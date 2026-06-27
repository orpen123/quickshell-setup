

import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Particles

Item {
    id: root
    required property var  pill
    required property bool showWorkspaces

    property int activeWorkspace: 1
    property int lastPoppedWorkspace: -1
    property int prevWorkspace: 1
    property var openWorkspaces: [1, 2, 3, 4, 5]
    property var workspaceApps: ({})

    readonly property int maxVisible: 7

    ListModel { id: wsModel }
    property var _modelIds: ({})

    function _getVisibleWindow(allIds, activeId) {
        var total = allIds.length
        if (total <= root.maxVisible) return allIds.slice()
        var activeIdx = allIds.indexOf(activeId)
        if (activeIdx === -1) activeIdx = 0
        var half  = Math.floor(root.maxVisible / 2)
        var start = activeIdx - half
        var end   = start + root.maxVisible
        if (start < 0)   { start = 0;            end = root.maxVisible }
        if (end > total) { end   = total;         start = total - root.maxVisible }
        return allIds.slice(start, end)
    }

    function syncModel(newIds) {
        var desired = {}
        for (var i = 0; i < newIds.length; i++) desired[newIds[i]] = true
        for (var j = wsModel.count - 1; j >= 0; j--) {
            var entry = wsModel.get(j)
            if (!desired[entry.wsId] && !entry.dying)
                wsModel.setProperty(j, "dying", true)
        }
        for (var k = 0; k < newIds.length; k++) {
            var id = newIds[k]
            if (!root._modelIds[id]) {
                var insertAt = wsModel.count
                for (var m = 0; m < wsModel.count; m++) {
                    if (wsModel.get(m).wsId > id) { insertAt = m; break }
                }
                wsModel.insert(insertAt, { wsId: id, dying: false })
                var ids = root._modelIds
                ids[id] = true
                root._modelIds = ids
            }
        }
    }

    function removeFromModel(wsId) {
        for (var i = 0; i < wsModel.count; i++) {
            if (wsModel.get(i).wsId === wsId) { wsModel.remove(i); break }
        }
        var ids = root._modelIds
        delete ids[wsId]
        root._modelIds = ids
    }

    function refresh() {
        syncModel(_getVisibleWindow(root.openWorkspaces, root.activeWorkspace))
    }

    onActiveWorkspaceChanged: {
        if (activeWorkspace !== lastPoppedWorkspace) {
            prevWorkspace       = lastPoppedWorkspace
            lastPoppedWorkspace = activeWorkspace
        }
        refresh()
        if (root.openWorkspaces.indexOf(activeWorkspace) === -1)
            listDebounce.restart()
    }

    onOpenWorkspacesChanged: refresh()

    
    function getIconForClass(cls) {
        var c = cls.toLowerCase()
        if (c.indexOf("firefox") !== -1) return "󰈹"
        if (c.indexOf("discord") !== -1 || c.indexOf("vesktop") !== -1) return "󰙯"
        if (c.indexOf("code") !== -1) return "󰨞"
        if (c.indexOf("kitty") !== -1 || c.indexOf("alacritty") !== -1) return "󰄛"
        if (c.indexOf("spotify") !== -1) return "󰓇"
        if (c.indexOf("slack") !== -1) return "󰒱"
        if (c.indexOf("obsidian") !== -1) return "󱓧"
        if (c.indexOf("steam") !== -1) return "󰓓"
        if (c.indexOf("dolphin") !== -1 || c.indexOf("thunar") !== -1) return "󰉋"
        return "󰣆" 
    }

    function buildClients(jsonText) {
        try {
            var data = JSON.parse(jsonText)
            var apps = {}
            for (var i = 0; i < data.length; i++) {
                var c = data[i]
                var w = c.workspace.id
                if (w < 1) continue
                if (!apps[w]) apps[w] = []
                var icon = getIconForClass(c.class)
                if (apps[w].indexOf(icon) === -1) {
                    apps[w].push(icon)
                }
            }
            root.workspaceApps = apps
        } catch(e) {}
    }

    function buildWorkspaceList(jsonText) {
        try {
            var arr = JSON.parse(jsonText.trim())
            var ids = []
            for (var i = 0; i < arr.length; i++) {
                var id = parseInt(arr[i].id)
                if (!isNaN(id) && id > 0) ids.push(id)
            }
            for (var j = 1; j <= 5; j++) {
                if (ids.indexOf(j) === -1) ids.push(j)
            }
            ids.sort(function(a, b) { return a - b })
            root.openWorkspaces = ids
            if (ids.indexOf(root.activeWorkspace) === -1)
                workspaceGet.running = true
        } catch(e) {
            root.openWorkspaces = [1, 2, 3, 4, 5]
        }
    }

    Timer {
        id: listDebounce
        interval: 20; repeat: false; running: false
        onTriggered: workspacesListGet.running = true
    }

    Process {
        id: workspaceGet
        command: ["bash", "-c",
            "hyprctl activeworkspace -j | grep -o '\"id\":[0-9]*' | head -1 | grep -o '[0-9]*'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                if (!isNaN(v)) root.activeWorkspace = v
            }
        }
    }

    
    Process {
        id: clientsGet
        command: ["bash", "-c", "hyprctl clients -j"]
        stdout: StdioCollector { onStreamFinished: root.buildClients(text) }
    }

    Process {
        id: workspacesListGet
        command: ["bash", "-c", "hyprctl workspaces -j"]
        stdout: StdioCollector { onStreamFinished: root.buildWorkspaceList(text) }
    }

    Process {
        id: workspaceListener
        command: ["bash", "-c",
            "socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | " +
            "grep --line-buffered -E '^(workspace|activeworkspace|destroyworkspace|createworkspace|openwindow|closewindow|movewindow)>>'"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var parts   = line.trim().split(">>")
                var event   = parts[0]
                var payload = parts.length > 1 ? parseInt(parts[1].split(",")[0]) : NaN
                if (event === "workspace" || event === "activeworkspace") {
                    if (!isNaN(payload)) root.activeWorkspace = payload
                } else if (event === "createworkspace" || event === "destroyworkspace" || event === "openwindow" || event === "closewindow" || event === "movewindow") {
                    clientsGet.running = true
                    listDebounce.restart()
                }
            }
        }
    }

    Timer {
        interval: 250; running: true; repeat: false; triggeredOnStart: true
        onTriggered: { workspaceGet.running = true; workspacesListGet.running = true; clientsGet.running = true }
    }

    Timer {
        interval: 2000; running: pill.centerMode === 1; repeat: true
        onTriggered: { workspacesListGet.running = true; workspaceGet.running = true }
    }

    
    

    Process {
        id: wsSwitchProcess
        property string target: "1"
        command: ["bash", "-c", "hyprctl dispatch workspace " + target]
    }

    
    
    
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        width:  pill.centerMode === 1
        ? (root.maxVisible * 20 + Math.max(0, root.maxVisible - 1) * 4 + 48)
        : 200
height: parent.height
clip:   false
Behavior on width {
    enabled: pill.centerMode === 1
    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
}

        
        Item {
            width: parent.width; height: parent.height
            opacity: pill.centerMode === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 130 } }
            transform: Translate {
                y: pill.centerMode === 0 ? 0 : -16
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: clockRect
                anchors.centerIn: parent
                width: 120; height: pill.expanded ? 52 : 28; radius: 12
                color: pill.clockHovered && pill.expanded ? pill.t_cardHover : "transparent"
                Behavior on color  { ColorAnimation  { duration: 180 } }
                Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                clip: true

                property bool isRain:  (pill.weatherCondition || "").indexOf("rain") !== -1 || (pill.weatherCondition || "").indexOf("drizzle") !== -1
                property bool isSnow:  (pill.weatherCondition || "").indexOf("snow") !== -1

                ParticleSystem {
                    id: snowSystem
                    anchors.fill: parent
                    opacity: (!pill.expanded && (clockRect.isSnow || (!clockRect.isRain && !pill.isLightMode))) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    ItemParticle {
                        system: snowSystem
                        delegate: Rectangle {
                            width: 3; height: 3; radius: 1.5
                            color: "#ffffff"
                            opacity: 0.6
                        }
                    }

                    Emitter {
                        system: snowSystem
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        emitRate: 8
                        lifeSpan: 4000
                        size: 3
                        sizeVariation: 1
                        velocity: PointDirection { y: 12; yVariation: 4; xVariation: 5 }
                    }
                }

                
                ParticleSystem {
                    id: lightSystem
                    anchors.fill: parent
                    opacity: (!pill.expanded && pill.isLightMode && !clockRect.isRain && !clockRect.isSnow) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    ItemParticle {
                        system: lightSystem
                        delegate: Rectangle {
                            width: 12; height: 12; radius: 6
                            color: "transparent"
                            border.color: pill.t_accent
                            border.width: 1.5
                            opacity: 0.5
                        }
                    }

                    Emitter {
                        system: lightSystem
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        emitRate: 3
                        lifeSpan: 5000
                        size: 8
                        sizeVariation: 6
                        velocity: PointDirection { y: -10; yVariation: 4; xVariation: 5 }
                    }
                }

                
                ParticleSystem {
                    id: rainSystem
                    anchors.fill: parent
                    opacity: (!pill.expanded && clockRect.isRain) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    ItemParticle {
                        system: rainSystem
                        delegate: Rectangle {
                            width: 1.5; height: 12; radius: 0.75
                            color: pill.isLightMode ? "#0ea5e9" : "#3dffc0"
                            opacity: 0.7
                        }
                    }

                    Emitter {
                        system: rainSystem
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        emitRate: 15
                        lifeSpan: 1500
                        size: 12
                        sizeVariation: 4
                        velocity: PointDirection { y: 40; yVariation: 10; xVariation: 2 }
                    }
                }

            }

            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            

            

            
            
            
            
            
            
            
            

            
            
            
            
            
            
            
            
            
            
            
            
            
            
            Item {
    anchors.fill: parent

    
    
    
    
    property int  _sleepTick: 0
    property bool isSleeping: {
        _sleepTick  
        return (new Date().getHours() >= 22 || new Date().getHours() < 7)
    }
    Timer {
        interval: 300000; running: true; repeat: true  
        onTriggered: parent._sleepTick++
    }

    AnimatedImage {
    source: parent.isSleeping
        ? Qt.resolvedUrl("icons/sleeping.gif")
        : Qt.resolvedUrl("icons/pikachu.gif")

    width:  parent.isSleeping ? 50 : 100
    height: parent.isSleeping ? 70 : 100

    playing: !pill.expanded
    visible: !pill.expanded
    fillMode: Image.PreserveAspectFit
    anchors.left: parent.left; anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: pill.expanded ? -12 : 0

    Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
}

    Text {
        id: clockText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: pill.expanded ? -12 : 0
        color: pill.t_text; font.bold: pill.expanded
        font.pointSize: pill.expanded ? 16 : 12
        font.family: "JetBrainsMono Nerd Font Mono"
        text: Qt.formatDateTime(new Date(), "hh:mm")
        Behavior on font.pointSize { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Timer {
            interval: 10000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "hh:mm")
        }
    }
}

            Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.verticalCenter; anchors.topMargin: 6
    color: pill.t_textSub; font.pointSize: 8
    font.family: "JetBrainsMono Nerd Font Mono"
    text: Qt.formatDateTime(new Date(), "ddd, MMM d")
    opacity: pill.expanded ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
}
        }

        
        Item {
            width: parent.width; height: parent.height
            opacity: pill.centerMode === 1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 130 } }
            transform: Translate {
                y: pill.centerMode === 1 ? 0 : 16
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Item {
                id: trackWrapper
                anchors.centerIn: parent

                property int liveCount: {
                    var n = 0
                    for (var i = 0; i < wsModel.count; i++)
                        if (!wsModel.get(i).dying) n++
                    return Math.max(1, n)
                }

                property real pillW: {
                    var active = root.openWorkspaces.indexOf(root.activeWorkspace) !== -1 ? 1 : 0
                    var inactive = liveCount - active
                    return active * 36 + inactive * 14 + Math.max(0, liveCount - 1) * 4 + 20
                }

                width:  Math.max(40, pillW)
                height: 28
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: pill.isLightMode ? "#e8f5ed" : "#0a1f16" 
                    border.width: 1
                    border.color: pill.isLightMode ? "#b2e0c9" : "#163828"
                }

                Rectangle {
                    anchors.left: parent.left; anchors.leftMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3; height: 3; radius: 1.5
                    color: pill.t_accent
                    opacity: {
                        var win = root._getVisibleWindow(root.openWorkspaces, root.activeWorkspace)
                        return (root.openWorkspaces.length > root.maxVisible &&
                                win.length > 0 &&
                                win[0] !== root.openWorkspaces[0]) ? 0.45 : 0
                    }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3; height: 3; radius: 1.5
                    color: pill.t_accent
                    opacity: {
                        var win = root._getVisibleWindow(root.openWorkspaces, root.activeWorkspace)
                        var last = root.openWorkspaces[root.openWorkspaces.length - 1]
                        return (root.openWorkspaces.length > root.maxVisible &&
                                win.length > 0 &&
                                win[win.length - 1] !== last) ? 0.45 : 0
                    }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Row {
                    id: dotsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: wsModel

                        delegate: Item {
                            id: wsDelegate
                            required property int  index
                            required property int  wsId
                            required property bool dying

                            property bool isActive:  wsId === root.activeWorkspace
                            property bool isHovered: false

                            property real enterProgress: 0
                            property real exitProgress:  1

                            property var apps: root.workspaceApps[wsId] || []
                            property real contentWidth: Math.max(0, apps.length * 16)
                            property real targetW: isActive ? (20 + contentWidth) : (isHovered ? (14 + contentWidth) : (apps.length > 0 ? (14 + contentWidth) : 14))
                            Behavior on targetW {
                                NumberAnimation {
                                    duration:         isActive ? 200 : 120
                                    easing.type:      isActive ? Easing.OutBack : Easing.OutCubic
                                    easing.overshoot: 0.6
                                }
                            }

                            width:   targetW  * enterProgress * exitProgress
                            height:  18
                            opacity: Math.pow(enterProgress * exitProgress, 0.5)
                            anchors.verticalCenter: parent.verticalCenter
                            clip: false

                            NumberAnimation on enterProgress {
                                id: enterAnim; running: false
                                from: 0; to: 1; duration: 250
                                easing.type: Easing.OutBack; easing.overshoot: 0.7
                            }

                            SequentialAnimation {
                                id: exitAnim; running: false
                                NumberAnimation {
                                    target: wsDelegate; property: "exitProgress"
                                    from: 1; to: 0; duration: 160
                                    easing.type: Easing.InCubic
                                }
                                ScriptAction { script: root.removeFromModel(wsDelegate.wsId) }
                            }

                            Component.onCompleted: { enterProgress = 0; enterAnim.start() }
                            onDyingChanged: { if (dying) { enterAnim.stop(); exitAnim.start() } }

                            Rectangle {
                                id: dotBody
                                width:  parent.width
                                height: parent.height
                                radius: height / 2

                                color: isActive
                                    ? pill.t_accent
                                    : (isHovered ? pill.t_cardHover : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }

                                border.width: 1.5
                                border.color: isActive
                                    ? pill.t_accent
                                    : (isHovered ? pill.t_border : pill.t_border)
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    anchors.top: parent.top; anchors.topMargin: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width:   isActive ? parent.width * 0.45 : 0
                                    height:  1; radius: 1
                                    color:   pill.t_text
                                    opacity: isActive ? 0.4 : 0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                    Behavior on width   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    property var apps: root.workspaceApps[wsDelegate.wsId] || []
                                    text: apps.length > 0 ? apps.join(" ") : wsDelegate.wsId.toString()
                                    color: isActive ? pill.t_bg : pill.t_textSub
                                    font.pointSize: apps.length > 0 ? 9 : 8
                                    font.bold: true
                                    font.family: "JetBrainsMono Nerd Font Mono"
                                    opacity: (isActive || apps.length > 0) ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 100 } }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered: wsDelegate.isHovered = true
                                onExited:  wsDelegate.isHovered = false
                                onClicked: {
                                    if (!isActive && !dying) {
                                        root.activeWorkspace    = wsDelegate.wsId
                                        wsSwitchProcess.target  = wsDelegate.wsId.toString()
                                        wsSwitchProcess.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        
Item {
    width: parent.width; height: parent.height
    opacity: pill.centerMode === 2 ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 130 } }
    transform: Translate {
        y: pill.centerMode === 2 ? 0 : 16
        Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    Item {
    id: statContainer
    anchors.centerIn: parent
    width: parent.width - 36; height: 28

        property int activeStatIndex: 1

        Row {
            anchors.fill: parent
            spacing: 3

            
            Item {
                id: cpuPill
                property bool isActive: statContainer.activeStatIndex === 0
                
                width: isActive ? (parent.width - 9) * 0.55 : (parent.width - 9) * 0.15
                height: parent.height
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: cpuPill.isActive ? "#232323" : "#181818"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Row {
                    anchors.centerIn: parent
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    spacing: 5

                    Text {
                        text: "󰻠"
                        color: cpuPill.isActive ? "#cccccc" : "#555555"
                        font.pointSize: 10
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Text {
                        text: pill.cpuUsage + "%"
                        color: pill.cpuUsage > 80 ? "#ff6b6b"
                             : pill.cpuUsage > 50 ? "#ffcc66"
                             : "#dddddd"
                        font.pointSize: 9; font.bold: true
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: cpuPill.isActive ? 1 : 0
                        visible: cpuPill.isActive
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!cpuPill.isActive) statContainer.activeStatIndex = 0
                }
            }

            
            Item {
                id: ramPill
                property bool isActive: statContainer.activeStatIndex === 1
                width: isActive ? (parent.width - 9) * 0.55 : (parent.width - 9) * 0.15
                height: parent.height
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: ramPill.isActive ? "#232323" : "#181818"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "󰍛"
                        color: ramPill.isActive ? "#cccccc" : "#555555"
                        font.pointSize: 10
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Text {
                        text: Math.round(pill.ramUsage / 1024) + "/" + Math.round(pill.ramTotal / 1024) + "G"
                        color: (pill.ramUsage / pill.ramTotal) > 0.8 ? "#ff6b6b"
                             : (pill.ramUsage / pill.ramTotal) > 0.5 ? "#ffcc66"
                             : "#dddddd"
                        font.pointSize: 9; font.bold: true
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: ramPill.isActive ? 1 : 0
                        visible: ramPill.isActive
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!ramPill.isActive) statContainer.activeStatIndex = 1
                }
            }

            
            Item {
                id: diskPill
                property bool isActive: statContainer.activeStatIndex === 2
                width: isActive ? (parent.width - 9) * 0.55 : (parent.width - 9) * 0.15
                height: parent.height
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: diskPill.isActive ? "#232323" : "#181818"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "󰋊"
                        color: diskPill.isActive ? "#cccccc" : "#555555"
                        font.pointSize: 10
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Text {
                        text: pill.diskUsage + "/" + pill.diskTotal + "G"
                        color: (pill.diskUsage / pill.diskTotal) > 0.8 ? "#ff6b6b"
                             : (pill.diskUsage / pill.diskTotal) > 0.5 ? "#ffcc66"
                             : "#dddddd"
                        font.pointSize: 9; font.bold: true
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: diskPill.isActive ? 1 : 0
                        visible: diskPill.isActive
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!diskPill.isActive) statContainer.activeStatIndex = 2
                }
            }

            
            Item {
                id: netPill
                property bool isActive: statContainer.activeStatIndex === 3
                width: isActive ? (parent.width - 9) * 0.55 : (parent.width - 9) * 0.15
                height: parent.height
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: netPill.isActive ? "#232323" : "#181818"
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰩟"
                        color: netPill.isActive ? "#cccccc" : "#555555"
                        font.pointSize: 10
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        opacity: netPill.isActive ? 1 : 0
                        visible: netPill.isActive
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            text: "↓ " + pill.netDownSpeed
                            color: pill.t_text
                            font.pointSize: 7; font.bold: true
                            font.family: "JetBrainsMono Nerd Font Mono"
                        }
                        Text {
                            text: "↑ " + pill.netUpSpeed
                            color: pill.t_textSub
                            font.pointSize: 7
                            font.family: "JetBrainsMono Nerd Font Mono"
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!netPill.isActive) statContainer.activeStatIndex = 3
                }
            }
        }
    }
}
    }

    
    Row {
        anchors.left: parent.left; anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        opacity: (pill.expanded && pill.centerMode !== 2) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 130 } }

        Item {
            width: 40; height: 40
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: barArtImage
                anchors.fill: parent
                source: pill.activePlayer ? (pill.activePlayer.trackArtUrl || "") : ""
                fillMode: Image.PreserveAspectCrop; asynchronous: true
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect { maskEnabled: true; maskSource: barArtMask }
            }

            Rectangle {
                anchors.fill: parent; radius: 20
                color: pill.t_card
                visible: !pill.activePlayer || barArtImage.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text: pill.activePlayer ? "󰎇" : "󰝛"
                    color: pill.activePlayer ? "#ffffff" : "#444444"
                    font.pointSize: 14
                    font.family: "JetBrainsMono Nerd Font Mono"
                }
            }

            Rectangle { id: barArtMask; anchors.fill: parent; radius: 20; visible: false; layer.enabled: true }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1; width: 130

            Text {
                text: pill.activePlayer ? (pill.activePlayer.trackTitle || "") : "No media"
                color: pill.activePlayer ? "#ffffff" : "#444444"
                font.pointSize: 9; font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
                elide: Text.ElideRight; width: parent.width
            }
            Text {
                text: pill.activePlayer ? (pill.activePlayer.trackArtist || "") : "Nothing playing"
                color: pill.activePlayer ? "#888888" : "#333333"
                font.pointSize: 8
                font.family: "JetBrainsMono Nerd Font Mono"
                elide: Text.ElideRight; width: parent.width
            }
        }
    }

    
    Row {
        anchors.right: parent.right; anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        
        opacity: (pill.expanded && pill.centerMode !== 2) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 130 } }

        Rectangle {
            width: 75; height: 28; radius: 14; color: pill.t_cardHover
            anchors.verticalCenter: parent.verticalCenter
            border.width: 1
            border.color: pill.iconHovered ? "#2a7a5e" : "#333333"
            Behavior on border.color { ColorAnimation { duration: 160 } }

            Row {
                anchors.centerIn: parent; spacing: 6
                Image {
                    source: Qt.resolvedUrl("icons/" + pill.wifiIconName + ".svg")
                    width: 18; height: 18; sourceSize.width: 18; sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 38; height: 22
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: batBody
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 18; radius: 4
                        color: "transparent"
                        border.width: 1.5
                        border.color: pill.t_border

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(2, (batBody.width - 4) * (pill.batteryPercent / 100))
                            height: batBody.height - 4; radius: 2
                            color: pill.batteryPercent <= 10 ? "#ff4444"
                                 : pill.batteryPercent <= 25 ? "#ffaa00"
                                 : "#3dffc0"
                            opacity: 0.85
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: pill.batteryIconName === "battery-charging" ? "󱐋" : pill.batteryPercent
                            color: pill.batteryIconName === "battery-charging" ? "#555555" : "#353232"
                            font.pointSize: pill.batteryIconName === "battery-charging" ? 12 : 10
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font Mono"
                        }
                    }

                    Rectangle {
                        anchors.left: batBody.right
                        anchors.leftMargin: 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: 7; radius: 1.5
                        color: pill.t_border
                    }
                }
            }
        }
    }
}
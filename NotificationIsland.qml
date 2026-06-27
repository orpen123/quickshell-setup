





















import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property var pill
    required property var notifWatcher

    
    
    
    
    Process {
        id: focusApp
        property string appName: ""
        command: ["bash", "-c",
            
            "n=$(printf '%s' \"$1\" | tr '[:upper:]' '[:lower:]'); " +
            "hyprctl dispatch focuswindow \"class:.*${n}.*\" 2>/dev/null || " +
            "hyprctl dispatch focuswindow \"title:.*${n}.*\" 2>/dev/null || true",
            "--", appName
        ]
    }

    
    
    Rectangle {
        anchors.fill: parent
        radius: 21
        color: pill.t_bg
    }

    
    Item {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        opacity: pill.notificationActive ? 1 : 0
        visible: opacity > 0
        scale:   pill.notificationActive ? 1 : 0.82
        transformOrigin: Item.Left

        Behavior on opacity {
            NumberAnimation { duration: pill.notificationActive ? 180 : 130 }
        }
        Behavior on scale {
            NumberAnimation {
                duration:         pill.notificationActive ? 280 : 140
                easing.type:      pill.notificationActive ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 0.6
            }
        }

        
        transform: Translate {
            id: swipeTranslate
            x: 0
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        
        Item {
            id: iconBadge
            width: 44; height: 44
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: pill.isLightMode ? "#e8f5ed" : "#0d1f17"
                border.width: 1
                border.color: pill.isLightMode ? "#b2e0c9" : "#1c3d2c"
            }

            IconImage {
                id: appIconImage
                anchors.fill: parent
                anchors.margins: 6
                asynchronous: true
                visible: status === Image.Ready

                
                
                
                
                
                source: {
                    var icon = pill.notificationIcon
                    if (icon.length === 0) return ""
                    if (icon.startsWith("/") || icon.startsWith("file://") ||
                        icon.startsWith("http://") || icon.startsWith("https://"))
                        return icon
                    return Quickshell.iconPath(icon, true) 
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !appIconImage.visible
                text: pill.notificationAppName.length > 0
                      ? pill.notificationAppName.charAt(0).toUpperCase()
                      : "?"
                color: pill.t_accent
                font.bold: true
                font.pointSize: 14
                font.family: "JetBrainsMono Nerd Font Mono"
            }
        }

        
        Column {
            anchors.left: iconBadge.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: pill.notificationAppName
                color: pill.t_accent
                font.pointSize: 8
                font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Text {
                width: parent.width
                text: pill.notificationSummary
                color: pill.t_text
                font.pointSize: 10
                font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Text {
                width: parent.width
                visible: pill.notificationBody.length > 0
                text: pill.notificationBody
                color: pill.t_textSub
                font.pointSize: 9
                font.family: "JetBrainsMono Nerd Font Mono"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
                lineHeight: 1.15
            }
        }
    }

    
    
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        property real _startX: 0
        property real _dragX:  0

        onPressed:  { _startX = mouseX; _dragX = 0 }
        onPositionChanged: {
            if (!pressed) return
            _dragX = mouseX - _startX
            swipeTranslate.x = _dragX * 0.55
        }
        onReleased: {
            if (Math.abs(_dragX) > 80) {
                root.notifWatcher.dismissCurrent()
            } else {
                swipeTranslate.x = 0
            }
            _dragX = 0
        }
        onClicked: {
            if (Math.abs(_dragX) < 5) {
                
                if (pill.notificationAppName.length > 0) {
                    focusApp.appName = pill.notificationAppName
                    focusApp.running = true
                }
                root.notifWatcher.dismissCurrent()
            }
        }
    }
}

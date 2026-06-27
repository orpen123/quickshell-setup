

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick

Rectangle {
    id: pill
    focus: true
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 6
    radius: 25
    color: t_bg
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.InOutQuad } }
    clip: true

    
    property bool controlCenterOpen: false
    property bool wallpaperOpen:     false
    property bool weatherOpen:       false
    property string weatherCondition: ""
    property bool isLightMode:       false

    
    property color t_bg:        isLightMode ? "#e2e6eb" : "#050e0f"
    property color t_card:      isLightMode ? "#ffffff" : "#1a2420"
    property color t_cardHover: isLightMode ? "#f3f4f6" : "#141815"
    property color t_text:      isLightMode ? "#111827" : "#ffffff"
    property color t_textSub:   isLightMode ? "#4b5563" : "#aaaaaa"
    property color t_accent:    isLightMode ? "#0ea5e9" : "#3dffc0" 
    property color t_border:    isLightMode ? "#d1d5db" : "#1c3d2c"
    
    
    property int centerMode: 0
    property bool showWorkspaces: centerMode === 1


    property real   cpuUsage:   0
property real   ramUsage:   0
property real   ramTotal:   0
property real   diskUsage:  0
property real   diskTotal:  0

Process {
    id: sysStatsGet
    command: ["bash", "-c",
        "echo cpu:$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d. -f1); " +
        "echo ram:$(free -m | awk '/Mem:/{print $3\",\"$2}'); " +
        "echo disk:$(df -BG / | awk 'NR==2{gsub(\"G\",\"\",$3); gsub(\"G\",\"\",$2); print $3\",\"$2}')"
    ]
    stdout: StdioCollector {
        onStreamFinished: {
            var lines = text.trim().split("\n")
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split(":")
                if (parts[0] === "cpu") {
                    pill.cpuUsage = parseFloat(parts[1]) || 0
                } else if (parts[0] === "ram") {
                    var ram = parts[1].split(",")
                    pill.ramUsage = parseFloat(ram[0]) || 0
                    pill.ramTotal = parseFloat(ram[1]) || 0
                } else if (parts[0] === "disk") {
                    var disk = parts[1].split(",")
                    pill.diskUsage = parseFloat(disk[0]) || 0
                    pill.diskTotal = parseFloat(disk[1]) || 0
                }
            }
        }
    }
}

Timer {
    interval: 2000; running: pill.centerMode === 2; repeat: true; triggeredOnStart: true
    onTriggered: sysStatsGet.running = true
}



    readonly property bool expanded: (hoverArea.containsMouse && !showWorkspaces) || controlCenterOpen
    readonly property bool batteryCharging: battery ? battery.state === UPowerDeviceState.Charging : false
    property bool calendarOpen: false

property bool   notificationActive:   false
    property string notificationAppName:  ""
    property string notificationSummary:  ""
    property string notificationBody:     ""
    property string notificationIcon:     ""
    property int    notificationCount:    0   
    readonly property int notificationWidth:  460
    readonly property int notificationHeight: 86

    
    property bool dnd: false

    
    onControlCenterOpenChanged: if (controlCenterOpen) notificationCount = 0
    onCalendarOpenChanged:      if (calendarOpen)      notificationCount = 0

    
    Keys.onEscapePressed: {
        controlCenterOpen = false
        calendarOpen = false
        wallpaperOpen = false
        weatherOpen = false
    }

    readonly property int collapsedWidth:      200
    readonly property int collapsedHeight:     36
    readonly property int expandedWidth:       600
    readonly property int expandedHeight:      70
    readonly property int workspaceWidth:      200  
    readonly property int workspaceHeight:     36   
    readonly property int controlCenterWidth:  600
    readonly property int controlCenterHeight: 580

    readonly property int wallpaperWidth:      600
    readonly property int wallpaperHeight:     180

    readonly property int weatherWidth:      400
    readonly property int weatherHeight:     240

    readonly property int calendarWidth:  600
    readonly property int calendarHeight: 460


    
    

    readonly property bool iconHovered:
        hoverArea.containsMouse &&
        !controlCenterOpen &&
        hoverArea.mouseX >= (pill.width - 90) &&
        hoverArea.mouseX <= (pill.width - 10) &&
        hoverArea.mouseY >= (pill.height / 2 - 16) &&
        hoverArea.mouseY <= (pill.height / 2 + 16)

    readonly property bool clockHovered:
        hoverArea.containsMouse &&
        !controlCenterOpen &&
        hoverArea.mouseX >= (pill.width / 2 - 60) &&
        hoverArea.mouseX <= (pill.width / 2 + 60) &&
        hoverArea.mouseY >= 0 &&
        hoverArea.mouseY <= pill.height


width:  notificationActive ? notificationWidth
      : controlCenterOpen ? controlCenterWidth
      : wallpaperOpen     ? wallpaperWidth
      : weatherOpen       ? weatherWidth
      : calendarOpen      ? calendarWidth
      : centerMode === 1  ? workspaceWidth
      : centerMode === 2  ? workspaceWidth
      : expanded          ? expandedWidth
      :                     collapsedWidth

height: notificationActive ? notificationHeight
      : controlCenterOpen ? controlCenterHeight
      : wallpaperOpen     ? wallpaperHeight
      : weatherOpen       ? weatherHeight
      : calendarOpen      ? calendarHeight
      : centerMode === 1  ? workspaceHeight
      : centerMode === 2  ? workspaceHeight
      : expanded          ? expandedHeight
      :                     collapsedHeight

    Behavior on width  { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    
    
    
    
    
    
    
    
    
    
    MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    visible: !pill.controlCenterOpen && !pill.calendarOpen && !pill.notificationActive && !pill.wallpaperOpen
    onClicked: (mouse) => {
        if (pill.iconHovered && !pill.controlCenterOpen)
            pill.controlCenterOpen = true
        else if (pill.clockHovered && !pill.calendarOpen)
            pill.calendarOpen = true
    }
}

    
    readonly property var activePlayer: {
        const players = Mpris.players.values
        if (players.length === 0) return null
        for (let i = 0; i < players.length; i++)
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        for (let i = 0; i < players.length; i++)
            if (players[i].playbackState === MprisPlaybackState.Paused) return players[i]
        return players[0]
    }

    readonly property var battery: UPower.displayDevice

    
    property string wifiIconName: "wifi-x"
    property string wifiSsid:     "Not connected"
    property int    wifiSignal:   0
    property bool   wifiEnabled:  false

    Process {
        id: wifiCheck
        command: ["bash", "-c",
            "nmcli -t -f WIFI g 2>/dev/null | grep -q enabled && echo 'enabled' || echo 'disabled'; " +
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | grep '^yes' | head -1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                pill.wifiEnabled = (lines[0].trim() === "enabled")

                if (lines.length < 2 || lines[1].trim() === "") {
                    pill.wifiSsid     = pill.wifiEnabled ? "Not connected" : "WiFi off"
                    pill.wifiSignal   = 0
                    pill.wifiIconName = pill.wifiEnabled ? "wifi-none" : "wifi-x"
                    return
                }

                var parts = lines[1].trim().split(":")
                if (parts.length < 3) {
                    pill.wifiSsid     = pill.wifiEnabled ? "Not connected" : "WiFi off"
                    pill.wifiSignal   = 0
                    pill.wifiIconName = pill.wifiEnabled ? "wifi-none" : "wifi-x"
                    return
                }

                var signal = parseInt(parts[1]) || 0
                var ssid   = parts.slice(2).join(":").trim()
                pill.wifiSignal = signal
                pill.wifiSsid   = ssid || "Unknown"

                if      (signal > 70) pill.wifiIconName = "wifi-high"
                else if (signal > 40) pill.wifiIconName = "wifi-medium"
                else if (signal > 10) pill.wifiIconName = "wifi-low"
                else                  pill.wifiIconName = "wifi-none"
            }
        }
    }

    Process {
        id: wifiToggle
        property bool turningOn: false
        command: ["bash", "-c", turningOn ? "nmcli radio wifi on" : "nmcli radio wifi off"]
        onRunningChanged: if (!running) wifiCheck.running = true
    }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: wifiCheck.running = true
    }

    
    property bool   btPowered: false
    property string btDevice:  ""
    property string btAddress: ""

    Process {
        id: btCheck
        command: ["bash", "-c",
            "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'; " +
            "bluetoothctl devices Connected 2>/dev/null | head -1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                pill.btPowered = (lines[0].trim() === "on")

                if (lines.length >= 2 && lines[1].trim() !== "") {
                    var parts = lines[1].trim().split(" ")
                    if (parts.length >= 3) {
                        pill.btAddress = parts[1]
                        pill.btDevice  = parts.slice(2).join(" ")
                    } else {
                        pill.btDevice  = ""
                        pill.btAddress = ""
                    }
                } else {
                    pill.btDevice  = ""
                    pill.btAddress = ""
                }
            }
        }
    }

    Process {
        id: btToggle
        property bool turningOn: false
        command: ["bash", "-c", turningOn ? "bluetoothctl power on" : "bluetoothctl power off"]
        onRunningChanged: if (!running) btCheck.running = true
    }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: btCheck.running = true
    }

    
    property string batteryIconName: "battery-empty"
    property int    batteryPercent:  0

    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!pill.battery) return
            var pct = Math.round(pill.battery.percentage * 100)
            pill.batteryPercent = pct
            if      (pill.battery.state === UPowerDeviceState.Charging) pill.batteryIconName = "battery-charging"
            else if (pct > 80) pill.batteryIconName = "battery-full"
            else if (pct > 50) pill.batteryIconName = "battery-high"
            else if (pct > 25) pill.batteryIconName = "battery-medium"
            else if (pct > 10) pill.batteryIconName = "battery-low"
            else               pill.batteryIconName = "battery-warning"
        }
    }

    
    property real   volumeLevel:  0.6
    property string volumeTarget: "60"
    property bool   volumeManual: false

    Process {
        id: volumeGet
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (pill.volumeManual) return
                var v = parseInt(text.trim())
                if (!isNaN(v)) pill.volumeLevel = Math.min(v / 100.0, 1.0)
            }
        }
    }

    Process {
        id: volumeSetProcess
        command: ["bash", "-c", "pactl set-sink-volume @DEFAULT_SINK@ " + pill.volumeTarget + "%"]
        onRunningChanged: {
            if (!running) {
                pill.volumeManual = false
                volumeGet.running = true
            }
        }
    }

    Process {
        id: volumeSubscribe
        command: ["bash", "-c", "pactl subscribe | grep --line-buffered \"Event 'change' on sink\""]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (!pill.volumeManual) volumeGet.running = true
            }
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!pill.volumeManual) volumeGet.running = true
        }
    }

    
    property real   brightnessLevel:  0.45
    property string brightnessTarget: "45"
    property int    brightnessMax:    0
    property bool   brightnessManual: false

    Process {
        id: brightnessMaxGet
        command: ["bash", "-c", "cat /sys/class/backlight/intel_backlight/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                if (!isNaN(v) && v > 0) pill.brightnessMax = v
            }
        }
    }

    Process {
        id: brightnessGet
        command: ["bash", "-c", "cat /sys/class/backlight/intel_backlight/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (pill.brightnessManual) return
                var cur = parseInt(text.trim())
                if (!isNaN(cur) && pill.brightnessMax > 0)
                    pill.brightnessLevel = cur / pill.brightnessMax
            }
        }
    }

    Process {
        id: brightnessSetProcess
        command: ["bash", "-c", "brightnessctl set " + pill.brightnessTarget + "% --min-value=500"]
        onRunningChanged: {
            if (!running) {
                pill.brightnessManual = false
                brightnessGet.running = true
            }
        }
    }

    Timer {
        id: brightnessPoll
        interval: 3000   
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pill.brightnessManual && !brightnessGet.running)
                brightnessGet.running = true
        }
    }

    
    property real   _netPrevRx:  -1
    property real   _netPrevTx:  -1
    property string netDownSpeed: "―"
    property string netUpSpeed:   "―"

    function _formatNetSpeed(bps) {
        if (bps < 1024)       return Math.round(bps) + " B/s"
        if (bps < 1048576)    return Math.round(bps / 1024) + " K/s"
        return (bps / 1048576).toFixed(1) + " M/s"
    }

    Process {
        id: netStatsGet
        
        
        command: ["bash", "-c",
            "awk 'NR>2 && !/lo/{gsub(/:/,\"\"); rx+=$2; tx+=$10} END{print int(rx), int(tx)}' /proc/net/dev"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/)
                if (parts.length < 2) return
                var rx = parseFloat(parts[0]) || 0
                var tx = parseFloat(parts[1]) || 0
                if (pill._netPrevRx >= 0) {
                    
                    var drx = Math.max(0, rx - pill._netPrevRx)
                    var dtx = Math.max(0, tx - pill._netPrevTx)
                    pill.netDownSpeed = pill._formatNetSpeed(Math.round(drx / 2))
                    pill.netUpSpeed   = pill._formatNetSpeed(Math.round(dtx / 2))
                }
                pill._netPrevRx = rx
                pill._netPrevTx = tx
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: netStatsGet.running = true
    }

    
    property bool _lowBatWarned: false
    property bool _wasCharging: batteryCharging

    onBatteryChargingChanged: {
        if (batteryCharging) {
            notificationWatcher.injectSynthetic(
                "Battery",
                "Charger Connected",
                "Battery is now charging.",
                "battery-charging"
            )
        }
        _wasCharging = batteryCharging
    }

    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!pill.battery) return
            var pct = Math.round(pill.battery.percentage * 100)
            if (pct <= 20 && !pill.batteryCharging && !pill._lowBatWarned) {
                pill._lowBatWarned = true
                notificationWatcher.injectSynthetic(
                    "Battery",
                    "Low Battery — " + pct + "%",
                    "Connect your charger soon",
                    "battery-low"
                )
            } else if (pct > 25 || pill.batteryCharging) {
                pill._lowBatWarned = false
            }
        }
    }

    
    BarContent {
        anchors.fill: parent
        visible: !pill.controlCenterOpen && !pill.calendarOpen && !pill.wallpaperOpen && !pill.weatherOpen
        opacity: (pill.controlCenterOpen || pill.calendarOpen || pill.wallpaperOpen || pill.weatherOpen) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }

        pill:           pill
        showWorkspaces: pill.showWorkspaces
    }

    WallpaperCard {
        anchors.fill: parent
        visible: pill.wallpaperOpen
        opacity: pill.wallpaperOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        pill: pill
    }

    ControlCenter {
        anchors.fill: parent
        anchors.margins: 4
        visible: pill.controlCenterOpen
        clip: true
        opacity: pill.controlCenterOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        pill: pill
        onCloseRequested: pill.controlCenterOpen = false
        onVolumeChanged: (v) => {
            pill.volumeManual = true
            pill.volumeLevel  = v
            pill.volumeTarget = Math.round(v * 100).toString()
            volumeSetProcess.running = true
        }
        onBrightnessChanged: (b) => {
            pill.brightnessManual = true
            pill.brightnessLevel  = b
            pill.brightnessTarget = Math.round(b * 100).toString()
            brightnessSetProcess.running = true
        }
        onWifiToggleRequested: (turningOn) => {
            wifiToggle.turningOn = turningOn
            wifiToggle.running = true
        }
        onBtToggleRequested: (turningOn) => {
            btToggle.turningOn = turningOn
            btToggle.running = true
        }
    }
    CalendarView {
    anchors.fill: parent
    anchors.margins: 4
    visible: pill.calendarOpen
    clip: true
    opacity: pill.calendarOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 160 } }

    pill: pill
    onCloseRequested: pill.calendarOpen = false
}
NotificationWatcher {
    id: notificationWatcher
    pill: pill
}

NotificationIsland {
    anchors.fill: parent
    anchors.margins: 4
    opacity: pill.notificationActive ? 1 : 0
    visible: opacity > 0
    clip: true
    Behavior on opacity { NumberAnimation { duration: 160 } }

    pill: pill
    notifWatcher: notificationWatcher
}

    WeatherCard {
        anchors.fill: parent
        pill: pill
        opacity: pill.weatherOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
}

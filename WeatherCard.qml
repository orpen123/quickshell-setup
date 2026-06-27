import QtQuick
import Quickshell.Io

Rectangle {
    id: root
    color: pill ? pill.t_bg : "#050e0f"
    radius: 25
    focus: false

    required property var pill

    property string weatherTemp: "--"
    property string weatherCond: "..."
    property string weatherLoc:  ""
    property string weatherHum:  "--"
    property string weatherWind: "--"
    property string weatherIcon: "󰖐"

    function parseOutput(text) {
        var t = text.trim()
        if (t.indexOf("|") !== -1) {
            var parts = t.split("|")
            root.weatherTemp = parts[0] ? parts[0].trim() : "--"
            root.weatherCond = parts[1] ? parts[1].trim() : "Unknown"
            
            var locFull = parts[2] ? parts[2].trim() : ""
            root.weatherLoc = locFull.split(",")[0]
            
            root.weatherHum = parts[3] ? parts[3].trim() : "--"
            root.weatherWind = parts[4] ? parts[4].trim() : "--"
            
            var cond = root.weatherCond.toLowerCase()
            if (cond.indexOf("rain") !== -1 || cond.indexOf("drizzle") !== -1) root.weatherIcon = "󰖗"
            else if (cond.indexOf("snow") !== -1) root.weatherIcon = "󰖘"
            else if (cond.indexOf("cloud") !== -1 || cond.indexOf("overcast") !== -1) root.weatherIcon = "󰖐"
            else if (cond.indexOf("clear") !== -1 || cond.indexOf("sun") !== -1) root.weatherIcon = "󰖙"
            else root.weatherIcon = "󰖐"
            
            if (pill) pill.weatherCondition = cond
        } else {
            root.weatherCond = "Data error"
        }
    }

    Process {
        id: weatherGet
        command: ["bash", "-c", "curl -s --max-time 5 'wttr.in/?format=%t|%C|%l|%h|%w'"]
        stdout: StdioCollector {
            onStreamFinished: parseOutput(text)
        }
    }

    Timer {
        interval: 1800000 
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: weatherGet.running = true
    }

    Component.onCompleted: {
        weatherGet.running = true
    }
    


    Item {
        anchors.fill: parent
        anchors.margins: 16

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.weatherLoc ? root.weatherLoc : "Earth"
                color: pill ? pill.t_textSub : "#aaaaaa"
                font.pointSize: 12; font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.weatherIcon
                color: pill ? pill.t_accent : "#3dffc0"
                font.pointSize: 54
                font.family: "JetBrainsMono Nerd Font Mono"
                style: Text.Outline
                styleColor: Qt.rgba(0,0,0,0.1)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.weatherTemp
                color: pill ? pill.t_text : "#ffffff"
                font.pointSize: 42; font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.weatherCond
                color: pill ? pill.t_textSub : "#aaaaaa"
                font.pointSize: 16
                font.family: "JetBrainsMono Nerd Font Mono"
            }

            Item { width: 1; height: 8 } 

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24
                
                Row {
                    spacing: 6
                    Text {
                        text: "󰖐"
                        color: pill ? pill.t_accent : "#3dffc0"
                        font.pointSize: 12
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.weatherHum
                        color: pill ? pill.t_textSub : "#aaaaaa"
                        font.pointSize: 12
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                Row {
                    spacing: 6
                    Text {
                        text: "󰖝"
                        color: pill ? pill.t_accent : "#3dffc0"
                        font.pointSize: 12
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.weatherWind
                        color: pill ? pill.t_textSub : "#aaaaaa"
                        font.pointSize: 12
                        font.family: "JetBrainsMono Nerd Font Mono"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}

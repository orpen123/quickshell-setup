import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string currentWallpaper: ""
    property var pill

    
    Process {
        id: wpCurrentGet
        command: ["bash", "-c", "grep '^wallpaper =' ~/.config/waypaper/config.ini | cut -d' ' -f3"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.currentWallpaper = text.trim()
        }
    }

    
    Process {
        id: wpSetter
        property string target: ""
        command: ["waypaper", "--wallpaper", target]
    }

    
    ListModel { id: wpModel }

    
    Process {
        id: wpLister
        command: ["bash", "-c", "find ~/wallpapers -type f | grep -iE '\\.(jpg|jpeg|png|gif)$' | sort"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split('\n')
                wpModel.clear()
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line !== "") {
                        wpModel.append({ filePath: line })
                    }
                }
            }
        }
    }

    
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36

        Text {
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Wallpaper"
            color: pill ? pill.t_text : "#ffffff"
            font.pointSize: 11; font.bold: true
            font.family: "JetBrainsMono Nerd Font Mono"
        }
    }

    
    ListView {
        id: listView
        anchors.top: header.bottom
        anchors.bottom: parent.bottom; anchors.bottomMargin: 12
        anchors.left: parent.left; anchors.leftMargin: 12
        anchors.right: parent.right; anchors.rightMargin: 12
        
        orientation: ListView.Horizontal
        spacing: 10
        clip: true

        
        maximumFlickVelocity: 10000
        flickDeceleration: 1500

        model: wpModel
        delegate: Item {
            id: delegateRoot
            width: 160
            height: listView.height

            property bool isActive: root.currentWallpaper === filePath

            Item {
                id: imageWrapper
                anchors.fill: parent

                Image {
                    id: wpImg
                    anchors.fill: parent
                    source: "file://" + filePath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: imgMask
                    }
                }

                Rectangle {
                    id: imgMask
                    anchors.fill: parent
                    radius: 12
                    visible: false
                    layer.enabled: true
                }

                
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "transparent"
                    border.color: pill ? pill.t_accent : "#5fffcf"
                    border.width: 3
                    opacity: delegateRoot.isActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentWallpaper = filePath
                        wpSetter.target = filePath
                        wpSetter.running = true
                    }
                }
            }
        }
    }
}

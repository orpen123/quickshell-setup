

import QtQuick

Item {
    id: root
    required property var pill
    signal closeRequested()

    property int displayYear:  new Date().getFullYear()
    property int displayMonth: new Date().getMonth()

    onVisibleChanged: {
    if (visible) {
        root.displayYear  = new Date().getFullYear()
        root.displayMonth = new Date().getMonth()
    }
}

    readonly property var monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]
    readonly property var dayNames: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    function firstDayOfMonth(y, m) {
        var d = new Date(y, m, 1).getDay()
        return d === 0 ? 6 : d - 1
    }

    
    Item {
        id: calHeader
        anchors.top: parent.top
        anchors.left: parent.left; anchors.right: parent.right
        anchors.topMargin: 16; anchors.leftMargin: 16; anchors.rightMargin: 16
        height: 28

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 28; height: 28; radius: 14
                color: root.pill.t_card
                Text { anchors.centerIn: parent; text: "←"; color: root.pill.t_text; font.pointSize: 12; font.family: "JetBrainsMono Nerd Font Mono" }
                MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Calendar"
                color: root.pill.t_text; font.pointSize: 13; font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
            }
        }

        
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 28; height: 28; radius: 14; color: root.pill.t_card
                Text { anchors.centerIn: parent; text: "‹"; color: root.pill.t_accent; font.pointSize: 14; font.family: "JetBrainsMono Nerd Font Mono" }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.displayMonth === 0) { root.displayMonth = 11; root.displayYear-- }
                        else root.displayMonth--
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.monthNames[root.displayMonth] + " " + root.displayYear
                color: root.pill.t_text; font.pointSize: 10; font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
                width: 140; horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: 28; height: 28; radius: 14; color: root.pill.t_card
                Text { anchors.centerIn: parent; text: "›"; color: root.pill.t_accent; font.pointSize: 14; font.family: "JetBrainsMono Nerd Font Mono" }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.displayMonth === 11) { root.displayMonth = 0; root.displayYear++ }
                        else root.displayMonth++
                    }
                }
            }
        }
    }

    
    Row {
        id: dayHeaders
        anchors.top: calHeader.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.topMargin: 16; anchors.leftMargin: 16; anchors.rightMargin: 16
        spacing: 0

        Repeater {
            model: root.dayNames
            delegate: Text {
                width: (root.width - 32) / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: (index === 5 || index === 6) ? root.pill.t_accent : root.pill.t_textSub
                font.pointSize: 8; font.bold: true
                font.family: "JetBrainsMono Nerd Font Mono"
            }
        }
    }

    
    Rectangle {
        anchors.top: dayHeaders.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.topMargin: 8; anchors.leftMargin: 16; anchors.rightMargin: 16
        height: 1; color: root.pill.t_card
    }

    
    Item {
        id: dayGrid
        anchors.top: dayHeaders.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 16; anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.bottomMargin: 16

        property int cellW: (width)  / 7
        property int cellH: (height) / 6

        readonly property int today:        new Date().getDate()
        readonly property int todayMonth:   new Date().getMonth()
        readonly property int todayYear:    new Date().getFullYear()
        readonly property int firstDay:     root.firstDayOfMonth(root.displayMonth === -1 ? 11 : root.displayMonth, root.displayMonth === -1 ? root.displayYear - 1 : root.displayYear)
        readonly property int totalDays:    root.daysInMonth(root.displayYear, root.displayMonth)
        readonly property bool isThisMonth: root.displayMonth === todayMonth && root.displayYear === todayYear

        Repeater {
            model: 42
            delegate: Item {
                id: cell
                property int dayNum: index - dayGrid.firstDay + 1
                property bool isValid: dayNum >= 1 && dayNum <= dayGrid.totalDays
                property bool isToday: isValid && dayGrid.isThisMonth && dayNum === dayGrid.today
                property bool isWeekend: (index % 7 === 5 || index % 7 === 6)

                x: (index % 7) * dayGrid.cellW
                y: Math.floor(index / 7) * dayGrid.cellH
                width: dayGrid.cellW
                height: dayGrid.cellH
                visible: isValid

                Rectangle {
                    anchors.centerIn: parent
                    width: 28; height: 28; radius: 14
                    color: cell.isToday ? root.pill.t_accent : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.isValid ? cell.dayNum : ""
                    color: cell.isToday  ? root.pill.t_bg
                         : cell.isWeekend ? root.pill.t_accent
                         : root.pill.t_text
                    font.pointSize: 9
                    font.bold: cell.isToday
                    font.family: "JetBrainsMono Nerd Font Mono"
                    opacity: cell.isValid ? 1 : 0
                }
            }
        }
    }
}
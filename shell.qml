

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    PanelWindow {
        id: panel
        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 600
        exclusiveZone: 36
        color: "transparent"

        WlrLayershell.keyboardFocus: (bar.controlCenterOpen || bar.calendarOpen || bar.wallpaperOpen || bar.weatherOpen)
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.OnDemand

        Rectangle {
            id: fullMask
            anchors.fill: parent
            color: "transparent"
            visible: bar.controlCenterOpen || bar.calendarOpen || bar.wallpaperOpen || bar.weatherOpen
        }

        mask: Region {
            item: (bar.controlCenterOpen || bar.calendarOpen || bar.wallpaperOpen || bar.weatherOpen) ? fullMask : bar
        }

        
        
        
        
        
        MouseArea {
            id: backdrop
            anchors.fill: parent
            visible: bar.controlCenterOpen || bar.calendarOpen || bar.wallpaperOpen || bar.weatherOpen
            onClicked: {
                bar.controlCenterOpen = false
                bar.calendarOpen = false
                bar.wallpaperOpen = false
                bar.weatherOpen = false
            }
        }

        Bar {
            id: bar
        }
    }

    IpcHandler {
        target: "bar"
        function toggleWorkspaces(): void {
            bar.centerMode = (bar.centerMode + 1) % 3
        }
        function toggleWallpaper(): void {
            if (bar.controlCenterOpen || bar.calendarOpen || bar.weatherOpen) {
                bar.controlCenterOpen = false
                bar.calendarOpen = false
                bar.weatherOpen = false
            }
            bar.wallpaperOpen = !bar.wallpaperOpen
        }

        function toggleWeather(): void {
            if (bar.controlCenterOpen || bar.calendarOpen || bar.wallpaperOpen || bar.weatherOpen) {
                bar.controlCenterOpen = false
                bar.calendarOpen = false
                bar.wallpaperOpen = false
            }
            bar.weatherOpen = !bar.weatherOpen
        }
    }
}

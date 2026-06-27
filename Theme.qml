pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string accent:     "#3dffc0"
    property string background: "#050e0f"
    property string surface:    "#0d1a16"
    property string surface2:   "#1a2420"
    property string text:       "#ffffff"
    property string subtext:    "#aaaaaa"

    function reload() {
        themeRead.running = true
    }

    Process {
        id: themeRead
        command: ["bash", "-c",
            "cat ~/.config/quickshell/themes/$(cat ~/.config/quickshell/themes/.active 2>/dev/null || echo ariadne).json 2>/dev/null"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(text)
                    root.accent     = d.accent     || "#3dffc0"
                    root.background = d.background || "#050e0f"
                    root.surface    = d.surface    || "#0d1a16"
                    root.surface2   = d.surface2   || "#1a2420"
                    root.text       = d.text       || "#ffffff"
                    root.subtext    = d.subtext    || "#aaaaaa"
                } catch(e) {}
            }
        }
    }

    
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: themeRead.running = true
    }
}



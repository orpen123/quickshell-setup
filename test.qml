import Quickshell
import Quickshell.Services.Mpris
import QtQuick

ShellRoot {
    Component.onCompleted: {
        for (var i = 0; i < Mpris.players.length; i++) {
            var p = Mpris.players[i]
            console.log("Player props:");
            for (var k in p) console.log("  " + k + " : " + typeof p[k]);
        }
        Qt.quit()
    }
}

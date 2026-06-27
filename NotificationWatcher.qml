















import Quickshell.Services.Notifications
import QtQuick

Item {
    id: watcher

    
    
    required property var pill

    
    
    property int displayDuration: 3800

    
    
    property int queueGap: 360

    
    property var _queue: []
    property var _current: null
    property bool _busy: false

    function _enqueue(n) {
        
        if (pill.dnd) {
            n.expire()
            return
        }
        _queue.push(n)
        pill.notificationCount++   
        if (!_busy) _showNext()
    }

    function _removeFromQueue(n) {
        var idx = _queue.indexOf(n)
        if (idx !== -1) _queue.splice(idx, 1)
        if (_current === n) dismissCurrent()
    }

    
    
    
    
    
    function injectSynthetic(appName, summary, body, icon) {
        var synth = {
            appName:  appName,
            summary:  summary,
            body:     body,
            appIcon:  icon,
            tracked:  false,
            expire:   function() {}
        }
        _queue.push(synth)
        if (!_busy) _showNext()
    }

    
    
    
    
    
    function _cleanBody(raw) {
        if (!raw) return ""
        var lines = raw.split("\n")
            .map(function (l) { return l.trim() })
            .filter(function (l) { return l.length > 0 })

        if (lines.length > 1 && /^[\w-]+(\.[\w-]+)+$/.test(lines[0]))
            lines.shift()

        return lines.join(" ")
    }

    function _showNext() {
        if (_queue.length === 0) {
            _busy = false
            return
        }
        _busy = true
        var n = _queue.shift()
        _current = n

        pill.notificationAppName = n.appName || "Notification"
        pill.notificationSummary = n.summary || ""
        pill.notificationBody    = watcher._cleanBody(n.body)
        pill.notificationIcon    = n.appIcon || ""

        pill.notificationActive = true
        hideTimer.restart()
    }

    
    
    function dismissCurrent() {
        if (!pill.notificationActive && !_current) return
        hideTimer.stop()
        pill.notificationActive = false
        if (_current) {
            _current.expire()
            _current = null
        }
        queueGapTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: watcher.displayDuration
        repeat: false
        onTriggered: watcher.dismissCurrent()
    }

    Timer {
        id: queueGapTimer
        interval: watcher.queueGap
        repeat: false
        onTriggered: watcher._showNext()
    }

    NotificationServer {
        id: server

        bodySupported:    true
        imageSupported:   true   
        
        
        
        
        
        
        
        actionsSupported: true
        keepOnReload:     false  

        onNotification: (notification) => {
            
            notification.tracked = true

            
            
            
            notification.closed.connect(function () {
                watcher._removeFromQueue(notification)
            })

            watcher._enqueue(notification)
        }
    }
}

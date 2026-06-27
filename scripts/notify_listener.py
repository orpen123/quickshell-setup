#!/usr/bin/env python3
import dbus
import json
import sys
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()


def on_notification(*args):
    try:
        app = str(args[0]) if len(args) > 0 else "Unknown"
        icon = str(args[2]) if len(args) > 2 else ""
        summary = str(args[3]) if len(args) > 3 else ""
        body = str(args[4]) if len(args) > 4 else ""
        data = {"app": app, "summary": summary, "body": body, "icon": icon}
        print("NOTIFY:" + json.dumps(data), flush=True)
    except:
        pass


bus.add_signal_receiver(
    on_notification,
    signal_name="Notify",
    dbus_interface="org.freedesktop.Notifications",
    path="/org/freedesktop/Notifications",
)

print("READY", flush=True)
GLib.MainLoop().run()

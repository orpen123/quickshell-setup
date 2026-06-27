#!/bin/bash

# Quickshell reload script
# Kills the current quickshell instance and restarts it

killall quickshell 2>/dev/null
sleep 0.2
quickshell &
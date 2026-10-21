#!/bin/sh
Xvfb :0 -screen 0 1600x900x24 &
sleep 1
fluxbox &
x11vnc -display :0 -forever -nopw -quiet -rfbport 5900 &
websockify --web /usr/share/novnc 6080 localhost:5900 &
sleep 1
exec "${APP:-netedit}" "$@"

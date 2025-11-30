#!/bin/bash

# VNC setup for Godot
export DISPLAY=:0
export RESOLUTION=${RESOLUTION:-1280x720}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}

# Kill any existing VNC/X sessions
pkill -9 Xvnc 2>/dev/null
pkill -9 godot4 2>/dev/null
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null

# Create necessary directories
mkdir -p ~/.vnc
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Start Xvnc directly
echo "Starting Xvnc server on display $DISPLAY with resolution $RESOLUTION"
Xvnc $DISPLAY -geometry $RESOLUTION -SecurityTypes None -rfbport 5900 -AlwaysShared -AcceptKeyEvents -AcceptPointerEvents -AcceptSetDesktopSize -SendCutText -AcceptCutText &
VNC_PID=$!

# Wait for X server to be ready
echo "Waiting for X server to start..."
X_READY=false
for i in {1..30}; do
    if xdpyinfo -display $DISPLAY >/dev/null 2>&1; then
        echo "X server is ready!"
        X_READY=true
        break
    fi
    sleep 0.5
done

if [ "$X_READY" = false ]; then
    echo "ERROR: X server failed to start after 15 seconds"
    kill $VNC_PID 2>/dev/null
    exit 1
fi

# Start Godot
echo "Starting Godot 4.4.1..."
godot4 --path . --editor 2>&1 &

echo "Godot is running. Connect via VNC viewer or use Replit's desktop view."
wait

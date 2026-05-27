#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Legion Mobile Sandbox — start_emulator.sh
# demo x hexa | Team Death Legion
#
# Starts Xvfb, x11vnc, noVNC, and Android 15 emulator with SIM card.
# Usage: bash start_emulator.sh [options]
#
# Options:
#   --vnc-password <pass>     Set VNC password (default: none)
#   --display <n>             X display number (default: 1)
#   --phone-number <number>   Virtual SIM phone number (default: +15551234567)
#   --network <type>          GSM network type: gsm|edge|lte|5gnr (default: lte)
#   --signal <0-4>            Signal strength (default: 4)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
AVD_NAME="LegionDevice"
DISPLAY_NUM=1
VNC_PORT=5901
NOVNC_PORT=6080
SCREEN_W=1280
SCREEN_H=800
SCREEN_D=24
VNC_PASSWORD=""
PHONE_NUMBER="+15551234567"
NETWORK_TYPE="lte"
SIGNAL_STRENGTH="4"

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --vnc-password) VNC_PASSWORD="$2"; shift 2 ;;
        --display)      DISPLAY_NUM="$2"; VNC_PORT=$((5900 + DISPLAY_NUM)); shift 2 ;;
        --phone-number) PHONE_NUMBER="$2"; shift 2 ;;
        --network)      NETWORK_TYPE="$2"; shift 2 ;;
        --signal)       SIGNAL_STRENGTH="$2"; shift 2 ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

export DISPLAY=":${DISPLAY_NUM}"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

log() { echo "[legion] $*"; }

# Kill previous instances cleanly
log "Stopping any previous instances..."
pkill -f "Xvfb :${DISPLAY_NUM}" 2>/dev/null || true
pkill -f "x11vnc" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true
pkill -f "emulator.*${AVD_NAME}" 2>/dev/null || true
sleep 2

# 1. Xvfb
log "Starting Xvfb on :${DISPLAY_NUM}..."
Xvfb ":${DISPLAY_NUM}" -screen 0 "${SCREEN_W}x${SCREEN_H}x${SCREEN_D}" -ac +extension RANDR &
XVFB_PID=$!
sleep 2

# 2. x11vnc
log "Starting x11vnc on port ${VNC_PORT}..."
if [ -n "$VNC_PASSWORD" ]; then
    x11vnc -display ":${DISPLAY_NUM}" -forever -shared \
        -rfbport "${VNC_PORT}" -noxdamage -noxfixes \
        -passwd "${VNC_PASSWORD}" \
        -bg -o /tmp/x11vnc.log
else
    x11vnc -display ":${DISPLAY_NUM}" -forever -shared \
        -rfbport "${VNC_PORT}" -noxdamage -noxfixes \
        -nopw \
        -bg -o /tmp/x11vnc.log
fi
sleep 2

# 3. noVNC
log "Starting noVNC on port ${NOVNC_PORT}..."
python3 /opt/novnc/utils/websockify/run \
    --web /opt/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" \
    > /tmp/novnc.log 2>&1 &
sleep 2

# 4. Android 15 emulator with SIM card
KVM_FLAG="-accel off"
[ -e /dev/kvm ] && KVM_FLAG="-accel on"

log "Starting Android 15 emulator (${AVD_NAME})..."
log "  SIM phone number: ${PHONE_NUMBER}"
log "  Network type    : ${NETWORK_TYPE}"
log "  Signal strength : ${SIGNAL_STRENGTH}/4"

"$ANDROID_HOME/emulator/emulator" \
    -avd "$AVD_NAME" \
    $KVM_FLAG \
    -gpu swiftshader_indirect \
    -no-snapshot \
    -no-audio \
    -no-boot-anim \
    -wipe-data \
    -skin 1080x2400 \
    -memory 4096 \
    -cores 4 \
    -phone-number "$PHONE_NUMBER" \
    -display ":${DISPLAY_NUM}" \
    > /tmp/emulator.log 2>&1 &
EMU_PID=$!

log "Emulator PID: $EMU_PID"
log ""
log "================================================================"
log "  Legion Mobile Sandbox — Android 15 — running"
log "  noVNC     : http://localhost:${NOVNC_PORT}/vnc.html"
log "  ADB       : $ANDROID_HOME/platform-tools/adb devices"
log "  SIM phone : ${PHONE_NUMBER}"
log "  Logs      : /tmp/emulator.log | /tmp/x11vnc.log | /tmp/novnc.log"
log "  Boot takes ~4 minutes."
log "================================================================"
log ""
log "Waiting for boot..."

ADB="$ANDROID_HOME/platform-tools/adb"
MAX_WAIT=480   # Android 15 may need more time
ELAPSED=0
STATUS="0"

while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$("$ADB" shell getprop sys.boot_completed 2>/dev/null || echo "0")
    STATUS=$(echo "$STATUS" | tr -d '[:space:]')
    if [ "$STATUS" = "1" ]; then
        break
    fi
    ELAPSED=$((ELAPSED + 10))
    log "  [${ELAPSED}s] booting..."
    sleep 10
done

if [ "$STATUS" != "1" ]; then
    log "WARNING: boot timed out after ${MAX_WAIT}s. Check /tmp/emulator.log"
    exit 1
fi

log "Android 15 is ready."

# Configure SIM via emulator console
sleep 3
if command -v socat &>/dev/null; then
    log "Configuring SIM card..."
    echo -e "network ${NETWORK_TYPE}\nquit" | socat - TCP:localhost:5554 2>/dev/null || true
    echo -e "gsm signal ${SIGNAL_STRENGTH} ${SIGNAL_STRENGTH}\nquit" | socat - TCP:localhost:5554 2>/dev/null || true
    echo -e "gsm voice home\nquit" | socat - TCP:localhost:5554 2>/dev/null || true
    echo -e "gsm data home\nquit"  | socat - TCP:localhost:5554 2>/dev/null || true
    log "  Network: ${NETWORK_TYPE^^}, Signal: ${SIGNAL_STRENGTH}/4"
fi

# Dismiss lock screen
"$ADB" shell input keyevent 82
"$ADB" shell input keyevent 4
log "Lock screen dismissed."
log ""
log "SIM telephony commands (requires socat):"
log "  echo -e 'sms send +15559876543 \"Hello\"\nquit' | socat - TCP:localhost:5554"
log "  echo -e 'gsm call +15559876543\nquit'           | socat - TCP:localhost:5554"
log "  echo -e 'gsm accept +15559876543\nquit'         | socat - TCP:localhost:5554"
log "  echo -e 'gsm cancel +15559876543\nquit'         | socat - TCP:localhost:5554"
log ""
log "Or use the ADB helper: bash scripts/adb_helper.sh sim-sms +15559876543 \"Hello\""

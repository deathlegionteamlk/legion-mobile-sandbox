#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Legion Mobile Sandbox — adb_helper.sh
# demo x hexa | Team Death Legion
#
# Usage:
#   bash adb_helper.sh screenshot [output_path]
#   bash adb_helper.sh install <apk_path_or_url>
#   bash adb_helper.sh tap <x> <y>
#   bash adb_helper.sh swipe <x1> <y1> <x2> <y2> [duration_ms]
#   bash adb_helper.sh type <"text">
#   bash adb_helper.sh key <keycode>
#   bash adb_helper.sh url <"https://...">
#   bash adb_helper.sh shell [command...]
#   bash adb_helper.sh devices
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"

if [ ! -f "$ADB" ]; then
    echo "ERROR: adb not found at $ADB"
    echo "Run setup.sh first, or set ANDROID_HOME."
    exit 1
fi

CMD="${1:-devices}"
shift || true

case "$CMD" in
    screenshot)
        DEST="${1:-./legion_screen.png}"
        "$ADB" shell screencap /sdcard/legion_screen.png
        "$ADB" pull /sdcard/legion_screen.png "$DEST"
        echo "Saved: $DEST"
        ;;

    install)
        APK="${1:-}"
        [ -z "$APK" ] && { echo "Usage: adb_helper.sh install <path_or_url>"; exit 1; }
        if [[ "$APK" == http* ]]; then
            TMP="/tmp/legion_install.apk"
            echo "Downloading $APK..."
            wget -q "$APK" -O "$TMP"
            APK="$TMP"
        fi
        "$ADB" install -r "$APK"
        ;;

    tap)
        X="${1:-540}"; Y="${2:-960}"
        "$ADB" shell input tap "$X" "$Y"
        echo "Tapped: $X $Y"
        ;;

    swipe)
        X1="${1:-540}"; Y1="${2:-1400}"; X2="${3:-540}"; Y2="${4:-400}"; DUR="${5:-300}"
        "$ADB" shell input swipe "$X1" "$Y1" "$X2" "$Y2" "$DUR"
        echo "Swiped: ($X1,$Y1) -> ($X2,$Y2) over ${DUR}ms"
        ;;

    type)
        TEXT="${1:-}"
        [ -z "$TEXT" ] && { echo "Usage: adb_helper.sh type \"your text\""; exit 1; }
        # Replace spaces with %s for adb input text
        ESCAPED=$(echo "$TEXT" | sed 's/ /%s/g')
        "$ADB" shell input text "$ESCAPED"
        echo "Typed: $TEXT"
        ;;

    key)
        CODE="${1:-}"
        [ -z "$CODE" ] && { echo "Usage: adb_helper.sh key <keycode_number_or_name>"; exit 1; }
        "$ADB" shell input keyevent "$CODE"
        echo "Key: $CODE"
        ;;

    url)
        URL="${1:-}"
        [ -z "$URL" ] && { echo "Usage: adb_helper.sh url \"https://...\""; exit 1; }
        "$ADB" shell am start -a android.intent.action.VIEW -d "$URL"
        echo "Opened: $URL"
        ;;

    shell)
        if [ $# -gt 0 ]; then
            "$ADB" shell "$@"
        else
            "$ADB" shell
        fi
        ;;

    devices)
        "$ADB" devices
        ;;

    logcat)
        "$ADB" logcat "$@"
        ;;

    # ── SIM / Telephony commands ──────────────────────────────
    # These go through the emulator console on port 5554 via socat.

    sim-sms)
        # bash adb_helper.sh sim-sms +15559876543 "Message text"
        FROM="${1:-+15559876543}"
        MSG="${2:-Test message from Legion Sandbox}"
        echo -e "sms send ${FROM} ${MSG}\nquit" | socat - TCP:localhost:5554
        echo "SMS sent from ${FROM}: ${MSG}"
        ;;

    sim-call)
        # bash adb_helper.sh sim-call +15559876543
        NUM="${1:-+15559876543}"
        echo -e "gsm call ${NUM}\nquit" | socat - TCP:localhost:5554
        echo "Incoming call from ${NUM} triggered."
        ;;

    sim-accept)
        NUM="${1:-+15559876543}"
        echo -e "gsm accept ${NUM}\nquit" | socat - TCP:localhost:5554
        echo "Call accepted: ${NUM}"
        ;;

    sim-cancel)
        NUM="${1:-+15559876543}"
        echo -e "gsm cancel ${NUM}\nquit" | socat - TCP:localhost:5554
        echo "Call cancelled: ${NUM}"
        ;;

    sim-signal)
        # bash adb_helper.sh sim-signal 4   (0=none, 4=excellent)
        SIG="${1:-4}"
        echo -e "gsm signal ${SIG} ${SIG}\nquit" | socat - TCP:localhost:5554
        echo "Signal set to ${SIG}/4"
        ;;

    sim-network)
        # bash adb_helper.sh sim-network lte
        # Options: gsm, edge, gprs, hsdpa, lte, 5gnr, none
        NET="${1:-lte}"
        echo -e "network ${NET}\nquit" | socat - TCP:localhost:5554
        echo "Network type set to: ${NET}"
        ;;

    sim-status)
        "$ADB" shell dumpsys telephony.registry | grep -E \
            'mPhoneNumber|mNetworkType|mDataConnectionState|mSignalStrength|mSimState|mOperatorAlpha' \
            || echo "No telephony info found. Is the emulator booted?"
        ;;

    sim-nosignal)
        echo -e "gsm signal 0 0\nquit"            | socat - TCP:localhost:5554
        echo -e "gsm voice unregistered\nquit"    | socat - TCP:localhost:5554
        echo -e "gsm data unregistered\nquit"     | socat - TCP:localhost:5554
        echo "Signal removed (airplane mode simulation)."
        ;;

    sim-restore)
        SIG="${1:-4}"
        NET="${2:-lte}"
        echo -e "gsm signal ${SIG} ${SIG}\nquit"  | socat - TCP:localhost:5554
        echo -e "gsm voice home\nquit"             | socat - TCP:localhost:5554
        echo -e "gsm data home\nquit"              | socat - TCP:localhost:5554
        echo -e "network ${NET}\nquit"             | socat - TCP:localhost:5554
        echo "Signal restored: ${SIG}/4, network: ${NET}"
        ;;

    *)
        echo "Unknown command: $CMD"
        echo ""
        echo "General:"
        echo "  screenshot [output_path]"
        echo "  install <apk_path_or_url>"
        echo "  tap <x> <y>"
        echo "  swipe <x1> <y1> <x2> <y2> [duration_ms]"
        echo "  type \"<text>\""
        echo "  key <keycode>"
        echo "  url \"<https://...>\""
        echo "  shell [command]"
        echo "  devices"
        echo "  logcat"
        echo ""
        echo "SIM card / Telephony:"
        echo "  sim-sms <from_number> \"<message>\"   — simulate incoming SMS"
        echo "  sim-call <number>                    — simulate incoming call"
        echo "  sim-accept <number>                  — accept the incoming call"
        echo "  sim-cancel <number>                  — cancel/end call"
        echo "  sim-signal <0-4>                     — set signal strength"
        echo "  sim-network <type>                   — gsm|edge|lte|5gnr|none"
        echo "  sim-status                           — show current SIM/network state"
        echo "  sim-nosignal                         — simulate no signal"
        echo "  sim-restore [signal] [network]       — restore signal"
        exit 1
        ;;
esac

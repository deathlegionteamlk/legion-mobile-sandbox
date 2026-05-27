#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Legion Mobile Sandbox — setup.sh
# demo x hexa | Team Death Legion
#
# Runs a full install on Ubuntu/Debian.
# Usage: bash setup.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ANDROID_HOME="/opt/android-sdk"
AVD_NAME="LegionDevice"
API_LEVEL="35"        # Android 15
ABI="x86_64"
TARGET="google_apis"

log()  { echo "[legion] $*"; }
err()  { echo "[legion] ERROR: $*" >&2; exit 1; }

# ── 1. System packages ──────────────────────────────────────
log "Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    openjdk-17-jdk xvfb x11vnc websockify \
    wget unzip curl \
    libgles2-mesa libpulse0 libasound2 \
    libxcomposite1 libxcursor1 libxi6 \
    libxrandr2 libxss1 libxtst6 \
    libgl1-mesa-glx libgl1-mesa-dri \
    xauth x11-xkb-utils xfonts-base xterm

java -version

# ── 2. Android SDK ──────────────────────────────────────────
log "Downloading Android SDK tools..."
SDK_ZIP="/tmp/cmdline-tools.zip"
wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
    -O "$SDK_ZIP"

sudo mkdir -p "$ANDROID_HOME/cmdline-tools"
sudo unzip -q "$SDK_ZIP" -d "$ANDROID_HOME/cmdline-tools/"

EXTRACTED="$ANDROID_HOME/cmdline-tools/cmdline-tools"
LATEST="$ANDROID_HOME/cmdline-tools/latest"
if [ -d "$EXTRACTED" ] && [ ! -d "$LATEST" ]; then
    sudo mv "$EXTRACTED" "$LATEST"
fi

export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# Write to /etc/profile.d so child processes pick it up
cat <<EOF | sudo tee /etc/profile.d/android.sh > /dev/null
export ANDROID_HOME=$ANDROID_HOME
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:\$PATH
EOF

log "sdkmanager: $(sdkmanager --version)"

# ── 3. SDK packages ─────────────────────────────────────────
log "Accepting licenses..."
yes | sdkmanager --licenses

for pkg in \
    "platform-tools" \
    "emulator" \
    "platforms;android-${API_LEVEL}" \
    "system-images;android-${API_LEVEL};${TARGET};${ABI}"
do
    log "Installing: $pkg"
    yes | sdkmanager "$pkg"
done

# ── 4. Create AVD ───────────────────────────────────────────
log "Creating AVD: $AVD_NAME"
echo no | avdmanager create avd \
    -n "$AVD_NAME" \
    -k "system-images;android-${API_LEVEL};${TARGET};${ABI}" \
    --device "pixel_3a" \
    --force

# Update config.ini
CONFIG_INI="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [ -f "$CONFIG_INI" ]; then
    declare -A HW_OVERRIDES=(
        [hw.ramSize]=2048
        [hw.cpu.ncore]=2
        [disk.dataPartition.size]="4096M"
        [vm.heapSize]=256
        [hw.lcd.density]=240
        [hw.lcd.width]=1080
        [hw.lcd.height]=1920
        [hw.gpu.enabled]=yes
        [hw.gpu.mode]=swiftshader_indirect
        [hw.audioInput]=no
        [hw.audioOutput]=no
        [hw.battery]=yes
        [hw.gps]=yes
        [hw.sensors.proximity]=yes
        [hw.sensors.acceleration]=yes
        [hw.camera.front]=none
        [hw.camera.back]=none
    )
    for key in "${!HW_OVERRIDES[@]}"; do
        value="${HW_OVERRIDES[$key]}"
        if grep -q "^${key}=" "$CONFIG_INI"; then
            sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_INI"
        else
            echo "${key}=${value}" >> "$CONFIG_INI"
        fi
    done
    log "AVD config updated."
else
    log "WARNING: config.ini not found at $CONFIG_INI"
fi

# ── 5. noVNC ────────────────────────────────────────────────
log "Installing noVNC..."
wget -q "https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz" -O /tmp/novnc.tar.gz
mkdir -p /opt/novnc
tar -xzf /tmp/novnc.tar.gz -C /opt/novnc --strip-components=1

wget -q "https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz" -O /tmp/websockify.tar.gz
mkdir -p /opt/novnc/utils/websockify
tar -xzf /tmp/websockify.tar.gz -C /opt/novnc/utils/websockify --strip-components=1

[ ! -f /opt/novnc/index.html ] && ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# ── Done ────────────────────────────────────────────────────
log "Setup complete. Run scripts/start_emulator.sh to launch."

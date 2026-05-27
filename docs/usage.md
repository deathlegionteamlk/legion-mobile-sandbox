# Usage

Extended notes for Legion Mobile Sandbox.

---

## Colab (recommended)

Open the notebook, paste your ngrok token in Cell 8, and run all cells. That's it.

If the emulator doesn't boot after 5 minutes, check the log in Cell 14. The most common cause on the free Colab tier is not enough RAM. Switching to a GPU runtime helps — it allocates more memory.

---

## Local Linux

### Full setup

```bash
git clone https://github.com/demo-x-hexa/legion-mobile-sandbox.git
cd legion-mobile-sandbox
bash scripts/setup.sh
```

This takes 5-10 minutes. It downloads ~1.5 GB of Android SDK packages.

### Start the emulator

```bash
bash scripts/start_emulator.sh
```

To set a VNC password:

```bash
bash scripts/start_emulator.sh --vnc-password mysecretpass
```

Open `http://localhost:6080/vnc.html` in a browser. The emulator takes ~3 minutes to boot.

---

## ADB

```bash
# Check device is connected
bash scripts/adb_helper.sh devices

# Take a screenshot
bash scripts/adb_helper.sh screenshot ./screen.png

# Install an APK from local disk
bash scripts/adb_helper.sh install /path/to/app.apk

# Install an APK from URL
bash scripts/adb_helper.sh install https://example.com/app.apk

# Tap at coordinates
bash scripts/adb_helper.sh tap 540 960

# Swipe up
bash scripts/adb_helper.sh swipe 540 1400 540 400 300

# Type text
bash scripts/adb_helper.sh type "hello world"

# Press back button
bash scripts/adb_helper.sh key 4

# Open URL in Chrome
bash scripts/adb_helper.sh url "https://google.com"

# Open ADB shell
bash scripts/adb_helper.sh shell

# Run a specific shell command
bash scripts/adb_helper.sh shell pm list packages

# View logcat
bash scripts/adb_helper.sh logcat
```

---

## Common Android keycodes

| Keycode | Key |
|---------|-----|
| 3 | Home |
| 4 | Back |
| 24 | Volume up |
| 25 | Volume down |
| 26 | Power |
| 82 | Menu / unlock |
| 187 | Recents |

---

## Useful ADB shell commands

```bash
# List installed packages
adb shell pm list packages

# Launch an app by package name
adb shell monkey -p com.example.app -c android.intent.category.LAUNCHER 1

# Clear app data
adb shell pm clear com.example.app

# Enable developer options (sets global setting)
adb shell settings put global development_settings_enabled 1

# Check CPU info
adb shell cat /proc/cpuinfo

# Check available storage
adb shell df

# Dump network stats
adb shell dumpsys connectivity
```

---

## Ports

| Service | Default port |
|---------|-------------|
| x11vnc  | 5901 |
| noVNC   | 6080 |
| ADB     | 5554 (emulator console), 5555 (ADB) |

---

## SIM card / Telephony

The emulator runs a full software telephony stack. The virtual SIM is enabled by default. The `-phone-number` flag on the emulator command sets the number that appears in the device's dialer.

### Set the phone number

In `start_emulator.sh`:
```bash
bash scripts/start_emulator.sh --phone-number "+447911123456"
```

In the Colab notebook, edit `SIM_PHONE_NUMBER` in Cell 8.

### Simulate incoming SMS

```bash
bash scripts/adb_helper.sh sim-sms +15559876543 "Your OTP is 482910"
```

Or directly via socat:
```bash
echo -e 'sms send +15559876543 "Hello"\nquit' | socat - TCP:localhost:5554
```

### Simulate incoming call

```bash
bash scripts/adb_helper.sh sim-call +15559876543
# Answer it:
bash scripts/adb_helper.sh sim-accept +15559876543
# Or hang up:
bash scripts/adb_helper.sh sim-cancel +15559876543
```

### Change network type

```bash
bash scripts/adb_helper.sh sim-network 5gnr    # 5G NR
bash scripts/adb_helper.sh sim-network lte     # 4G LTE
bash scripts/adb_helper.sh sim-network hsdpa   # 3G HSDPA
bash scripts/adb_helper.sh sim-network edge    # 2G EDGE
bash scripts/adb_helper.sh sim-network gsm     # 2G GSM
bash scripts/adb_helper.sh sim-network none    # no data
```

### Change signal strength

```bash
bash scripts/adb_helper.sh sim-signal 0   # no signal
bash scripts/adb_helper.sh sim-signal 1   # weak
bash scripts/adb_helper.sh sim-signal 2   # fair
bash scripts/adb_helper.sh sim-signal 3   # good
bash scripts/adb_helper.sh sim-signal 4   # excellent
```

### Simulate airplane mode conditions

```bash
bash scripts/adb_helper.sh sim-nosignal    # cuts all signal
bash scripts/adb_helper.sh sim-restore     # restores LTE + signal 4
```

### Check SIM status

```bash
bash scripts/adb_helper.sh sim-status
```

### Change default carrier identity

Edit `configs/avd_config.ini`:
```ini
gsm.sim.operator.numeric=310260    # MCC+MNC (310=US, 260=T-Mobile)
gsm.sim.operator.alpha=T-Mobile
gsm.sim.operator.iso-country=us
```

Common operator codes:
| Carrier | Numeric |
|---|---|
| T-Mobile US | 310260 |
| AT&T US | 310410 |
| Verizon US | 311480 |
| EE UK | 23430 |
| Vodafone UK | 23415 |
| Vodafone DE | 26202 |

---

## Changing the Android version

The default is Android 15 (API 35). To switch versions, edit `setup.sh` or Cell 4 in the notebook:

```bash
API_LEVEL="35"     # Android 15 (default)
API_LEVEL="34"     # Android 14
API_LEVEL="33"     # Android 13
```

Also update the system image package name:
```
system-images;android-35;google_apis;x86_64
```

Check what's available:
```bash
sdkmanager --list | grep "system-images"
```

Note: Android 15 needs ~4 GB RAM. Older versions can run with 2 GB.

---

## Screen resolution

The default Xvfb screen is 1280x800. The Android 15 emulator uses a 1080x2400 skin (Pixel 8 dimensions).

To change the Xvfb resolution, edit `SCREEN_W` and `SCREEN_H` in `start_emulator.sh`.

To change the emulator skin, change `-skin 1080x2400` in the emulator command.

---

## Running without ngrok

If you're on a local machine or have your own reverse proxy, you don't need ngrok. Just open:

```
http://localhost:6080/vnc.html
```

For remote access on a server, use SSH port forwarding:

```bash
ssh -L 6080:localhost:6080 user@your-server
```

Then open `http://localhost:6080/vnc.html` locally.

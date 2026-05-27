# Legion Mobile Sandbox

**Cloud Android 15 emulator with virtual SIM card. Runs in Google Colab. No local setup required.**

Built by **demo x hexa** | Team **Death Legion**

---

## What it does

Legion spins up a full Android 15 (API 35) device inside Google Colab and streams the screen to your browser over noVNC. The device has a virtual SIM card — you can simulate incoming SMS messages, phone calls, and network conditions without touching real carrier infrastructure. ADB gives you full shell access, app install, screenshots, and input.

---

## Quick start

1. Open the notebook in Colab:

   [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/demo-x-hexa/legion-mobile-sandbox/blob/main/notebooks/Legion_Mobile_Sandbox.ipynb)

2. Get a free ngrok token at [dashboard.ngrok.com](https://dashboard.ngrok.com/signup) and paste it into **Cell 8**.

3. Set your virtual phone number in **Cell 8** — `SIM_PHONE_NUMBER`.

4. Click **Runtime > Run all**.

5. Wait ~4 minutes. Cell 9 prints a public URL like `https://xxxx.ngrok.io/vnc.html`.

6. Open that URL. Android 15 boots in your browser with a working SIM.

---

## What you get

| Feature | Details |
|---|---|
| Android version | 15 (API 35), x86_64 |
| Device profile | Pixel 8 |
| RAM | 4096 MB |
| Storage | 8 GB |
| GPU | SwiftShader (software, no KVM needed) |
| Remote access | noVNC over websockify |
| Public tunnel | ngrok HTTPS |
| ADB | Full shell, install, screenshot, input, screen record |
| SIM card | Virtual SIM — GSM/LTE/5G, incoming calls, SMS |
| Carrier (default) | T-Mobile US (310-260), configurable |

---

## Virtual SIM card

The emulator runs a full telephony stack with a software SIM. You can simulate real-world mobile conditions for testing apps that depend on carrier services.

### Send an incoming SMS to the device

```bash
bash scripts/adb_helper.sh sim-sms +15559876543 "Test message"
```

Or in the Colab notebook (Cell 16):
```python
emu_cmd('sms send +15559876543 "Test message from Legion"')
```

### Simulate an incoming call

```bash
bash scripts/adb_helper.sh sim-call +15559876543
bash scripts/adb_helper.sh sim-accept +15559876543   # accept it
bash scripts/adb_helper.sh sim-cancel +15559876543   # or cancel
```

### Change network type and signal

```bash
bash scripts/adb_helper.sh sim-network 5gnr     # 5G
bash scripts/adb_helper.sh sim-network lte      # LTE
bash scripts/adb_helper.sh sim-network edge     # 2G EDGE
bash scripts/adb_helper.sh sim-signal 2         # weak signal
bash scripts/adb_helper.sh sim-signal 4         # full bars
bash scripts/adb_helper.sh sim-nosignal         # no signal
bash scripts/adb_helper.sh sim-restore          # restore full LTE
```

### Check SIM status

```bash
bash scripts/adb_helper.sh sim-status
```

---

## Notebook cells

| Cell | What it does |
|---|---|
| 1 | Checks CPU, RAM, KVM availability |
| 2 | Installs Java 17, Xvfb, x11vnc, websockify, socat |
| 3 | Downloads Android SDK command-line tools |
| 4 | Installs emulator + Android 15 system image |
| 5 | Creates AVD with SIM card + telephony config |
| 6 | Installs noVNC |
| 7 | Installs ngrok |
| 8 | Config — ngrok token, SIM phone number, network type |
| 9 | Starts Xvfb, x11vnc, noVNC, emulator with `-phone-number` |
| 10 | Waits for boot, configures SIM via emulator console |
| 11 | ADB helpers (tap, swipe, type, install, open URL) |
| 12 | In-notebook screenshot viewer |
| 13 | APK installer from URL |
| 14 | Screen recorder |
| 15 | Log viewer for troubleshooting |
| 16 | SIM card / telephony helpers (SMS, calls, signal) |
| 17 | Keep-alive loop (prevents Colab idle timeout) |

---

## ADB quick reference

```bash
# Check connected devices
adb devices

# Install an APK
adb install yourapp.apk

# Take a screenshot
adb shell screencap /sdcard/screen.png && adb pull /sdcard/screen.png ./screen.png

# Record screen (max 180s)
adb shell screenrecord --time-limit 30 /sdcard/record.mp4 && adb pull /sdcard/record.mp4 .

# Open a URL in Chrome
adb shell am start -a android.intent.action.VIEW -d "https://example.com"

# Tap / swipe / type
adb shell input tap 540 1200
adb shell input swipe 540 2000 540 800 300
adb shell input text "hello"

# Open ADB shell
adb shell

# List installed packages
adb shell pm list packages
```

---

## Running scripts locally

```bash
# Full setup (installs SDK, creates AVD, starts everything)
bash scripts/setup.sh

# Start emulator with custom SIM
bash scripts/start_emulator.sh \
    --phone-number "+15551234567" \
    --network lte \
    --signal 4

# SIM card commands
bash scripts/adb_helper.sh sim-sms +15559876543 "Hello"
bash scripts/adb_helper.sh sim-call +15559876543
bash scripts/adb_helper.sh sim-signal 2
bash scripts/adb_helper.sh sim-network 5gnr
bash scripts/adb_helper.sh sim-status
```

---

## Requirements

**Colab (recommended)**
- Google account (free tier works, T4 GPU runtime preferred)
- ngrok account (free) for the public URL

**Local Linux**
- Ubuntu 20.04+ or Debian 11+
- 8 GB RAM minimum (Android 15 uses ~4 GB)
- Java 17
- socat (for SIM card console commands)
- KVM is optional but makes boot ~3x faster

---

## Troubleshooting

**Emulator won't boot after 5 minutes**

Android 15 needs more RAM than older versions. Switch to a T4 GPU runtime (Runtime > Change runtime type > T4 GPU). Then re-run from Cell 1.

**noVNC loads but screen is black**

The emulator is still starting. Wait 30 more seconds and refresh. If it stays black, run Cell 15 and look for `ERROR` lines in the emulator log.

**SIM not showing in Settings > About phone**

The SIM activates after full boot. Run Cell 16 after Cell 10 confirms boot is complete. If it still doesn't appear, run:
```python
emu_cmd('gsm voice home')
emu_cmd('gsm data home')
```

**ngrok URL not appearing**

Check your token in Cell 8. If ngrok started but the URL didn't print:
```python
import subprocess, json
r = subprocess.run('curl -s http://localhost:4040/api/tunnels', shell=True, capture_output=True, text=True)
print(r.stdout)
```

---

## Project structure

```
legion-mobile-sandbox/
├── notebooks/
│   └── Legion_Mobile_Sandbox.ipynb   # Main Colab notebook (Android 15 + SIM)
├── scripts/
│   ├── setup.sh                      # Full local setup
│   ├── start_emulator.sh             # Launch with SIM options
│   └── adb_helper.sh                 # ADB + SIM card command wrapper
├── configs/
│   └── avd_config.ini                # AVD hardware + telephony config
├── docs/
│   └── usage.md                      # Extended usage notes
├── .github/
│   └── ISSUE_TEMPLATE/
├── LICENSE
├── CONTRIBUTING.md
└── README.md
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT. See [LICENSE](LICENSE).

---

## Team

**demo x hexa** | **Death Legion**

> Built for app developers, security researchers, and anyone who needs a throwaway Android 15 device with a working SIM card.

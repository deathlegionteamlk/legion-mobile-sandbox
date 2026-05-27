# Contributing

Thanks for wanting to help.

---

## How to report a bug

Open an issue. Include:
- What you ran (Colab, local Linux, something else)
- What you expected
- What actually happened
- The relevant log output (Cell 14 in the notebook, or `/tmp/emulator.log`)

If the emulator failed to boot, paste the last 50 lines of `/tmp/emulator.log`.

---

## How to submit a fix or feature

1. Fork the repo
2. Create a branch: `git checkout -b fix/your-description`
3. Make your changes
4. Test them (Colab or local)
5. Open a PR against `main`

Keep PRs focused. One fix or feature per PR makes review faster.

---

## What's useful to work on

- Support for newer Android versions (API 33, 34)
- A Dockerfile for local Docker-based runs
- ADB helper improvements (logcat filtering, screen record)
- GitHub Actions to smoke-test the notebook on new commits

---

## Code style

No strict linter enforced. Keep shell scripts `set -euo pipefail`. Keep Python readable.

---

## Team

demo x hexa | Team Death Legion

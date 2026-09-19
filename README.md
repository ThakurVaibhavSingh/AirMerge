

<div align="center">
<img width="1920" height="1080" alt="AirMerge main menu - wireless audit Bash toolkit" src="https://github.com/user-attachments/assets/6e746ca6-2a56-4a77-8a94-a861a9f0a887" />
<img width="1920" height="1080" alt="AirMerge WiFi audit module - monitor mode and handshake capture" src="https://github.com/user-attachments/assets/8d665514-e84c-4e78-a315-57081bc74ccf" />
<img width="1920" height="1080" alt="AirMerge Nmap scanning module - subnet sweep and OS detection" src="https://github.com/user-attachments/assets/139254f2-da29-438f-8e95-d5669562cb8d" />
<img width="1920" height="1080" alt="AirMerge Metasploit module - payload generation and sessions" src="https://github.com/user-attachments/assets/e6aca394-2d81-45e9-bb48-f6ebd67eddc9" />
<img width="1920" height="1080" alt="AirMerge cracking module - Hashcat, John, and Aircrack-ng" src="https://github.com/user-attachments/assets/3155e8e8-ec55-4c2c-ac91-ffd2ed9d1c87" />

# 🛰️ AirMerge

### A Modular Wireless & Network Audit Bash Toolkit for Kali Linux — v4

**One Bash menu for WiFi recon, deauth/handshake capture, Bettercap MITM, Nmap scanning, Metasploit, Hashcat/John/Aircrack cracking, and IP/MAC + Tor rotation.**

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/Platform-Linux-0078D6?style=for-the-badge&logo=linux&logoColor=white)](https://www.kernel.org/)
[![Kali](https://img.shields.io/badge/Tested%20On-Kali%20Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)](https://www.kali.org/)
[![License](https://img.shields.io/badge/License-Educational%20Use-orange?style=for-the-badge)](#-license)
[![Status](https://img.shields.io/badge/Status-Actively%20Developed-brightgreen?style=for-the-badge)](#-todo)
[![Root Required](https://img.shields.io/badge/Requires-Root-critical?style=for-the-badge)](#-requirements)
[![Stars](https://img.shields.io/github/stars/ThakurVaibhavSingh/AirMerge?style=for-the-badge&logo=github)](https://github.com/ThakurVaibhavSingh/AirMerge/stargazers)

</div>

---

> ⚠️ **Disclaimer:** AirMerge is a personal learning project for practicing wireless security, network scanning, and offline password recovery **on networks and devices you own or have explicit written permission to test**. Unauthorized use against networks you don't control is illegal in most jurisdictions. Use responsibly.

---

## 📖 What is AirMerge?

**AirMerge is a single-menu Bash toolkit that stitches together the most common wireless-auditing and network-pentesting tools into one interactive workflow.** Instead of juggling `airodump-ng`, `bettercap`, `nmap`, `msfconsole`, `hashcat`/`john`/`aircrack-ng`, and Tor in separate terminals with separate syntax, AirMerge gives you one menu, one state, and one place to work.

It auto-detects your interface/gateway/subnet, keeps the selected AP/target visible on-screen across every module, and hands off long-running scans and attacks to dedicated terminal windows (PID-tracked, Ctrl+C-safe) so the main menu never blocks.

Every run is logged to a per-session file, and you can save/restore your entire working state (interface, selected AP, subnet, files) between sessions.

Built and maintained by [Thakur Vaibhav Singh](https://github.com/ThakurVaibhavSingh) as a hands-on cybersecurity learning project — actively evolving, not a finished product.

---

## 🚀 Quick Start

```bash
git clone https://github.com/ThakurVaibhavSingh/AirMerge.git
cd AirMerge/Air
sudo ./airmerge.sh
```

On launch, AirMerge checks dependencies, lets you pick your wireless interface, and auto-detects your gateway and subnet. Navigate the numbered menu to jump into WiFi, Bettercap, Nmap, Metasploit, Hashcat, IP/MAC rotation, or session logging modules.

---

## ✨ Features

| Module | What it does |
|---|---|
| 📡 **WiFi Audit** | Dynamic interface picker (`iw dev` parsing, no hardcoded adapter names), monitor/managed toggle, dual scan paths (Airodump-ng auto-select or Bettercap manual review), deauth via Aireplay-ng or MDK4, handshake capture with automatic aircrack-ng verification and a direct hand-off into the cracking pipeline |
| 🐍 **Bettercap** | Timed network+wifi recon, target selection (auto or manual override), ARP+DNS spoofing with domain/target/fake-IP prompts, MITM session with timestamped pcap output |
| 🌐 **Nmap** | Full subnet sweep with live spinner and MAC/vendor parsing, single-host deep scan, curated/specific/all-ports submenus, aggressive version detection with an automatic stealthier retry when services look filtered/tcpwrapped, firewall & vulnerability scripts, OS detection, geo/whois lookups, active-user enumeration |
| 💣 **Metasploit** | Auto-starts PostgreSQL + msfdb, runs msfconsole inside a persistent tmux session (reattaches if already running), db_nmap integration, session list/interact/kill, Android/Windows/Linux payload generation (with APK auto-signing via a random keystore password), reverse-shell listener, and a one-off file server tunnelled out via SSH (localhost.run with serveo.net fallback) |
| 🔓 **Cracking** | Hash extraction for ZIP/RAR/PDF/7Z/KeePass/Office/WPA handshakes, a three-engine picker (Hashcat, John, Aircrack-ng), mask-based (digit/lower/upper/custom-order merge) or wordlist-based attacks, on-the-fly crunch wordlist generation, and a one-shot cleanup for temp files and potfiles |
| 🎭 **IP/MAC Rotation** | MAC randomization + forced DHCP renewal to get a fresh ISP-assigned IP, MAC restore, public-IP checker with multi-provider fallback, and a Tor auto-rotator — one-time idempotent control-port setup, then a self-running terminal that requests a new circuit on a user-set interval and confirms the exit IP actually changed |
| 📝 **Session Logging & State** | Every run writes a timestamped log to `logs/session_<date>.log` with key events (session start, module actions, state saves/loads). You can view the full log, tail it live in a separate terminal, or save/restore your working state (interface, AP, subnet, file paths) across sessions via `logs/last_session.state` |
| 🎨 **UX** | Color-coded output, figlet module banners, a dynamic status bar that only shows the state you've actually set (interface, AP, channel, IP, gateway, subnet, file, hashcat mode, etc.), stale-xterm detection on startup |

---

## 💪 Strengths

- **One entry point, six tools** — no need to remember flags across airodump-ng, bettercap, nmap, msfconsole, hashcat, john, aircrack-ng, and tor
- **State persistence across menus and sessions** — selected AP/channel/IP/gateway/subnet stay visible and carry over between modules, and can be saved to disk and reloaded on the next run
- **Per-session audit log** — every run is timestamped and logged; you can review it after the fact or tail it live
- **Non-blocking, PID-tracked long ops** — deauth, handshake capture, and scans run in separate terminal windows with tracked PIDs, so Ctrl+C in the main menu (or the window closing early) doesn't leave orphaned processes
- **Multi-terminal-emulator support** — `open_terminal()` falls back through xterm → gnome-terminal → xfce4-terminal → konsole instead of hard-requiring xterm
- **Sane defaults with override** — auto-detects interface, gateway, and subnet, but every value can be manually corrected if auto-detection is wrong
- **Real cleanup logic** — monitor interface teardown, hash/potfile clearing, a startup check for leftover xterm windows from a crashed session, and a Tor-service guard that stops any Tor instance left running from a previous run
- **CPU-only friendly** — cracking works via PoCL OpenCL even without a usable GPU device exposed to Hashcat
- **Ethical guardrails baked into the code, not just the docs** — `nmap.sh` deliberately leaves out active credential-guessing (users-brute) with an inline note on throttling and never evading target-side logging if it's ever added

---

## ⚙️ Requirements

- Linux (developed & tested on Kali Linux)
- Root privileges
- A wireless adapter that supports monitor mode (built-in laptop WiFi over a hotspot does not count — AirMerge can create a virtual monitor interface on some laptop adapters, but results vary)
- `aircrack-ng` suite, `mdk4`, `bettercap`, `nmap`, `metasploit-framework`, `hashcat`, `john`, `hcxpcapngtool`, `crunch`, `macchanger`, `tor`, `tmux`, `figlet`, `python3`
- A terminal emulator: `xterm` (preferred), or `gnome-terminal` / `xfce4-terminal` / `konsole` as a fallback
- For Tor rotation to affect browser traffic: the FoxyProxy browser extension, configured with a proxy entry pointing at Tor's SOCKS5 port (`127.0.0.1:9050`). AirMerge rotates the Tor circuit at the system level, but your browser must be told to actually route through it.

---

## 🧱 Weaknesses / Known Limitations

- 🔌 **Fails on WPA3-Personal mobile hotspots** — AirMerge assumes a router-based connection. If the target is only reachable via a WPA3-Personal hotspot (like an Android phone in WPA3 mode), the WiFi handshake capture and Bettercap MITM modules fail completely. Deauth may also fail in some cases, though not always — results vary by adapter and driver.
- **No GPU acceleration** — Hashcat runs CPU-only via PoCL; cracking speed is significantly slower than with a dedicated GPU. (My own GPU died in a recent Kali update, so GPU support isn't in yet — but it's a simple flag change if you have a working card.)
- **Terminal-dependent** — several modules assume a graphical session is available for spawning capture/deauth windows; won't work well over a pure headless SSH session (it won't fail, but the graphical view will be limited).
- **Minimal input validation in places** — most prompts validate format (MAC/IP/channel regex) but a few edge cases can still trip a module rather than fail gracefully
- **Logs are plain text, not structured reports** — the session log is a readable event trail, not a JSON/CSV report you can parse programmatically
- **Root-only, no privilege separation** — the whole suite runs as root for convenience, not least-privilege
- **Tor auto-rotator patches system torrc** — it edits `/etc/tor/torrc` to add a control-port password on first run; fine for a dedicated lab/VM, worth knowing before running on a daily-driver machine
- **Browser-side Tor routing needs FoxyProxy** — the system Tor circuit rotates, but a browser won't use it unless you've configured a proxy extension (see Requirements)

---

## 🗂️ Project Structure

```text
Air/
 └──
    ├── config/
    │   ├── config.sh          # Colors, banners, status bar, dep checks, global state
    │   └── handle.sh          # Terminal spawning, PID-tracked scan/deauth/capture runners
    ├── modules/
    │   ├── wifi.sh             # Monitor mode, dual-path scan, deauth, handshake capture
    │   ├── bettercap.sh        # Network scan, target selection, ARP/DNS spoof, MITM
    │   ├── nmap.sh              # Subnet/host scan, ports, services, OS detection, geo/whois
    │   ├── metasploit.sh       # msfconsole DB, db_nmap, sessions, payloads, tunnelled server
    │   ├── crack.sh             # Hash extraction + Hashcat/John/Aircrack cracking
    │   ├── iprotator.sh         # MAC/DHCP IP rotation, restore, Tor auto-rotator
    │   ├── logging.sh           # Per-session logs + save/load session state
    │   ├── workflow.sh          # Text-based module overview diagram
    │   ├── parse_scan.py        # Parses airodump-ng CSV *and* bettercap scan output
    │   └── pick_ap.py            # Resolves menu selection → BSSID/channel
    ├── logs/                     # Runtime logs + last_session.state (gitignored by default)
    ├── pass.sh                   # Dev helper — generates password-protected test files for crack.sh
    └── airmerge.sh                # Entry point — sources config/ + modules/, runs main menu
```

---

## 📝 TODO

- [ ] Handle Android-hotspot / no-monitor-mode environments gracefully instead of failing silently
- [ ] Add remaining input validation for edge-case MAC/IP/channel fields
- [ ] Export session logs to a structured format (JSON/CSV) for programmatic review
- [ ] Add a true headless mode that doesn't depend on a terminal emulator
- [ ] Config file for wordlist paths, default interface, and timeouts instead of editing config.sh directly
- [ ] Unit-test the Python parsers (parse_scan.py, pick_ap.py)
- [ ] More attack modules as I keep learning (this list will keep growing)

---

## 📄 License

This project is released for educational and authorized testing use only. See the disclaimer at the top for the full legal note. If you'd like a formal OSI license (MIT, GPL, etc.), open an issue and I'll add one.

<div align="center">

🚧 **Actively evolving** — I'm still learning as I build this, so expect rough edges and frequent changes. 🚧

Feedback and issues welcome.

</div>

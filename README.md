<div align="center">
<img width="1920" height="1080" alt="Screenshot_20260809_085241" src="https://github.com/user-attachments/assets/ec553281-3c10-4c37-9317-e019e3399cb3" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/7f901f43-1619-4f8a-b898-838f4a1e2d8f" />

# 🛰️ AirMerge

### A Modular Wireless & Network Audit Bash Toolkit

*WiFi Recon · Deauth/Handshake Capture · Bettercap MITM · Nmap Scanning · Metasploit · Hashcat/John/Aircrack Cracking · IP/MAC Rotation*

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-0078D6?style=for-the-badge&logo=linux&logoColor=white)
![Kali](https://img.shields.io/badge/Tested%20On-Kali%20Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![License](https://img.shields.io/badge/License-Educational%20Use-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Actively%20Developed-brightgreen?style=for-the-badge)
![Root Required](https://img.shields.io/badge/Requires-Root-critical?style=for-the-badge)

</div>

---

> ⚠️ **Disclaimer:** AirMerge is a personal learning project for practicing wireless security, network scanning, and offline password recovery **on networks and devices you own or have explicit written permission to test**. Unauthorized use against networks you don't control is illegal in most jurisdictions. Use responsibly.

---

## 📖 What is AirMerge?

AirMerge is a single-menu bash suite that stitches together the most common wireless-auditing and network-pentesting tools into one interactive workflow — instead of juggling `airodump-ng`, `bettercap`, `nmap`, `msfconsole`, and `hashcat` in separate terminals with separate syntax to remember. It auto-detects your interface/subnet, keeps the selected AP/target visible on-screen, and hands off long-running scans to dedicated `xterm` windows so the main menu stays usable.

Built and maintained by [Thakur Vaibhav Singh](https://github.com/ThakurVaibhavSingh) as a hands-on cybersecurity learning project — actively evolving, not a finished product.

---

## 🗂️ Project Structure

```
AirMerge/
├── Config/
│   └── config.sh          # Colors, banners, global state, root check
├── Handelers/
│   └── handelers.sh        # Interface checks, cleanup, dependency checks
├── Modules/
│   ├── wifi.sh              # Monitor mode, scanning, deauth, handshake, PMKID
│   ├── bettercap.sh         # Network scan, ARP/DNS spoof, MITM
│   ├── nmap.sh               # Subnet/host scan, ports, services, OS detection
│   ├── metaspliot.sh        # msfconsole DB, db_nmap, sessions, exploits
│   ├── crack.sh              # Hash extraction + Hashcat/John/Aircrack cracking
│   ├── iprotator.sh          # IP/MAC rotation & restore
│   ├── parse_scan.py         # Parses airodump-ng CSV output
│   └── pick_ap.py             # Resolves menu selection → BSSID/channel
└── airmerge.sh                # Entry point — sources everything, runs main menu
```

---

## ✨ Features

| Module | What it does |
|---|---|
| **📡 WiFi Audit** | Virtual Monitor/managed mode toggle, live AP scan (parsed via Python), deauth (aireplay-ng / mdk4), WPA handshake capture with auto-verification |
| **🐍 Bettercap** | Network scan, target selection, ARP+DNS spoofing, MITM session |
| **🌐 Nmap** | Full subnet sweep, single-host deep scan, port/service/OS detection, firewall & security checks |
| **💣 Metasploit** | Auto-starts PostgreSQL + msfdb, launches `msfconsole` in a persistent `tmux` session, `db_nmap` integration, session management |
| **🔓 Cracking** | Hash extraction (`zip2john`, `rar2john`, `pdf2john`, `7z2john`, `keepass2john`, `office2john`), mask & wordlist attacks across **Hashcat**, **John**, and **Aircrack-ng** |
| **🎭 IP/MAC Rotation** | Rotate and restore IP/MAC independently or together |
| **🎨 UX touches** | Color-coded output, `figlet` banners, persistent target/subnet status box, auto subnet detection from the active interface |

---

## 💪 Strengths

- **One entry point, six tools** — no need to remember flags across `airodump-ng`, `bettercap`, `nmap`, `msfconsole`, `hashcat`, `john`, and `aircrack-ng` individually
- **State persistence across menus** — selected AP/channel/subnet/IP stay visible and carry over between modules (e.g. scan in WiFi module → attack it in Cracking module)
- **Non-blocking long scans** — heavy operations run in separate `xterm` windows so the main menu never freezes
- **Sane defaults with override** — auto-detects interface and subnet, but still lets you pick manually
- **Real cleanup logic** — monitor interface teardown, cache/potfile clearing, and a `ctrlc_kill` trap so Ctrl+C doesn't leave orphaned processes
- **CPU-only friendly** — cracking works via PoCL OpenCL even without a usable GPU device exposed to Hashcat

---

## 🧱 Weaknesses / Known Limitations

- **🔌 Fails on isolated devices via WPA3/Android hotspot** — when the machine is tethered through a phone hotspot instead of a Router, interface creation, subnet auto-detection, and deauth/handshake capture **does/doesn't work**. AirMerge assumes that you are connected via Router so if the **target is connected via WPA3/Hotspot** any factor then WIFI and Bettercap MITM modules Fails Completely.
- **No GPU acceleration** — Hashcat runs CPU-only via PoCL; cracking speed is significantly slower than a real GPU device due to unavailability of a dedicated GPU 
- **PMKID capture is a stub** — `wifi_pmkid()` is unimplemented (`hcxdumptool` call is commented out)
- **`xterm`-dependent** — several modules assume `xterm` is installed and a graphical session is available; won't work well over a pure SSH/headless session
- **Minimal input validation** — most prompts assume correctly-formatted input (MAC addresses, IPs, channel numbers); malformed input can crash a module rather than fail gracefully
- **Hardcoded interface name fallback** (`wlan1`) in a couple of places — multi-adapter setups need manual checking
- **No logging/report output** — results print to terminal only; nothing is saved to a structured log or report file
- **Typos in folder/function names** (`Handelers`, `metaspliot`) — cosmetic, but not yet cleaned up
- **Root-only, no privilege separation** — the whole suite runs as root for convenience, not least-privilege

---

## ⚙️ Requirements

- Linux (developed & tested on **Kali Linux**)
- Root privileges
- A wireless adapter that supports **monitor mode** (built-in laptop WiFi over a hotspot does **not** count)
- `aircrack-ng` suite, `mdk4`, `bettercap`, `nmap`, `metasploit-framework`, `hashcat`, `john`, `xterm`, `figlet`, `tmux`, `python3`

---

## 🚀 Usage

```bash
git clone https://github.com/ThakurVaibhavSingh/AirMerge.git
cd AirMerge/AirMerge
sudo ./airmerge.sh
```

Navigate the numbered menu to jump into WiFi, Bettercap, Nmap, Metasploit, Hashcat, or IP/MAC rotation modules. The selected target (AP/channel or subnet/IP) is shown at the top of each relevant module and persists as you move between them.

---

## 📝 TODO

- [ ] Fix PMKID capture (`hcxdumptool` integration)
- [ ] Handle Android-hotspot / no-monitor-mode environments gracefully instead of failing silently
- [ ] Add input validation for MAC/IP/channel fields
- [ ] Add optional logging to a report file (per-session results)
- [ ] Replace remaining hardcoded `wlan1` fallback with dynamic detection
- [ ] Rename `Handelers` → `Handlers`, `metaspliot.sh` → `metasploit.sh`
- [ ] Add a headless mode that doesn't depend on `xterm`
- [ ] Config file for wordlist paths, default interface, and timeouts instead of editing `config.sh` directly
- [ ] Unit-test the Python parsers (`parse_scan.py`, `pick_ap.py`)
- [ ] More attack modules as I keep learning (this list will keep growing)

---

<div align="center">

**🚧 Actively evolving — I'm still learning as I build this, so expect rough edges and frequent changes. 🚧**

Feedback and issues welcome.

</div>

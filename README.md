<div align="center">
<img width="1920" height="1080" alt="Screenshot_20260903_191442" src="https://github.com/user-attachments/assets/6e746ca6-2a56-4a77-8a94-a861a9f0a887" />
<img width="1920" height="1080" alt="Screenshot_20260903_191450" src="https://github.com/user-attachments/assets/8d665514-e84c-4e78-a315-57081bc74ccf" />
<img width="1920" height="1080" alt="Screenshot_20260903_191528" src="https://github.com/user-attachments/assets/139254f2-da29-438f-8e95-d5669562cb8d" />
<img width="1920" height="1080" alt="Screenshot_20260903_191628" src="https://github.com/user-attachments/assets/e6aca394-2d81-45e9-bb48-f6ebd67eddc9" />
<img width="1920" height="1080" alt="Screenshot_20260903_191651" src="https://github.com/user-attachments/assets/3155e8e8-ec55-4c2c-ac91-ffd2ed9d1c87" />

# 🛰️ AirMerge

### A Modular Wireless & Network Audit Bash Toolkit — v4

*WiFi Recon · Deauth/Handshake Capture · Bettercap MITM · Nmap Scanning · Metasploit · Hashcat/John/Aircrack Cracking · IP/MAC + Tor Rotation*

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

AirMerge is a single-menu bash suite that stitches together the most common wireless-auditing and network-pentesting tools into one interactive workflow — instead of juggling `airodump-ng`, `bettercap`, `nmap`, `msfconsole`, `hashcat`/`john`/`aircrack-ng`, and Tor in separate terminals with separate syntax to remember. It auto-detects your interface/gateway/subnet, keeps the selected AP/target visible on-screen across every module, and hands off long-running scans and attacks to dedicated terminal windows (PID-tracked, Ctrl+C-safe) so the main menu never blocks.

Built and maintained by [Thakur Vaibhav Singh](https://github.com/ThakurVaibhavSingh) as a hands-on cybersecurity learning project — actively evolving, not a finished product.

---

## 🗂️ Project Structure

```
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
    │   ├── parse_scan.py        # Parses airodump-ng CSV *and* bettercap scan output
    │   └── pick_ap.py            # Resolves menu selection → BSSID/channel
    ├── pass.sh                   # Dev helper — generates password-protected test files for crack.sh
    └── airmerge.sh                # Entry point — sources config/ + modules/, runs main menu
```

---

## ✨ Features

| Module | What it does |
|---|---|
| **📡 WiFi Audit** | Dynamic interface picker (`iw dev` parsing, no hardcoded adapter names), monitor/managed toggle, dual scan paths (Airodump-ng auto-select or Bettercap manual review), deauth via **Aireplay-ng** or **MDK4**, handshake capture with automatic `aircrack-ng` verification and a direct hand-off into the cracking pipeline |
| **🐍 Bettercap** | Timed network+wifi recon, target selection (auto or manual override), ARP+DNS spoofing with domain/target/fake-IP prompts, MITM session with timestamped pcap output |
| **🌐 Nmap** | Full subnet sweep with live spinner and MAC/vendor parsing, single-host deep scan, curated/specific/all-ports submenus, aggressive version detection with an automatic stealthier retry when services look filtered/tcpwrapped, firewall & vulnerability scripts, OS detection, geo/whois lookups, active-user enumeration |
| **💣 Metasploit** | Auto-starts PostgreSQL + `msfdb`, runs `msfconsole` inside a persistent `tmux` session (reattaches if already running), `db_nmap` integration, session list/interact/kill, Android/Windows/Linux payload generation (with APK auto-signing via a random keystore password), reverse-shell listener, and a one-off file server tunnelled out via SSH (`localhost.run` with `serveo.net` fallback) |
| **🔓 Cracking** | Hash extraction for ZIP/RAR/PDF/7Z/KeePass/Office/WPA handshakes, a three-engine picker (**Hashcat**, **John**, **Aircrack-ng**), mask-based (digit/lower/upper/custom-order merge) or wordlist-based attacks, on-the-fly `crunch` wordlist generation, and a one-shot cleanup for temp files and potfiles |
| **🎭 IP/MAC Rotation** | MAC randomization + forced DHCP renewal to get a fresh ISP-assigned IP, MAC restore, public-IP checker with multi-provider fallback, and a **Tor auto-rotator** — one-time idempotent control-port setup, then a self-running terminal that requests a new circuit on a user-set interval and confirms the exit IP actually changed |
| **🎨 UX** | Color-coded output, `figlet` module banners, a dynamic status bar that only shows the state you've actually set (interface, AP, channel, IP, gateway, subnet, file, hashcat mode, etc.), stale-xterm detection on startup |

---

## 💪 Strengths

- **One entry point, six tools** — no need to remember flags across `airodump-ng`, `bettercap`, `nmap`, `msfconsole`, `hashcat`, `john`, `aircrack-ng`, and `tor`
- **State persistence across menus** — selected AP/channel/IP/gateway/subnet stay visible and carry over between modules (e.g. scan in WiFi → capture handshake → crack it without re-entering anything)
- **Non-blocking, PID-tracked long ops** — deauth, handshake capture, and scans run in separate terminal windows with tracked PIDs, so Ctrl+C in the main menu (or the window closing early) doesn't leave orphaned processes
- **Multi-terminal-emulator support** — `open_terminal()` falls back through `xterm` → `gnome-terminal` → `xfce4-terminal` → `konsole` instead of hard-requiring `xterm`
- **Sane defaults with override** — auto-detects interface, gateway, and subnet, but every value can be manually corrected if auto-detection is wrong
- **Real cleanup logic** — monitor interface teardown, hash/potfile clearing, a startup check for leftover xterm windows from a crashed session, and a Tor-service guard that stops any Tor instance left running from a previous run
- **CPU-only friendly** — cracking works via PoCL OpenCL even without a usable GPU device exposed to Hashcat
- **Ethical guardrails baked into the code, not just the docs** — `nmap.sh` deliberately leaves out active credential-guessing (`users-brute`) with an inline note on throttling and never evading target-side logging if it's ever added

---

## 🧱 Weaknesses / Known Limitations

- **🔌 Fails on isolated devices via WPA3/Android hotspot** — AirMerge assumes a router-based connection; if the target is only reachable via a WPA3/hotspot-style link, the WiFi and Bettercap MITM modules fail completely
- **No GPU acceleration** — Hashcat runs CPU-only via PoCL; cracking speed is significantly slower than with a dedicated GPU(Bcz in recent kali update my gpu became dead so sorry for not adding gpu support you can add that simply by some commands.)
- **PMKID capture is still a stub** — PMKID will be implimented when i will buy a new wifi antenna.
- **Terminal-dependent** — several modules assume a graphical session is available for spawning capture/deauth windows; won't work well over a pure headless SSH session(Not fails only graphical view will be low.)
- **Minimal input validation in places** — most prompts validate format (MAC/IP/channel regex) but a few edge cases can still trip a module rather than fail gracefully
- **No logging/report output** — results print to terminal only; nothing is saved to a structured log or report file
- **Root-only, no privilege separation** — the whole suite runs as root for convenience, not least-privilege
- **Tor auto-rotator patches system `torrc`** — it edits `/etc/tor/torrc` to add a control-port password on first run; fine for a dedicated lab/VM, worth knowing before running on a daily-driver machine

---

## ⚙️ Requirements

- Linux (developed & tested on **Kali Linux**)
- Root privileges
- A wireless adapter that supports **monitor mode** (built-in laptop WiFi over a hotspot does **not** count// I have created so it can create a virtual monitor interface on laptop adapters.)
- `aircrack-ng` suite, `mdk4`, `bettercap`, `nmap`, `metasploit-framework`, `hashcat`, `john`, `hcxpcapngtool`, `crunch`, `macchanger`, `tor`, `tmux`, `figlet`, `python3`
- A terminal emulator: `xterm` (preferred), or `gnome-terminal` / `xfce4-terminal` / `konsole` as a fallback

---

## 🚀 Usage

```bash
git clone https://github.com/ThakurVaibhavSingh/AirMerge.git
cd AirMerge/Air
sudo ./airmerge.sh
```

On launch, AirMerge checks dependencies, lets you pick your wireless interface, and auto-detects your gateway and subnet. Navigate the numbered menu to jump into WiFi, Bettercap, Nmap, Metasploit, Hashcat, or IP/MAC rotation modules — the selected target (AP/channel or subnet/IP) stays visible at the top of every relevant module and persists as you move between them.

---

## 📝 TODO

- [ ] IMPLIMENTAION PMKID capture (`hcxdumptool` integration)
- [ ] Handle Android-hotspot / no-monitor-mode environments gracefully instead of failing silently
- [ ] Add remaining input validation for edge-case MAC/IP/channel fields
- [ ] Add optional logging to a report file (per-session results)
- [ ] Add a true headless mode that doesn't depend on a terminal emulator
- [ ] Config file for wordlist paths, default interface, and timeouts instead of editing `config.sh` directly
- [ ] Unit-test the Python parsers (`parse_scan.py`, `pick_ap.py`)
- [ ] More attack modules as I keep learning (this list will keep growing)

---

<div align="center">

**🚧 Actively evolving — I'm still learning as I build this, so expect rough edges and frequent changes. 🚧**

Feedback and issues welcome.

</div>

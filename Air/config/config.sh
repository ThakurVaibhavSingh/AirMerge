#!/bin/bash

trap '' INT

DEPS=(aircrack-ng airodump-ng aireplay-ng bettercap nmap john hashcat figlet xterm hcxpcapngtool crunch iw mdk4 macchanger tor timeout ssh apksigner keytool python3 nmcli dhcpcd dhclient sudo fuser msfvenom nc openssl)

check_deps () {
    for dep in "${DEPS[@]}"; do
        if command -v "$dep" &>/dev/null; then
            info "$dep found"
        else
            err "$dep not found"
        fi
    done
    enter
}

print_banner() {
    echo -e "${GREEN}"
    figlet -f slant "AIRMERGE"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}

print_wifi() {
    echo -e "${GREEN}"
    figlet -f slant "AIRATTACK"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}

print_bettercap() {
    echo -e "${GREEN}"
    figlet -f slant "BETTERCAP"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}

print_nmap() {
    echo -e "${GREEN}"
    figlet -f slant "WIRELESS SCANNING"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}

print_hashcat() {
    echo -e "${GREEN}"
    figlet -f slant "OFFLINE HASHING"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}

print_iprotate() {
    echo -e "${GREEN}"
    figlet -f slant "IP&MAC CHANGER"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}

print_meta() {
    echo -e "${GREEN}"
    figlet -f slant "METASPLIOT"
    figlet -f slant "By: Thakur Vaibhav Singh"
    echo -e "${NC}"
    echo -e "${CYAN} Toolkit${NC}"
    echo
}
# ── Bright/Bold set ──
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
MAGENTA=$'\033[1;35m'
CYAN=$'\033[1;36m'
ORANGE=$'\033[38;5;208m'
PURPLE=$'\033[38;5;135m'
PINK=$'\033[38;5;213m'
TEAL=$'\033[38;5;30m'
LIME=$'\033[38;5;118m'

# ── Dim/Muted set ──
RED_DIM=$'\033[2;31m'
GREEN_DIM=$'\033[2;32m'
YELLOW_DIM=$'\033[2;33m'
BLUE_DIM=$'\033[2;34m'
MAGENTA_DIM=$'\033[2;35m'
CYAN_DIM=$'\033[2;36m'
WHITE_DIM=$'\033[2;37m'
ORANGE_DIM=$'\033[38;5;130m'
PURPLE_DIM=$'\033[38;5;97m'
PINK_DIM=$'\033[38;5;175m'
TEAL_DIM=$'\033[38;5;23m'
LIME_DIM=$'\033[38;5;64m'

# ── Formatting ──
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'


# ══════════════════════════════════════════════════════
# STATUS BANNER — margin-based, no hardcoded lines
# ══════════════════════════════════════════════════════

status_banner() {
    local items=()
    
    [[ -n "$INTER" ]]      && items+=("${DIM}IFACE${NC} ${CYAN}${INTER}${NC}")
    [[ -n "$INTERFACE" ]]  && items+=("${DIM}MON${NC} ${CYAN}${INTERFACE}${NC}")
    [[ -n "$ap" ]]         && items+=("${DIM}AP${NC} ${MAGENTA}${ap}${NC}")
    [[ -n "$ch" ]]         && items+=("${DIM}CH${NC} ${PINK}${ch}${NC}")
    [[ -n "$cp" ]]         && items+=("${DIM}CLIENT${NC} ${PINK}${cp}${NC}")
    [[ -n "$sec" ]]         && items+=("${DIM}SCANNED TIME${NC} ${PINK}${sec}${NC}")
	[[ -n "$pac" ]]         && items+=("${DIM}PACKETS${NC} ${PINK}${pac}${NC}")
    [[ -n "$IP" ]]         && items+=("${DIM}IP${NC} ${LIME}${IP}${NC}")
    [[ -n "$GATEWAY" ]]   && items+=("${DIM}GATEWAY${NC} ${LIME}${GATEWAY}${NC}")
    [[ -n "$SUBNET" ]]   && items+=("${DIM}SUBNET${NC} ${LIME}${SUBNET}${NC}")
    [[ -n "$file" ]]         && items+=("${DIM}FILE${NC} ${TEAL}${file}${NC}")
    [[ -n "$ext" ]]         && items+=("${DIM}EXTENSION${NC} ${TEAL}${ext}${NC}")
    [[ -n "$tools" ]]         && items+=("${DIM}USING_TOOL${NC} ${TEAL}${tools}${NC}")
    
    # Top margin + banner content + bottom margin
    printf "\n"
    
    if [[ ${#items[@]} -eq 0 ]]; then
        printf "  %sNo target selected — run Target Scan first%s\n" "${RED_DIM}" "${NC}"
    else
        printf "  "
        local first=1
        for item in "${items[@]}"; do
            if [[ $first -eq 1 ]]; then
                first=0
            else
                printf "  "   # gap between items
            fi
            printf "%s" "$item"
        done
        printf "\n"
    fi
    
    printf "\n"   # bottom margin
}

ap="${ap:-}"
ch="${ch:-}"
cp="${cp:-}"
IP="${IP:-}"
sec="${sec:-}"
GATEWAY="${GATEWAY:-}"
pac="${pac:-}"
file="${file:-}"
tools="${tools:-}"
ext="${ext:-}"
SUBNET="${SUBNET:-}"
GOTO_MAIN="${GOTO_MAIN:-0}"
HASHFILE="/home/$(logname)/hash.txt"
HCFILE="/home/$(logname)/hashcat_hash.txt"
#hashcat and john hash locations


check_stale_xterms() {
    local found
    found=$(pgrep -af xterm | grep -E "May not needed to close if its not long detailed one." 2>/dev/null)

    if [[ -n "$found" ]]; then
        warn "Found existing xterm window(s) still running:"
        echo "$found"
        warn "If these are leftover from a suspended/crashed session, kill manually with:"
        printf "  %skill -9 <PID>%s\n" "${CYAN}" "${NC}"
        printf "  %sor: pkill -f \"The xterm name\"%s\n" "${CYAN}" "${NC}"
        printf "  %sor: pkill -f \"PID is the first code \"%s\n" "${CYAN}" "${NC}"
        enter
    fi
}

info() { printf "%s[*] %s%s\n" "${GREEN}" "$1" "${NC}"; } #$1 means here that every part inside ""
err()  { printf "%s[!] %s%s\n" "${RED}" "$1" "${NC}"; }
warn() { printf "%s[!] %s%s\n" "${YELLOW}" "$1" "${NC}"; }
rel()  { printf "%s %s%s\n" "${ORANGE}" "$1" "${NC}"; }
relnext()  { printf "%s %s%s\n" "${CYAN}" "$1" "${NC}"; }
ask()  { printf "%s %s%s\n" "${PINK_DIM}" "$1" "${NC}"; }
userask() { read -rp "$(ask "Choose >>")" choice; }
buck() { printf "%s %s%s\n" "${RED_DIM}" "$1" "${NC}"; }
error() { err "Are you sure you choose correct"
            read -rp "press [ENTER] to continue"; }
enter() { read -rp "$(printf "%spress [ENTER] to continue%s\n" "${GREEN_DIM}" "${NC}")"; }
banner() { printf "%s%s%s\n" "${MAGENTA}" "$1" "${NC}";}



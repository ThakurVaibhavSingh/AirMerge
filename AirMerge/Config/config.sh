#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# CONGIGURATION
# ══════════════════════════════════════════════════════════════════════════════
print_banner() {
    echo -e "${RED}"
    figlet -f slant "AirAttack"
    echo -e "${NC}"
    echo -e "${CYAN}        Wireless Audit Toolkit${NC}"
    echo
}

print_banners () {
    echo -e "${RED}"
    figlet -f slant "Offline Cracking"
    echo -e "${NC}"
    echo -e "${CYAN}        Wireless Audit Toolkit${NC}"
    echo
}

bettercap_banner () {
    echo -e "${RED}"
    figlet -f slant "SwissCap"
    echo -e "${NC}"
    echo -e "${CYAN}       Toolkit${NC}"
    echo
}

nmap_banner () {
    echo -e "${RED}"
    figlet -f slant "AirScan"
    echo -e "${NC}"
    echo -e "${CYAN}       Toolkit${NC}"
    echo
}

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
ORANGE='\033[38;5;208m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
DIMMER='\033[2;90m'
NC='\033[0m'

#ROOT CHECK
if [[ $EUID -ne 0 ]]; then
    err "Run as root: sudo ./airattack.sh"
    exit 1
fi


GOTO_MAIN=0 #GOTO_MAIN=0 — global flag, starts as 0 (false).
INTERFA="wlan1"
ap="" #to announce it globally 
ch=""
SUBNET=""
cp=""
pac=""
info() { printf "${GREEN}[*] $1${NC}\n"; } #$1 means here that every part inside ""
err()  { printf "${RED}[!] $1${NC}\n"; }
warn() { printf "${YELLOW}[!] $1${NC}\n"; }
prin() { printf "${BLUE}[>>] $1${NC}\n";}
pp () { printf "${BOLD}${RED} $1 ${NC}\n";}
pt () { printf "${DIMMER}${YELLOW}${DIM} $1 ${NC}\n";}
into () { printf "${BOLD}${MAGENTA} $1${NC}\n";}	
to () { printf "${BOLD}${GREEN} $1${NC}\n";}
out () { printf "${BOLD}${RED} $1${NC}\n";}
pre () { printf "${DIMMER} $1${NC}\n";}

HASHFILE="/home/$(logname)/hash.txt"
HCFILE="/home/$(logname)/hashcat_hash.txt"
#hashcat and john hash locations
ACTIVE_PROC=0


prin_banner() {
    echo -e "${GREEN}"
    figlet -f slant "MAIN MENU"
    echo -e "${NC}"
    echo -e "${CYAN}        Toolkit${NC}"
    echo
}

workflow() {
    pp "$(printf "%-18s%-19s%-16s%-20s%-27s%-27s" "[WiFi]" "[Bettercap]" "[Nmap-NetIP]" "[Nmap-OtherIP]" "[Metasploit]" "[Hashcat]")"
    pt "$(printf "%-24s%-25s%-22s%-26s%-33s%-27s" "├──Monitor Mode" "├──Scan" "├──Scan Host" "├──Scan" "├──Start/Connect" "├──ZIP/RAR/7Z/CAP/OFFICE/KDBX")"
    pt "$(printf "%-24s%-25s%-22s%-26s%-33s%-27s" "├──Managed Mode" "├──Select AP" "├──Open Port" "├──Runtime" "├──Server Open" "├──Wordlist Creation")"			#%-22s fixed width keeps columns locked regardless of terminal tab width
    pt "$(printf "%-24s%-25s%-22s%-26s%-33s%-27s" "├──Scan" "├──DNS+ARP Spoof" "├──Service" "├──Security" "├──Network/Exploit Search" "├──HASHCAT")"
    pt "$(printf "%-24s%-25s%-22s%-26s%-33s%-27s" "├──Deauth" "├──Packet Sniffing" "├──Security" "├──Last Patched" "├──Active Session" "├──AIRCRACK")"
    pt "$(printf "%-24s%-25s%-22s%-26s%-33s%-27s" "├──Handshake" "├──MITM" "└──Version" "└──Active User" "├──Post Exploitation" "├──JOHN")"
    pt "$(printf "%-24s%-25s%-22s%-14s%-33s%-27s" "└──PMKID" "└──Packets" "" "" "└──Payloads" "└──Clear Previous Chache")"
    printf "\n"
}



show_target () {
    echo -e "${BLUE}╔═══════════════════════════════╗${NC}"
    if [[ -z $ap ]]; then
        echo -e "${BLUE}║    ${BOLD}AP: ${RED}Not Selected${NC}${BLUE}\t\t║${NC}"
        echo -e "${BLUE}║    ${BOLD}CH: ${RED}Not Selected${NC}${BLUE}\t\t║${NC}"
    else
        echo -e "${BLUE}║    ${BOLD}AP: ${GREEN}$ap${NC}${BLUE}\t║${NC}"
        echo -e "${BLUE}║    ${BOLD}CH: ${GREEN}$ch${NC}${BLUE}\t\t\t║${NC}"
    fi
    echo -e "${BLUE}╚═══════════════════════════════╝${NC}"
}

show_nmap () {
    echo -e "${BLUE}╔═══════════════════════════════╗${NC}"
    if [[ -z $SELECTED ]]; then
        echo -e "${BLUE}║    ${BOLD}SUBNET: ${RED}$SUBNET${NC}${BLUE}\t║${NC}"
        echo -e "${BLUE}║    ${BOLD}IP: ${RED}Not Selected${NC}${BLUE}\t\t║${NC}"
    else
        echo -e "${BLUE}║    ${BOLD}SUBNET: ${GREEN}$SUBNET${NC}${BLUE}\t║${NC}"
        echo -e "${BLUE}║    ${BOLD}IP: ${GREEN}$SELECTED${NC}${BLUE}\t\t║${NC}"
    fi
    echo -e "${BLUE}╚═══════════════════════════════╝${NC}"
}


show_nmaps () {
    echo -e "${BLUE}╔═══════════════════════════════╗${NC}"
    if [[ -z $SUBNET ]]; then
        echo -e "${BLUE}║    ${BOLD}IP: ${RED}$Not Selected${NC}${BLUE}\t\t║${NC}"
        
    else
        echo -e "${BLUE}║    ${BOLD}IP: ${GREEN}$SUBNET${NC}${BLUE}\t\t║${NC}"
        
    fi
    echo -e "${BLUE}╚═══════════════════════════════╝${NC}"
}



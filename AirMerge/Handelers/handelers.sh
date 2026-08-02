#!/bin/bash

DEPS=(aircrack-ng airodump-ng aireplay-ng bettercap nmap john hashcat figlet xterm hcxpcapngtool crunch iw mdk4 macchanger)

check_deps () {
    for dep in "${DEPS[@]}"; do
        if command -v "$dep" &>/dev/null; then
            info "$dep found"
        else
            err "$dep not found"
        fi
    done
    read -p "Press [Enter] to continue..."
}


# ══════════════════════════════════════════════════════════════════════════════
# INTERFACE SELECTION LOGIC
# ══════════════════════════════════════════════════════════════════════════════
select_interface () {
    # Parse `iw dev` blocks: pair each "Interface X" with its following "type Y"
    mapfile -t WIFI_IFACES < <(
        iw dev | awk '
            /^\s*Interface/ { iface=$2 }
            /^\s*type/      { if (iface != "" && $2 == "managed") print iface; iface="" }
        '
    )

    if [[ ${#WIFI_IFACES[@]} -eq 0 ]]; then
        err "No managed-mode wireless interfaces found."
        err "If you had a monitor interface running from a previous session, clean it up first (option 2)."
        exit 1
    fi

    info "Available wireless interfaces:"
    local i=1
    for iface in "${WIFI_IFACES[@]}"; do
        printf "${ORANGE}%d) %s${NC}\n" "$i" "$iface"
        ((i++))
    done

    read -rp "$(printf "${MAGENTA}Select interface (1-${#WIFI_IFACES[@]}): ${NC}")" pick
    if [[ $pick =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#WIFI_IFACES[@]} )); then
        INTER="${WIFI_IFACES[$((pick-1))]}"
    else
        err "Invalid selection — defaulting to ${WIFI_IFACES[0]}"
        INTER="${WIFI_IFACES[0]}"
    fi

    # Guard: never append "mon" onto something that's already a monitor-style name
    if [[ "$INTER" == *mon ]]; then
        err "Selected interface '$INTER' already looks like a monitor interface — aborting."
        exit 1
    fi

    INTERFACE="${INTER}mon"
    info "Managed: $INTER  |  Monitor: $INTERFACE"
    read -p "Press [Enter] to continue..."    
    #Here's a function that detects all wireless interfaces via iw dev, lets you pick one if there's more than one, and sets $INTER (and derives $INTERFACE as its monitor-mode name dynamically instead of hardcoding wlan0mon):
}


ctrlc_kill () {
    if [[ $ACTIVE_PROC -eq 1 ]]; then
        warn "Ctrl+C detected — stopping process..."
        pkill -TERM -f "airodump-ng" 2>/dev/null
        pkill -TERM -f "aireplay-ng" 2>/dev/null
        pkill -TERM -f "mdk4" 2>/dev/null
        sleep 2
        pkill -9 -f "airodump-ng" 2>/dev/null
        pkill -9 -f "aireplay-ng" 2>/dev/null
        pkill -9 -f "mdk4" 2>/dev/null
        pkill -9 -f "xterm.*mdk4"
        ACTIVE_PROC=0
    fi
    while read -r -t 0.1 -n 1000 discard; do :; done
}
trap 'ctrlc_kill' SIGINT
#This means Ctrl+C anywhere it check active process in the script and kills it. The script keeps running.


# ══════════════════════════════════════════════════════════════════════════════
# WIFI LOGIC
# ══════════════════════════════════════════════════════════════════════════════


cleanup () {
	
	if ! ip link show "$INTERFACE" >/dev/null 2>&1; then  #! — negates the condition [[ this part]], so if wlan0mon does not exist → print error and return.
        info "$INTERFACE is not created"
        return 1
	fi
	
    ip link show "$INTERFACE" >/dev/null 2>&1 && {
    sudo ip link set "$INTERFACE" down 2>/dev/null
    sudo iw dev "$INTERFACE" del 2>/dev/null
    info "Virtual Interface Removed"
	}
}


wlan_checker () {
        if ! ip link show "$INTER" >/dev/null 2>&1; then  #! — negates the condition [[ this part]], so if wlan0mon does not exist → print error and return.
        err "$INTER not found — Enable it First"
        return 1
		fi
}



mon_checker () {
        if ! ip link show "$INTERFACE" >/dev/null 2>&1; then  #! — negates the condition [[ this part]], so if wlan0mon does not exist → print error and return.
        err "$INTERFACE not found — Create Monitor Mode first"
        read -rp "$(pt "Press [Enter] to continue")"
        return 1
		fi
}

handshake_check () {
	    
	if ls handshake* 2>/dev/null | grep -q .; then  #ls handshake* 2>/dev/null — lists matching files, suppresses error if none found. grep -q . — returns true if any output exists (at least one file matched).
    rm -f handshake-* 2>/dev/null					#better for this tyoe if [[ -f handshake* ]]; then
    warn "Handshake file removed"
    else 
		warn "No Previous Handshake file"
    fi
	read -p ">>"
}

# ══════════════════════════════════════════════════════════════════════════════
# 		BETTERCAP LOGIC
# ══════════════════════════════════════════════════════════════════════════════

sunet () {
    local label
    if [[ -z $SNET ]]; then
        label="Not Selected"
    else
        label="$SNET"
    fi

    # Fixed inner width = 29 chars (between ║ and ║)
    local inner="Target: $label"
    local padded
    padded=$(printf "%-29s" "$inner")   # left-align, pad to 29

    echo -e "${MAGENTA} ╔═══════════════════════════════╗${NC}"
    into "║${BOLD}${RED}${padded}${NC}${MAGENTA}  ║${NC}"
    echo -e "${MAGENTA} ╚═══════════════════════════════╝${NC}"
}


# ══════════════════════════════════════════════════════════════════════════════
# NMAP LOGIC
# ══════════════════════════════════════════════════════════════════════════════

ip_check () {
 if [[ ! $SUBNET =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$ ]]; then  # checks if $SUBNET looks like 192.168.1.0 or 192.168.1.0/24. If not, error and return
    err "Invalid IP/CIDR format: $SUBNET"
    read -p "Press [Enter] to continue..."
    return 1
 fi
}

#==========================================================================
#Hashcat Logic

validate_digit () {
	local value=$1
	if [[ ! $value =~ ^[0-9]+$ ]]; then
		err "Enter a valid number"
		return 1
	fi
	return 0
}



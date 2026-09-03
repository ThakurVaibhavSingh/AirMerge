#!/bin/bash

# ── Check public IP via web ──
check_public_ip() {
    local ip
    ip=$(curl -s --max-time 3 --connect-timeout 2 https://api.ipify.org 2>/dev/null || \
         curl -s --max-time 3 --connect-timeout 2 https://ifconfig.me 2>/dev/null || \
         curl -s --max-time 3 --connect-timeout 2 https://icanhazip.com 2>/dev/null)
    if [[ -n "$ip" ]]; then
        info "Current Public IP: ${BOLD}$ip${NC}"
    else
        err "Could not determine public IP — check internet connection"
    fi
}

# ── Rotate MAC + force new public IP from ISP ──
public_ip_rotate() {
    if [[ -z "$INTER" ]]; then
        err "No interface selected"
        return 1
    fi

    info "Current public IP:"
    check_public_ip

    warn "Bringing $INTER down to change MAC..."
    sudo ip link set "$INTER" down 2>/dev/null
    sleep 1

    sudo macchanger -r "$INTER" || {
        err "macchanger failed"
        sudo ip link set "$INTER" up
        return 1
    }

    sudo ip link set "$INTER" up
    sleep 2

    # Release old DHCP lease and request new one
    # Modern systems use NetworkManager or dhcpcd instead of dhclient
    if command -v nmcli &>/dev/null; then
        sudo nmcli con down "$INTER" 2>/dev/null
        sleep 1
        sudo nmcli con up "$INTER" 2>/dev/null
    elif command -v dhcpcd &>/dev/null; then
        sudo dhcpcd -k "$INTER" 2>/dev/null
        sleep 1
        sudo dhcpcd "$INTER" 2>/dev/null
    elif command -v dhclient &>/dev/null; then
        sudo dhclient -r "$INTER" 2>/dev/null
        sleep 1
        sudo dhclient "$INTER" 2>/dev/null
    else
        # Fallback: just bounce the interface
        sudo ip link set "$INTER" down
        sleep 2
        sudo ip link set "$INTER" up
    fi

    sleep 3
    info "New public IP:"
    check_public_ip
}

# ── Restore original MAC ──
restore_mac() {
    if [[ -z "$INTER" ]]; then
        err "No interface selected"
        return 1
    fi

    sudo ip link set "$INTER" down
    sudo macchanger -p "$INTER"
    sudo ip link set "$INTER" up
    info "MAC restored to permanent/original"

    # Reconnect to get original IP back
    if command -v nmcli &>/dev/null; then
        sudo nmcli con down "$INTER" 2>/dev/null
        sleep 1
        sudo nmcli con up "$INTER" 2>/dev/null
    elif command -v dhcpcd &>/dev/null; then
        sudo dhcpcd -k "$INTER" 2>/dev/null
        sleep 1
        sudo dhcpcd "$INTER" 2>/dev/null
    fi

    sleep 2
    info "Public IP after restore:"
    check_public_ip
}

# ══════════════════════════════════════════════════════
# AUTO IP ROTATOR — xterm-controlled, Ctrl+C aware
# ══════════════════════════════════════════════════════
tor_auto_rotate() {
    local tor_auth_file="$HOME/.airmerge/.tor_control_pass"
    mkdir -p "$(dirname "$tor_auth_file")"

    # ── Idempotent credential setup: runs once per machine, self-heals stale torrc state ──
    if [[ ! -f "$tor_auth_file" ]]; then
        info "Setting up Tor control auth (first run on this system)..."
        local tor_pass tor_hash
        tor_pass=$(openssl rand -base64 24)
        tor_hash=$(tor --hash-password "$tor_pass" 2>/dev/null | tail -1)

        sudo sed -i '/^ControlPort 9051/d; /^HashedControlPassword/d; /^MaxCircuitDirtiness 15/d' /etc/tor/torrc

        sudo tee -a /etc/tor/torrc >/dev/null <<EOF
ControlPort 9051
HashedControlPassword $tor_hash
MaxCircuitDirtiness 15
EOF
        echo "$tor_pass" > "$tor_auth_file"
        chmod 600 "$tor_auth_file"

        if systemctl is-active --quiet tor@default; then
            sudo systemctl restart tor@default
            sleep 3
        fi
    fi

    # ── Single source of truth for Tor service state ──
if systemctl is-active --quiet tor@default; then
echo -e ""
else
warn "Tor is not running — starting it now..."

sudo systemctl start tor@default
sleep 3

if ! systemctl is-active --quiet tor@default; then
err "Failed to start Tor — check: sudo systemctl status tor@default"
enter
return 1
fi
info "Tor started successfully"
fi

pkill -f "Tor Auto Rotator" 2>/dev/null
sleep 1

if ! command -v tor &>/dev/null; then
err "Tor is not installed. Run: sudo apt install tor"
enter
return 1
fi

read -rp "$(printf "%sRotation interval in seconds (default 30): %s" "${BLUE_DIM}" "${NC}")" interval
interval="${interval:-30}"
if [[ ! "$interval" =~ ^[0-9]+$ ]] || [[ "$interval" -lt 15 ]]; then
err "Interval must be a number >= 15"
enter
return 1
fi

info "Launching Tor Auto Rotator..."
info "Interval: ${interval}s | Close xterm to stop"

# ── Write the rotator script to a temp file ──
local rotator_file="/tmp/tor_rotator_$$.sh"
cat > "$rotator_file" <<'EOF'
#!/bin/bash
INTERVAL=__INTERVAL__

GREEN=$'\033[1;32m'
RED=$'\033[1;31m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[1;36m'
DIM=$'\033[2m'
NC=$'\033[0m'

info() { printf "%s[*] %s%s\n" "${GREEN}" "$1" "${NC}"; }
err()  { printf "%s[!] %s%s\n" "${RED}" "$1" "${NC}"; }
warn() { printf "%s[!] %s%s\n" "${YELLOW}" "$1" "${NC}"; }

get_ip() {
    curl -s --max-time 10 --socks5-hostname 127.0.0.1:9050 https://api.ipify.org 2>/dev/null || \
    curl -s --max-time 10 --socks5-hostname 127.0.0.1:9050 https://ifconfig.me 2>/dev/null || \
    echo "unknown"
}

new_circuit() {
    printf 'AUTHENTICATE "__TOR_PASS__"\r\nSIGNAL NEWNYM\r\nQUIT\r\n' | nc __NC_OPTS__ 127.0.0.1 9051 2>/dev/null
}

count=1
while true; do
    echo ""
    echo "══════════════════════════════════════════════════════"
    printf "${CYAN}Rotation #%d${NC} | ${DIM}%s${NC}\n" "$count" "$(date +%H:%M:%S)"
    echo "══════════════════════════════════════════════════════"

    old_ip=$(get_ip)
    printf "${DIM}Current Tor IP: %s${NC}\n" "$old_ip"

    warn "Requesting new Tor circuit..."
    new_circuit
    sleep 3

    new_ip=$(get_ip)
    printf "${GREEN}[*] New Tor IP: %s${NC}\n" "$new_ip"

    if [[ "$old_ip" != "$new_ip" && "$new_ip" != "unknown" ]]; then
        info "Circuit changed successfully!"
    elif [[ "$new_ip" == "unknown" ]]; then
        err "Could not verify new IP — is Tor running?"
    else
        warn "Same exit node — Tor may have reused the circuit"
    fi

    printf "${DIM}Next rotation in %ss...${NC}\n" "$INTERVAL"
    sleep "$INTERVAL"
    ((count++))
done
EOF

local tor_pass nc_opts
tor_pass=$(cat "$tor_auth_file" 2>/dev/null)
nc_opts="-w1"
nc -h 2>&1 | grep -q -- "-q" && nc_opts="-q1"

sed -i "s/__INTERVAL__/$interval/" "$rotator_file"
sed -i "s|__TOR_PASS__|$tor_pass|" "$rotator_file"
sed -i "s/__NC_OPTS__/$nc_opts/" "$rotator_file"
chmod +x "$rotator_file"

open_terminal "Tor Auto Rotator" "bash '$rotator_file'"
info "Tor Auto Rotator running in background"
info "Close the extra window or press Ctrl+C in it to stop"
enter
}

iprotator_menu() {
    clear
	while true; do
        status_banner
        print_iprotate
        echo -e ""
        relnext "1) Rotate Public IP (MAC + DHCP)"
        relnext "2) Check Current Public IP"
        relnext "3) Restore Original MAC"
        relnext "4) Tor IP rotate"
        buck "0) Back"

        userask

        case $choice in
            1) public_ip_rotate ;;
            2) check_public_ip; enter ;;
            3) restore_mac ;;
			4) tor_auto_rotate ;;
            0) break ;;
            *) error ;;
        esac
    done
}

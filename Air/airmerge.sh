#!/bin/bash

# Find the directory this script lives in, so sourcing works
# no matter where you run suite.sh from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config/config.sh"
source "$SCRIPT_DIR/config/handle.sh"
source "$SCRIPT_DIR/modules/wifi.sh"
source "$SCRIPT_DIR/modules/bettercap.sh"
source "$SCRIPT_DIR/modules/crack.sh"
source "$SCRIPT_DIR/modules/nmap.sh"
source "$SCRIPT_DIR/modules/metasploit.sh"
source "$SCRIPT_DIR/modules/iprotator.sh"

# ...then your main() / workflow() menu function, which calls
# crack_menu, wifi_menu, bettercap_menu etc. — those functions
# now exist because they were sourced in above


run () {
		if systemctl is-active --quiet tor@default; then
        	info "Tor was running"
			warn "Its close now"
			sudo systemctl stop tor@default 
			enter
		else 
			info "Nothing"
			enter
		fi
		clear	
		print_banner
		check_deps || { err "Dependency check failed"; exit 1; }
		clear
		select_interface || return 1
		GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')
		SUBNET=$(ip route | grep -v default | grep "$INTER" | awk '{print $1}')
		SUBNET=${SUBNET:-$(ip -o -f inet addr show "$INTER" | awk '/scope global/ {print $4}')}
		[[ -z "$SUBNET" ]] && warn "Could not detect subnet — some features (bettercap spoof/mitm, nmap sub-network scan) will need a manual IP"

}

trap 'rm -f "$HOSTFILE" "$HOSTFILE.raw" "$PORTFILE" 2>/dev/null' EXIT

run


while true; do
		clear
		check_stale_xterms
		status_banner
		print_banner

		rel "1) WIFI Audit Script"
		rel "2) BETTERCAP Script"
		rel "3) NMAP Script"
		rel "4) METASPLOIT Script"
		rel "5) HASHCAT Script"
		rel "6) IP/MAC Rotate"
		buck "0) EXIT"
		
		userask
		
		case $choice in 
			
			1) wifi_main_menu;;
			
			2)bettercap_menu;;
			
			3)nmap_menu;;
			
			4)meta_menu;;
			
			5)crack_menu;;
			
			6)iprotator_menu;;
			
			0) info "Have a Nice Day"
				break
				cleanup;;
				
			*)error ;;
		esac

 done

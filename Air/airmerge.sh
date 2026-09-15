#!/bin/bash

# Find the directory this script lives in, so sourcing works
# no matter where you run suite.sh from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$SCRIPT_DIR/logs/last_session.state"

source "$SCRIPT_DIR/config/config.sh"
source "$SCRIPT_DIR/config/handle.sh"
source "$SCRIPT_DIR/modules/wifi.sh"
source "$SCRIPT_DIR/modules/bettercap.sh"
source "$SCRIPT_DIR/modules/crack.sh"
source "$SCRIPT_DIR/modules/nmap.sh"
source "$SCRIPT_DIR/modules/metasploit.sh"
source "$SCRIPT_DIR/modules/iprotator.sh"
source "$SCRIPT_DIR/modules/logging.sh"
source "$SCRIPT_DIR/modules/workflow.sh"

# ...then your main() / workflow() menu function, which calls
# crack_menu, wifi_menu, bettercap_menu etc. — those functions
# now exist because they were sourced in above


run () {
		check_stale_terminals
		if systemctl is-active --quiet tor@default; then
        	info "Tor was running"
			warn "Its close now"
			sudo systemctl stop tor@default 
			enter
		fi
		clear	
		print_banner
		check_deps || { err "Dependency check failed"; exit 1; }
		clear
		init_session_log
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
		status_banner
		print_banner

		printf "%s1) Logging Sessions\n%s" "${PURPLE}" "${NC}"
		printf "%s11) Logging Sessions Live\n%s" "${MAGENTA}" "${NC}"
		printf "%s25) Workflow View\n%s" "${MAGENTA_DIM}" "${NC}"
		printf "%s2) WIFI Audit Script\n%s" "${BLUE}" "${NC}"
		printf "%s3) BETTERCAP Script\n%s" "${GREEN}" "${NC}"
		printf "%s4) NMAP Script\n%s" "${YELLOW}" "${NC}"
		printf "%s5) METASPLOIT Script\n%s" "${PINK}" "${NC}"
		printf "%s6) HASHCAT Script\n%s" "${TEAL}" "${NC}"
		printf "%s7) IP/MAC Rotate\n%s" "${LIME}" "${NC}"
		printf "%s8) Save the loggings\n%s" "${ORANGE}" "${NC}"
		if [[ -f "$STATE_FILE" ]]; then
		printf "%s9) Load the loggings\n%s" "${CYAN}" "${NC}"
		fi


		buck "0) EXIT"
		
		userask
		
		case $choice in 
			
			1) view_session_log;;

			11) view_session_log_live;;

			2)	if [[ -z $ap ]];then
				 wifi_main_menu
				else
					wifi_attack_menu
				fi ;;
			
			3)bettercap_menu;;
			
			4)nmap_menu;;
			
			5)meta_menu;;
			
			6)crack_menu;;
			
			7)iprotator_menu;;
			
			8) save_session_state ;;

			9) load_session_state ;;

			0) info "Have a Nice Day"
				save_session_state
				break;;

			25) workflow ;;
				
			*)error ;;
		esac

 done

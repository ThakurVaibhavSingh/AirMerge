#!/bin/bash

# Find the directory this script lives in, so sourcing works
# no matter where you run suite.sh from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/Config/config.sh"
source "$SCRIPT_DIR/Handelers/handelers.sh"
source "$SCRIPT_DIR/Modules/wifi.sh"
source "$SCRIPT_DIR/Modules/bettercap.sh"
source "$SCRIPT_DIR/Modules/crack.sh"
source "$SCRIPT_DIR/Modules/nmap.sh"
source "$SCRIPT_DIR/Modules/metaspliot.sh"
source "$SCRIPT_DIR/Modules/iprotator.sh"

# ...then your main() / workflow() menu function, which calls
# crack_menu, wifi_menu, bettercap_menu etc. — those functions
# now exist because they were sourced in above


run () {
	
		clear	
		prin_banner
		#prin "Script Loading....."
		#sleep 1
		check_deps
		clear
		#prin "Loading....."
		#sleep 1
		select_interface
		SUNET=$(ip route | grep -v default | grep "$INTER" | awk '{print $1}')
		#This grabs the local subnet automatically from the interface — no manual input needed. 

}

run


while true; do
		    clear
			prin_banner
			workflow
    
		
		into "1) WIFI Audit Script"
		into "2) BETTERCAP Script"
		into "3) NMAP Script"
		into "4) METASPLOIT Script"
		into "5) HASHCAT Script"
		into "6) IP/MAC Rotate"
		out "0) EXIT"
		
		read -rp "$(printf "${BOLD}${DIM}${GREEN}Choose any option ==>${NC}\t")" choice
		
		case $choice in 
			
			1) wifi_menu;;
			
			2)bettercap_menu;;
			
			3)nmap_menu;;
			
			4)meta_menu;;
			
			5)crack_menu;;
			
			6)iprotator_menu;;
			
			0) to "Have a Nice Day"
				break;;
				
			*) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"
				continue ;;
		esac

 done

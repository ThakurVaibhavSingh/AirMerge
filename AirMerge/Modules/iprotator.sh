#!/bin/bash

iprotate () {

	sudo dhclient -r "$INTER" 2>/dev/null
	sudo dhclient "$INTER"
	info "IP renewed via DHCP"

}
	
mac_rotate () {

	sudo ip link set "$INTER" down
	sudo macchanger -r "$INTER"
	sudo ip link set "$INTER" up
	info "MAC randomized on $INTER"
	
} 

ip_mac () {
	
	sudo ip link set "$INTER" down
	sudo macchanger -r "$INTER"
	sudo ip link set "$INTER" up
	sudo dhclient -r "$INTER" 2>/dev/null
	sudo dhclient "$INTER"
	info "MAC and IP both rotated on $INTER"
	
}

restore_ip () {
	
	sudo dhclient -r "$INTER" 2>/dev/null
	sudo dhclient "$INTER"
	info "IP restored/renewed on $INTER"
	
}

restore_mac () {
	
	sudo ip link set "$INTER" down
	sudo macchanger -p "$INTER"
	sudo ip link set "$INTER" up
	info "MAC restored to permanent/original"
	
}




iprotator_menu () {
	
	while true; do 
		pp ""
		into "1)IP Rotate"
		into "2)MAC Rotate"
		into "3)Both IP/MAC"
		into "4)Restore IP"
		into "5)Restore MAC"
		into "0)Back"
	
		read -rp "$(pp "Choose >> ")" choice
		
		case $choice in 
		
			1)iprotate;;
			
			2)mac_rotate;;
			
			3)ip_mac;;
			
			4)restore_ip;;
			
			5)restore_mac;;
			
			0) break ;;
			
			*) err "Wrong Choice"
				read -rp "$(info "Press [ENTER] to Continue ")" 
				;;
		
		esac
	done
	
	
}

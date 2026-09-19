#!/bin/bash

wlan_checker () {
        if ! ip link show "$INTER" >/dev/null 2>&1; then
        err "$INTER not found — Enable it First"
        return 1
		fi
}


cleanup () {
	
	if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        info "$INTERFACE is not created"
        return 1
	fi
	
    ip link show "$INTERFACE" >/dev/null 2>&1 && {
    sudo ip link set "$INTERFACE" down 2>/dev/null
    sudo iw dev "$INTERFACE" del 2>/dev/null
    info "Virtual Interface Removed"
	log_event "WARNING" "Virtual Interface removed"
	}
}

handshake_check () {
	    
	if ls handshake* >/dev/null 2>&1; then
        rm -f handshake-* 2>/dev/null
    warn "Handshake file removed"
	log_event "WARNING" "Previous Handshake removed"
    else 
		warn "No Previous Handshake file"
    fi
	enter
}

mon_checker () {
        if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        err "$INTERFACE not found — Create Monitor Mode first"
		log_event "ERROR" "$INTERFACE not found"
        enter
        return 1
		fi
}

scan_check () {
	
	if [[ -f /tmp/scan_results.txt ]]; then
		 cat /tmp/scan_results.txt
	else 
		err "Scan file not created try again"
		return 1
	fi
}


create () {

	cleanup
	
    info "Creating virtual monitor interface $INTERFACE on $INTER..."
    if 
        sudo iw dev "$INTER" interface add "$INTERFACE" type monitor; then
        sudo ip link set "$INTERFACE" up
        info "$INTERFACE ready"
		log_event "INFO" "Virtual Interface created"
    else
        err "Could not create $INTERFACE — is $INTER available?"
        err "Check: iw dev"
        return 1
    fi

    enter
}

remove () {

    cleanup
    
    enter
}

select_interface () {
    mapfile -t WIFI_IFACES < <(
        iw dev | awk '
            /^\s*Interface/ { iface=$2 }
            /^\s*type/      { if (iface != "" && $2 == "managed") print iface; iface="" }
        '
    )

    if [[ ${#WIFI_IFACES[@]} -eq 0 ]]; then
        err "No managed-mode wimeness interfaces found."
        err "If you had a monitor interface running from a previous session, clean it up first."
        return 1
    fi

    info "Available wimeness interfaces:"
    local i=1
    for iface in "${WIFI_IFACES[@]}"; do
        printf "${PURPLE}%d) %s${NC}\n" "$i" "$iface"
        ((i++))
    done
while true; do
	if [[ ${#WIFI_IFACES[@]} = 1 ]]; then
		info "Only one selection is available"
		pick="1"
		INTER="${WIFI_IFACES[0]}"
		break
	else
		read -rp "$(printf "%sSelect interface (1-${#WIFI_IFACES[@]}): %s" "${PURPLE_DIM}" "${NC}")" pick
		
		if [[ $pick =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#WIFI_IFACES[@]} )); then
	        INTER="${WIFI_IFACES[$((pick-1))]}"
	        break
    	else
			read -rp "$(printf "You have selected the range%s %s %sout of range of%s %s%s. Press%s [ENTER] %sfor default selection to%s %s %s" \
        	"${PURPLE_DIM}" "$pick" "${NC}" "${PURPLE_DIM}" "${#WIFI_IFACES[@]}" "${NC}" "${PURPLE_DIM}" "${NC}" "${PURPLE_DIM}" "${WIFI_IFACES[0]}" "${NC}")"
        	warn "Invalid selection — defaulted to ${WIFI_IFACES[0]}"
        	INTER="${WIFI_IFACES[0]}"
        	break
    	fi
	fi
done
    if [[ "$INTER" =~ mon$ ]]; then 
        INTERFACE="$INTER"
    else
        INTERFACE="${INTER}mon"
    fi
    info "Managed: $INTER  |  Monitor: $INTERFACE"
    enter    
	log_event "INFO" "Interface selected"
}

wifi_deauth () {

 if [[ -z $ap ]]; then
         err "Run Target Scan First"
		 log_event "WARNING" "Target not scanned"
 else
    
    printf "%s%s Starting... %s\n" "${PURPLE}" "${BOLD}" "${NC}"
    
    mon_checker || return 1
    sudo iw dev "$INTERFACE" set channel "$ch"
	log_event "WARNING" "Virtual Interface has set on channel $ch"
    
    while true; do

        clear
        status_banner
        echo -e ""
		info "-----Make Choice-----"
		men "1) Aireplay Attack"
		men "2) MDK4 Attack (No Client Mac Needed)"
		buck "0) Back"
		warn "Press Ctrl+C here to stop"
    
		userask
		
		case $choice in 
		
			1) while true; do
                info "You can get Client MAC by Bettercap Scan"
                read -rp "$(printf "%sDeauth client  (Enter MAC of client. For all leave empty.): %s\t" "${BLUE_DIM}" "${NC}" )" cp
                if [[ -n $cp ]]; then
                    if [[ $cp =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                        break
                    else
                        err "Invalid MAC — expected format AA:BB:CC:DD:EE:FF"
						log_event "WARNING" "Invalid MAC entered"
                    fi
                else
                    break
                fi
                
                done
				while true; do
			    read -rp "$(printf "%sDeauth Packets Numbers(0 for infinite): %s\t" "${BLUE_DIM}" "${NC}")" pac
				if [[ -z $pac || ! $pac =~ ^[0-9]+$ ]]; then
					err "Number of packets is not selected or wrong selected"
				else 
					break
				fi
				done
				aireplay_deauth
				log_event "DEAUTH" "Aireplay deauth completed against $ap"
				;;
			
			2) mdk4_deauth
			   log_event "DEAUTH" "MDK4 deauth completed against $ap"
			   ;;
			
			0) break ;;
				
			*) error ;;	
		esac
    done
    
 fi
    enter
}

wifi_handshake () {

 if [[ -z $ap ]]; then
        err "Run Target Scan First"
		log_event "WARNING" "Target not scanned before handshake"
 else

    printf "%s Capturing... %s\n " "${PURPLE}" "${NC}"
    
 handshake_check    

    mon_checker || return 1
    while true; do
    info "You can get Client MAC by Bettercap Scan"
    read -rp "$(printf "%sDeauth client  (Enter MAC of client or For all leave empty): %s\t" "${MAGENTA}" "${NC}")" cp
    if [[ -z "$cp" ]]; then
        break
    elif [[ $cp =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        break
    else   
        err "Invalid MAC — expected format AA:BB:CC:DD:EE:FF"
    fi
    done
    
    sudo iw dev "$INTERFACE" set channel "$ch"
	log_event "WARNING" "Virtual Interface has set on channel $ch"

    while true; do
    clear
    status_banner
    echo -e ""
    ask "1) Aireplay (Deauth:- 20; Airodump:- 40)"
    ask "2) MDK4 (Best) (Deauth:- 25; Airodump:- 40)"
    ask "0) Back "
    warn "Please Dont Press Ctrl+C here"
    userask

	case $choice in
    
		1) if [[ -z $cp ]]; then
				scan_handshake
        		break
    		else
				scan_handshake1
        		break
    		fi ;;

		2)	mdk4_handshake
    		break
    		;;
		
		0) return 0 ;;

	*)error ;;
    esac
    done

	log_event "CAPTURE" "Handshake capture process completed for $ap"

    read -rp "$(printf "%sPress Enter to verify handshake...%s" "${MAGENTA}" "${NC}")"
    
    if 
        aircrack-ng handshake* 2>&1 | grep -q "1 handshake"; then
        info "Handshake captured successfully!"
		log_event "INFO" "Handshake successfully captured"
        info "For cracking process type (crack) or press [ENTER]"
        userask
        if [[ $choice = "crack" ]]; then
                echo -e ""
				file="handshake-01.cap"
				cap_run
				way_crack
		fi
    else
        err "No handshake found — try again"
        err "No Handshake Found Removing File 'handshake-01.cap'"
		log_event "ERROR" "Handshake capture failed for $ap"
        enter
		rm handshake*
	fi
   fi  
    enter
}

wifi_scan () {

    mon_checker || return 1
    rm -f scan-* 2>/dev/null
  while true; do 
    clear
    status_banner
    echo -e ""
    info "If you select [NO] in bettercap scan and fill correct [IP of client or gateway] you will get extra menu."
    men "1) Airodump-ng(Data will be autoselected)"
    men "2) Bettercap(Should be connected to the Network & Data may have to be fill manually)"
    buck "0) Back"
    userask

    case $choice in

    1)
		scan_airodump
    	info "Scan Finished"
		log_event "SCAN" "Airodump scan completed"

    if [[ ! -f scan-01.csv ]]; then 
        err "File scan-01.csv couldn't be generated, please retry"
        enter
        return 1
    fi

	python3 "$SCRIPT_DIR/modules/parse_scan.py" scan-01.csv > /tmp/scan_results.txt

	scan_check

    if [[ "$(wc -l < /tmp/scan_results.txt)" = 0 ]]; then 
        err "Proper scan not done or pressed ctrl+c in the small terminal"
        read -rp "$(printf "%s Press [ENTER] to continue%s" "${YELLOW_DIM}" "${NC}")"
        return 1
    fi

    while true; do
    read -rp "$(printf "%s%s Select target (1-$(wc -l < /tmp/scan_results.txt)) (For [Scan Again] chose 0): %s" "${PURPLE}" "${BOLD}" "${NC}")" PICK

    if [[ $PICK = 0 ]]; then
        wifi_scan
        return $?
    fi

	if [[ -n $PICK && $PICK =~ ^[0-9]+$ && $PICK -le $(wc -l < /tmp/scan_results.txt) ]]; then
		info "BSSID No Picked $PICK"
        break
	else
		err "Please choose between 1 to $(wc -l < /tmp/scan_results.txt) only"
		read -rp "$(printf "%sPress [Enter] key to continue...%s" "${GREEN_DIM}" "${NC}")"
	fi
	done
	IFS=',' read -r ap ch <<< "$(python3 "$SCRIPT_DIR/modules/pick_ap.py" /tmp/scan_results.txt "$PICK")"
	

    if [[ -n $ap && -n $ch ]]; then
        info "AP Selection Successful"
        info "Channel Selection Successful"
		log_event "TARGET" "AP selected: $ap on channel $ch"
    else
        err "AP Selection Failed"
        err "Channel Selection Failed"
		log_event "ERROR" "AP selection failed"
		return 1
    fi

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

    rm /tmp/scan_results.txt 2>/dev/null 
    enter
    break   ;;

    2) 	while true; do
        warn "Don't press Ctrl + C here"
        read -rp "$(printf "%s Scanning Time... %s\t" "${BLUE_DIM}" "${NC}")" sec	
        if [[ -z $sec || $sec -ge 60  || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
    		warn "Scan time must be a number greater than 0 and less then 60 sec"
		    enter
	    else 
            break
        fi
        done
	    
        sudo bettercap -iface "$INTER" -eval "wifi.recon on; net.recon on; net.probe on; sleep $sec; net.show; wifi.show; exit" 2>/dev/null | tee bettercap_scan.txt
        
        if [[ ! -f bettercap_scan.txt ]]; then 
            err "File bettercap_scan.txt couldn't be generated, please retry"
            enter
            return 1
        fi
        info "Scan Finished"
		log_event "SCAN" "Bettercap scan completed"

        python3 "$SCRIPT_DIR/modules/parse_scan.py" bettercap_scan.txt > /tmp/scan_results.txt
        scan_check

    if [[ "$(wc -l < /tmp/scan_results.txt)" = 0 ]]; then 
        err "Proper scan not done or pressed ctrl+c in the small terminal"
        enter
        return 1
    fi

    while true; do
    read -rp "$(printf "%s%s Select target (1-$(wc -l < /tmp/scan_results.txt)) (For [Scan Again] chose 0): %s" "${PURPLE}" "${BOLD}" "${NC}")" PICK

    if [[ $PICK = 0 ]]; then
        wifi_scan
        return $?
    fi

	if [[ -n $PICK && $PICK =~ ^[0-9]+$ && $PICK -le $(wc -l < /tmp/scan_results.txt) ]]; then
		info "BSSID No Picked $PICK"
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

        read -rp "$(printf "%sSelect the IP of MAC or Press [ENTER] (If not want nmap scans.)%s\t" "${BLUE_DIM}" "${NC}")" IP
        if [[ -n $IP ]];then
            if [[ ! $IP =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]]; then
				err "Invalid IP — expected format like 192.168.1.1 (no CIDR)"
    		fi
                    if [[ $IP = "$GATEWAY" ]]; then
                        info "IP Matched to the gateway"
                        men "47) NMAP-Network Scan (or Press [ENTER])"
                        userask
                        if [[ $choice = 47 ]]; then
                            network
                        fi
                    else    
                        info "IP didn't match the gateway"
                        men "102) NMAP-Other Scan (or Press [ENTER])"
                        userask
                        if [[ $choice = 102 ]]; then
                            other
                        fi
                    fi
        fi
		
        while true; do
            read -rp "$(printf "%sSelect the Channel of the AP%s\t" "${BLUE_DIM}" "${NC}")" ch
            if [[ $ch =~ ^[0-9]+$ ]] && (( ch >= 1 && ch <= 165 )); then
                break
            else
                err "Invalid channel — enter a number between 1 and 165"
            fi
        done
    fi

    if [[ -n $ap && -n $ch ]]; then
        info "AP Selection Successful"
        info "Channel Selection Successful"
		log_event "TARGET" "AP selected: $ap on channel $ch"
    else
        err "AP Selection Failed"
        err "Channel Selection Failed"
		log_event "ERROR" "AP selection failed"
		return 1
    fi
       rm /tmp/scan_results.txt 2>/dev/null 
        enter
    
        break;;
    
    *) error ;;
esac
done
}


wifi_attack_menu() {

    while true; do
    clear
    status_banner
    banner "══════════════════════════════════════════════════════"
    banner "${BOLD}               ATTACK             "
    banner "══════════════════════════════════════════════════════"
    men "4) Deauth Attack"
    men "5) Handshake capture"
	buck "00) Re-Scan"
    buck "0) Back"

    userask

    case $choice in
    4) wifi_deauth;;
    5) wifi_handshake;;
    00) wifi_main_menu;;
	0) break ;;
    *) error;;
    esac
    done
}
wifi_main_menu () {
    while true; do
    clear
    status_banner
    print_wifi
    echo -e ""
    banner "════════════════════════════════════════════════════"
    banner "${BOLD}              RECONNAISSANCE             "
    banner "══════════════════════════════════════════════════════"

    men "1) Switch to monitor mode"
    men "2) Swith to managed mode"
    men "3) Target scan"
    buck "0) Back"

    userask

    case $choice in 
    
        1) wlan_checker && create;;
        2) remove;;
        3) wifi_scan && wifi_attack_menu;;
        0) return 0;;
        *) error;;
    esac
    done
}

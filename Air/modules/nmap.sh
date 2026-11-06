#!/bin/bash

IP_selection () {
	
	read -rp "$(info "For Sub-Network(S) and For Specific IP(I) >>")" ipvalue
	ipvalue=$(echo "$ipvalue" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
	while true; do
		if [[ $ipvalue = s ]]; then
			read -rp "$(banner "Sub-Network $SUBNET")"
			IP="$SUBNET"
			log_event "NMAP" "Selected subnet: $SUBNET"
			enter
			break

			elif [[ $ipvalue = i ]]; then
				read -rp "$(banner "Select Target IP ")" IP
				if [[ $IP =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]]; then
					info "A valid IP"
					log_event "NMAP" "Selected target IP: $IP"
					enter
					break
				else
					err "Invalid IP — expected format like 192.168.1.1 (no CIDR)"
					log_event "ERROR" "Invalid IP format entered: $IP"
				fi
		else
			warn "Please do proper selection"
			enter
			IP_selection
		fi
	done
}

network () {
	
	while true; do 
	status_banner
		echo -e ""
	info "---Make a choice---"
		men "1) All Sub-Network Scan (Uses your connection SUBNET)"
		men "2) Select IP"
		men "3) Ports"
		men "4) Service"
		men "5) Security & Firewall"
		men "6) OS Version"
		men "7) View Last Scan"
		buck "0) Back"
		buck "00) Main Menu"

		
	read -rp ">>" choice
	
	case $choice in 
		
		1)	warn "Scanning $SUBNET"  
			log_event "NMAP" "Starting subnet scan: $SUBNET"
			
			HOSTFILE=$(mktemp /tmp/hostscan.XXXXXX)
			info "Live hosts temp file: $HOSTFILE"
			info "Scanning $SUBNET for live hosts..."
	
			sudo nmap -sn -PR --send-eth -n -T4 "$SUBNET" 2>/dev/null > "$HOSTFILE.raw" &
	
			NMAP_PID=$!
			spin='/-\|'
			i=0
		while kill -0 $NMAP_PID 2>/dev/null; do
			i=$(( (i+1) % 4 ))
			printf "\r$%sScanning... ${spin:$i:1}%s" "${ORANGE}" "${NC}"
			sleep 0.2
		done
		
		wait $NMAP_PID
		printf "\r"

		awk '
		/Nmap scan report for/ {ip=$NF; gsub(/[()]/,"",ip)}
		/MAC Address/ {mac=$3; $1=$2=$3=""; vendor=$0; gsub(/^ +/,"",vendor); print ip"|"mac"|"vendor}
		/Nmap scan report/ && !/MAC Address/ {} 
		' "$HOSTFILE.raw" > "$HOSTFILE"

		# handle hosts with no MAC line (e.g. the local machine itself, or non-ARP-reachable)
		grep "Nmap scan report for" "$HOSTFILE.raw" | awk '{print $NF}' | tr -d '()' | while read -r ip; do
		grep -q "^$ip|" "$HOSTFILE" || echo "$ip|--|This host (no ARP reply; Maybe be your local device)" >> "$HOSTFILE"
		done

		COUNT=$(wc -l < "$HOSTFILE")
		info "Found $COUNT live host(s):"
		awk -F'|' '{printf "%2d) %-15s %-18s %s\n", NR, $1, $2, $3}' "$HOSTFILE"
		log_event "NMAP" "Subnet scan completed: $COUNT hosts found in $SUBNET"
		;;
		
		2) IP_selection ;;
		
		3) while true; do
			if [[ -z $IP ]]; then
			warn "Selection not done"
			log_event "ERROR" "Port scan attempted without IP selection"
			enter
				return 1
			fi
			
			men "1) Open Ports"
			men "2) Specific Ports"
			men "3) All Ports (Take time)"
			buck "0) Back"
			
			userask
			
			case $choice in 
			
				1) log_event "NMAP" "Starting open ports scan on $IP"
					sudo nmap -sS -Pn -n --open -T3 \
					--max-retries 5 --min-rate 500 --max-rate 1500 \
					-p 21,22,23,53,80,88,135,139,143,443,445,515,548,554,631,993,995,1900,3689,3306,5000,5001,5353,5555,5900,7000,8008,8009,8080,8443,9000,49152-49157 \
					"$IP"
					log_event "NMAP" "Open ports scan completed on $IP"
					;;
				
				2) read -rp "$(ask "Choose the port(s){23,53,...}")" PORT
					log_event "NMAP" "Starting specific port scan ($PORT) on $IP"
					sudo nmap -sS -sV --version-intensity 9 -Pn -n \
					--max-retries 6 --min-rate 1000 \
					-p "$PORT" \
					--script=default,banner \
					"$IP"
					log_event "NMAP" "Specific port scan completed on $IP"
						;;
				3) log_event "NMAP" "Starting full port scan (-p-) on $IP"
					sudo nmap -sS -Pn -n --open -T4 \
					--min-rate 1000 --max-rate 3000 --max-retries 3 \
					-p- \
					"$IP"
					log_event "NMAP" "Full port scan completed on $IP"
					;;
					
				0) break ;;
				
				*) error
					return ;;
			esac
			done
			;;
		4) if [[ -z "$IP" ]]; then
			warn "Selection not done"
			log_event "ERROR" "Service scan attempted without IP selection"
			enter
				return 1
			fi
			
			log_event "NMAP" "Starting service/version scan on $IP"
			sudo nmap -sV --version-intensity 7 -Pn -n --open -p- -T4 --min-rate 3000 \
			--script=banner,http-headers,http-title,ssh-hostkey,ftp-anon,smtp-commands,http-enum,ssl-cert,dns-service-discovery,http-server-header \
			"$IP"
			log_event "NMAP" "Service/version scan completed on $IP"
			;;

		5) if [[ -z "$IP" ]]; then
			warn "Selection not done"
			log_event "ERROR" "Security scan attempted without IP selection"
			enter
				return 1
			fi
			
			log_event "NMAP" "Starting security/firewall scan on $IP"
			sudo nmap -sV --version-intensity 7 -Pn -n --open -T4 --min-rate 3000 \
			--script=vulners \
			"$IP"
			log_event "NMAP" "Security/firewall scan completed on $IP"
			;;

		6) if [[ -z "$IP" ]]; then
			warn "Selection not done"
			log_event "ERROR" "OS scan attempted without IP selection"
			enter
				return 1
			fi
		
			log_event "NMAP" "Starting OS detection scan on $IP"
			sudo nmap -O --osscan-guess --fuzzy -T4 --script=nbstat,smb-os-discovery,broadcast-dhcp-discover "$IP"
			log_event "NMAP" "OS detection scan completed on $IP"
			;;
    
		7) if [[ -f "$HOSTFILE" ]]; then
			column -t -s'|' "$HOSTFILE"
			log_event "NMAP" "Displayed last scan results from $HOSTFILE"
		else
				err "No scan run yet this session"
				log_event "ERROR" "Attempted to view last scan but no scan exists"
		fi ;;
		
		0) break;;
		
		00) GOTO_MAIN=1; break;;

		*);;
		
	esac
	done
}



other () {
	
	while true; do
    read -rp "$(printf "%sType the IP of the target%s" "${ORANGE_DIM}" "${NC}")" IP
        if [[ $IP =~ ^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]]; then
            info "A valid IP"
			log_event "NMAP" "External target set: $IP"
            break
        else
            err "Invalid IP — expected format like 192.168.1.1 (no CIDR)"
			log_event "ERROR" "Invalid external IP format entered: $IP"
        fi
    done

	while true; do 
	status_banner
		men ""
		info "Target: $IP"
		info "---Make a choice---"
		men "1) Host Reachability / Geo"
		men "2) Ports"
		men "3) Service/Version"
		men "4) Security & Firewall"
		men "5) Service Vuln"
		men "6) Active Users"
		buck "0) Back"
		buck "00) Main Menu"

	
	read -rp ">>" choice
	
	case $choice in 
		
		1) log_event "NMAP" "Starting host reachability/geo scan on $IP"
			sudo nmap -Pn -sn --reason "$IP" \
			--script=asn-query,whois-ip,ip-geolocation-ipinfodb
			log_event "NMAP" "Host reachability/geo scan completed on $IP"
			;;
		
		2) while true; do
			banner "1) Open Ports (fast, curated list)"
			banner "2) Specific Ports"
			banner "3) All Ports (takes time)"
			buck "0) Back"
	
			read -rp ">>" pchoice
			PORTFILE=$(mktemp)

			case $pchoice in
				1) log_event "NMAP" "Starting open ports scan (external) on $IP"
					sudo nmap -sS -Pn -n --open -T4 \
					--max-retries 2 --min-rate 2000 \
					-p 21,22,23,53,80,88,135,139,143,443,445,515,548,554,631,993,995,1900,3689,3306,5000,5001,5353,5555,5900,7000,8008,8009,8080,8443,9000,49152-49157 \
					"$IP" | tee "$PORTFILE"
					log_event "NMAP" "Open ports scan (external) completed on $IP"
					;;
		
				2) read -rp "$(ask "Choose the port(s){23,53,...}")" PORT
					log_event "NMAP" "Starting specific port scan (external) ($PORT) on $IP"
					sudo nmap -sS -sV --version-intensity 9 -Pn -n -T4 \
					--max-retries 2 --min-rate 1500 \
					-p "$PORT" --script=default,banner \
					"$IP" | tee "$PORTFILE"
					log_event "NMAP" "Specific port scan (external) completed on $IP"
					;;

				3) log_event "NMAP" "Starting full port scan (external) on $IP"
					sudo nmap -sS -Pn -n --open -T4 \
					--min-rate 3000 --max-retries 2 \
					-p- "$IP" | tee "$PORTFILE"
					log_event "NMAP" "Full port scan (external) completed on $IP"
					;;
		
				0) break ;;
				*) ;;
				esac
	
				# after the port capture in option 2:
				OPEN_PORTS=$(awk -F'/' '/open/ {print $1}' "$PORTFILE" | paste -sd, -)
				rm -f "$PORTFILE"
				[[ -n $OPEN_PORTS ]] && SCANNED=1

				if [[ -n $OPEN_PORTS ]]; then
					info "Captured open ports: $OPEN_PORTS"
					log_event "NMAP" "Open ports found on $IP: $OPEN_PORTS"
					[[ $pchoice != 3 ]] && warn "Note: partial scan (not -p-), some ports may be missed"
				else
					warn "No open ports found on $IP — target may be firewalled or fully filtered"
					log_event "NMAP" "No open ports found on $IP"
				fi
				enter
				done ;;
		
		3) if [[ -z $SCANNED ]]; then
			warn "No ports captured yet — run Ports scan (option 2) first"
			log_event "ERROR" "Service scan attempted without prior port scan on $IP"
	 		enter
			continue
   			elif [[ -z $OPEN_PORTS ]]; then
			warn "Last scan found no open ports on this target — nothing to check. Re-run Ports scan or try a different scan mode."
			log_event "ERROR" "Service scan attempted with no open ports on $IP"
			enter
			continue
   		fi

   		info "Attempting aggressive version detection..."
   		log_event "NMAP" "Starting aggressive version detection on $IP (ports: $OPEN_PORTS)"
   		RESULT=$(sudo nmap -sV --version-intensity 9 -Pn -n -T4 \
   		-p "$OPEN_PORTS" \
   		--min-rate 2000 --max-retries 2 \
   		--script=banner,http-headers,http-title,ssh-hostkey,ssl-cert \
   		"$IP")
   		echo "$RESULT"

   		if echo "$RESULT" | grep -qiE "tcpwrapped|unrecognized|filtered"; then
   			warn "Some services appear hidden — retrying with softer/stealthier probe"
   			log_event "NMAP" "Hidden services detected on $IP - running stealthier probe"
   			sudo nmap -sV --version-intensity 2 -Pn -n -T2 \
   			-p "$OPEN_PORTS" \
   			--max-retries 1 --scan-delay 300ms \
   			-f \
   			"$IP"
   			log_event "NMAP" "Stealth service scan completed on $IP"
   		fi
   		log_event "NMAP" "Service/version scan completed on $IP"
   		;;
		
		4) if [[ -z $SCANNED ]]; then
			warn "No ports captured yet — run Ports scan (option 2) first"
			log_event "ERROR" "Firewall scan attempted without prior port scan on $IP"
			enter
			continue
   			elif [[ -z $OPEN_PORTS ]]; then
			warn "Last scan found no open ports on this target — nothing to check. Re-run Ports scan or try a different scan mode."
			log_event "ERROR" "Firewall scan attempted with no open ports on $IP"
			enter
			continue
   		fi

   		log_event "NMAP" "Starting firewall/security scan on $IP (ports: $OPEN_PORTS)"
   		sudo nmap -sA -Pn -n -T4 \
   		-p "$OPEN_PORTS" \
   		--max-retries 2 --min-rate 2000 \
   		--script=firewalk,ipidseq \
   		"$IP"
   		log_event "NMAP" "Firewall scan completed on $IP"

   		read -rp "$(info "Vuln Scanning will be done (y/n) ")" vuln_confirm
   		if [[ $vuln_confirm = y ]]; then
   			log_event "NMAP" "Starting vulnerability scan on $IP"
   			sudo nmap -sS -sV --version-intensity 7 -Pn -n -T4 \
   			-p "$OPEN_PORTS" \
   			--min-rate 2000 --max-retries 2 \
   			--script=vulners,exploit,auth,http-shellshock,http-put,http-git,ftp-anon,smb-vuln-ms17-010,ssl-heartbleed \
   			"$IP"
   			log_event "NMAP" "Vulnerability scan completed on $IP"
   		fi
   		;;
		
		5) log_event "NMAP" "Starting service vulnerability scan on $IP"
			sudo nmap -sV --version-intensity 9 -Pn -n -T4 \
			--min-rate 2000 --max-retries 2 \
			--script=vulners \
			"$IP"
			log_event "NMAP" "Service vulnerability scan completed on $IP"
			;;
		
		6) log_event "NMAP" "Starting active users scan on $IP"
			sudo nmap -sV -Pn -n -T4 \
			-p 22,79,139,445,161 \
			--min-rate 1500 --max-retries 2 \
			--script=finger,smb-enum-users,smb-enum-sessions,snmp-info \
			"$IP"
			log_event "NMAP" "Active users scan completed on $IP"
			;;
		
		0) break;;

		00) GOTO_MAIN=1; break;;
		
		*);;
		
	esac
	enter
	done
}



nmap_menu () {		
	clear
	while true; do
		status_banner
		print_nmap
		
		men "1) Network IP"
		men "2) Other IP"
		buck "0) Main Menu"
	
	userask
	
	case $choice in 
	
		1) network
			[[ $GOTO_MAIN -eq 1 ]] && { GOTO_MAIN=0; break; } ;;
		2)	if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
				err "No internet connection — geolocation scripts need internet"
				log_event "ERROR" "External IP scan attempted without internet connection"
				enter
				continue
			fi
			other 
			[[ $GOTO_MAIN -eq 1 ]] && { GOTO_MAIN=0; break; };;
		0) break ;;
		
	
	esac	
	done
}

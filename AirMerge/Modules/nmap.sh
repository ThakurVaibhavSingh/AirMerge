#!/bin/bash

IP_selection () {
	
	read -rp "$(info "For Sub-Network(y) and For Specific IP(n) >>")" ip_value
	if [[ $ip_value = y ]]; then 
		read -rp "$(pp "Sub-Network $SUBNET")" SELECTED
		read -p "Press [ENTER]"
	elif [[ $ip_value = n ]]; then
		read -rp "$(pp "Select Target IP ")" SELECTED
		read -p "Press [ENTER]"
	else 
		return
	fi
	}

check_selection () {
	
prin "══════════════════════════════════════════════════════════════════════════════"
warn "Run Scan/Selection First (Selection Compulsury)"
prin "══════════════════════════════════════════════════════════════════════════════"
	
}

network () {
	
	while true; do 
		into ""
		show_nmap
	info "---Make a choice---"
		into "1) All Sub-Network Scan"
		into "2) Select IP"
		if [[ -z $SELECTED ]]; then
			check_selection
		fi
		into "3) Ports"
		into "4) Service"
		into "5) Security & Firewall"
		into "6) OS Version"
		into "7) View Last Scan"
		out "0) Back"
		out "00) Main Menu"
		
	read -p ">>" choice
	
	case $choice in 
		
		1)	pp "Scanning $SUBNET"
			read -p "Press [Enter] "
           	ip_check     
			
			HOSTFILE=$(mktemp /tmp/hostscan.XXXXXX)
			info "Live hosts temp file: $HOSTFILE"
			into "Scanning $SUBNET for live hosts..."
	
			sudo nmap -sn -PR --send-eth -n -T4 "$SUBNET" 2>/dev/null > "$HOSTFILE.raw" &
	
			NMAP_PID=$!
			spin='/-\|'
			i=0
		while kill -0 $NMAP_PID 2>/dev/null; do
			i=$(( (i+1) % 4 ))
			printf "\r${ORANGE}Scanning... ${spin:$i:1}${NC}"
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
		grep -q "^$ip|" "$HOSTFILE" || echo "$ip|--|This host (no ARP reply)" >> "$HOSTFILE"
		done

		COUNT=$(wc -l < "$HOSTFILE")
		info "Found $COUNT live host(s):"
		awk -F'|' '{printf "%2d) %-15s %-18s %s\n", NR, $1, $2, $3}' "$HOSTFILE"
		;;
		
		2) IP_selection ;;
		
		3) while true; do
			if [[ -z $SELECTED ]]; then
			warn "Selection not done"
			read -p "press [ENTER]"
				return 1
			fi
			
			pt "1) Open Ports"
			pt "2) Specific Ports"
			pt "3) All Ports (Take time)"
			out "0) Back"
			
			read -rp "$(prin"")" choice
			
			case $choice in 
			
				1) sudo nmap -sS -Pn -n --open -T3 \
					--max-retries 5 --min-rate 500 --max-rate 1500 \
					-p 21,22,23,53,80,88,135,139,143,443,445,515,548,554,631,993,995,1900,3689,3306,5000,5001,5353,5555,5900,7000,8008,8009,8080,8443,9000,49152-49157 \
					$SELECTED;;
				
				2) read -rp "$(pt "Choose the port(s){23,53,...}")" PORT
					sudo nmap -sS -sV --version-intensity 9 -Pn -n \
					--max-retries 6 --min-rate 1000 \
					-p "$PORT" \
					--script=default,banner \
					$SELECTED
						;;
				3) sudo nmap -sS -Pn -n --open -T4 \
					--min-rate 1000 --max-rate 3000 --max-retries 3 \
					-p- \
					$SELECTED ;;
					
				0) break ;;
				
				*) read -rp "$(err "Press [Enter] to return")"
					return ;;
			esac done
			;;
		4) if [[ -z $SELECTED ]]; then
			warn "Selection not done"
			read -p "press [ENTER]"
				return 1
			fi
			
			sudo nmap -sV --version-intensity 7 -Pn -n --open -p- -T4 --min-rate 3000 \
			--script=banner,http-headers,http-title,ssh-hostkey,ftp-anon,smtp-commands,http-enum,ssl-cert,dns-service-discovery,http-server-header \
			$SELECTED
			;;

		5) if [[ -z $SELECTED ]]; then
			warn "Selection not done"
			read -p "press [ENTER]"
				return 1
			fi
			
			sudo nmap -sV --version-intensity 7 -Pn -n --open -T4 --min-rate 3000 \
			--script=vulners \
			$SELECTED
			;;

		6) if [[ -z $SELECTED ]]; then
			warn "Selection not done"
			read -p "press [ENTER]"
				return 1
			fi
		
			sudo nmap -O --osscan-guess --fuzzy -T4 --script=nbstat,smb-os-discovery,broadcast-dhcp-discover $SELECTED;;
    
		7) if [[ -f "$HOSTFILE" ]]; then
			column -t -s'|' "$HOSTFILE"
		else
				err "No scan run yet this session"
		fi ;;
		
		0) break;;
		
		00) GOTO_MAIN=1; break;;
		#00 — set flag to 1 (true), then break out of network loop. Control returns to wherever network was called from (nmap_menu).
		
		*);;
		
	esac
	done
}

other () {
	
	while true; do 
	show_nmaps
	ip_check
		into "1) IP Scan"
		into "2) OS/Service/Version"
		into "3) Server Security,Firewall"
		into "4) Service Vunl"
		into "5) Active Users"
		out "0) Back"
		out "00) Main Menu"
	
	read -p ">>" choice
	
	case $choice in 
		
		1) sudo nmap -Pn -sn --reason $SUBNET \
			--script=asn-query,whois-ip,ip-geolocation-ipinfodb;;
		
		2) sudo nmap -sV --version-intensity 7 -O --osscan-guess -Pn -n \
			--script=banner,http-headers,http-title,ssh-hostkey,ssl-cert \
			$SUBNET;;
		
		3) sudo nmap -sA -Pn -n -T3 \
			--max-retries 4 --min-rate 500 \
			--script=firewalk,ipidseq \
			$SUBNET
			
			read -rp "$(info "Vunl Scanning will be done (y/n)")" choice
			
			if [[ $choice = y ]]; then
				sudo nmap -sS -sV --version-intensity 7 -Pn -n -T4 \
				-p 21,22,25,80,443,445,3306 \
				--min-rate 2000 --max-retries 3 \
				--script=vulners,exploit,auth,http-shellshock,http-put,http-git,ftp-anon,smb-vuln-ms17-010,ssl-heartbleed \
				$SUBNET
			else 
				continue
			fi;;
		
		4) sudo nmap -sV --version-intensity 9 -Pn -n -T4 \
			--min-rate 2000 --max-retries 3 \
			--script=vulners \
			$SUBNET ;;
		
		5) sudo nmap -sV -Pn -n -T4 \
			-p 22,79,139,445,161 \
			--min-rate 1500 --max-retries 3 \
			--script=finger,smb-enum-users,smb-enum-sessions,snmp-info \
			$SUBNET ;;
	# TODO: users-brute intentionally left out — active credential-guessing,
	# only add back once running against an owned/authorized lab target.
	# If added: throttle attempts (e.g. brute.delay) to avoid self-lockout,
	# and never use it to evade/hide from target-side logging or monitoring.
		
		0) break;;
		
		00) GOTO_MAIN=1; break;;
		
		*);;
		
	esac
	done
}

# ══════════════════════════════════════════════════════════════════════════════
# NMAP MENU Logic
# ══════════════════════════════════════════════════════════════════════════════

nmap_menu () {		
	while true; do
		clear
		nmap_banner
		
		into "1) Network IP"
		into "2) Other IP"
		out "0) Main Menu"
	
	read -rp "$(printf "${BOLD}${DIM}${GREEN}Choose any option ==>${NC}\t")" choice
	
	case $choice in 
	
			1) SUBNET=$(ip route | grep -v default | grep "$INTER" | awk '{print $1}')
				network
               [[ $GOTO_MAIN -eq 1 ]] && { GOTO_MAIN=0; break; } ;;
            
            2) if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
				err "No internet connection — geolocation scripts need internet"
				read -p "Press [Enter] to continue..."
				return 0
				fi

			GATEWAY=$(ip route | awk '/^default/ {print $3; exit}')
			
			read -rp "$(info "Enter Target IP >> ")" SUBNET
			[[ -z $SUBNET ]] && { warn "No IP entered"; read -rp "Press [Enter]"; continue; }
			[[ $SUBNET = $GATEWAY ]] && { warn "This is Gateway IP"; read -rp "Press [Enter]"; continue; }
			
			other
			
			[[ $GOTO_MAIN -eq 1 ]] && { GOTO_MAIN=0; break; } ;; #After nmap_main (which called network) returns — check the flag. If it's 1, reset it to 0 and break out of nmap_menu loop. Control returns to main menu.
            
		
		0) info "Bye Bye"
			break ;;
			
		*) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"
			continue ;;
	
	
	esac	
	done
}


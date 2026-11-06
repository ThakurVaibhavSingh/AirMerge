#!/bin/bash

generate () {
		
		info "Creating a permanent wordlist inside /home/$(logname)/filename.txt"
		read -rp "$(printf "%s Min Character %s\t" "${ORANGE}" "${NC}")" min
		read -rp "$(printf "%s Max Character %s\t" "${ORANGE}" "${NC}")" max
		read -rp "$(printf "%s Character %s\t" "${ORANGE}" "${NC}")" char
		read -rp "$(printf "%s File Name Without Extension >> %s\t" "${ORANGE}" "${NC}")" fill
		enter
		
		log_event "WORDLIST" "Generating permanent wordlist: $fill.txt (min:$min max:$max chars:$char)"
		crunch "$min" "$max" "$char" -o "/home/$(logname)/$fill.txt"
		
		if [[ $? -eq 0 ]]; then
			info "File Generated"
			log_event "WORDLIST" "Wordlist generated successfully: /home/$(logname)/$fill.txt"
		else
			err "Wordlist generation failed"
			log_event "ERROR" "Wordlist generation failed: $fill.txt"
		fi
		enter
	
}

deletes () {
	
	warn "This will remove all temp files AND stored cracked passwords (potfiles)."
	read -rp "$(printf "%sContinue? (y/n): %s" "${RED_DIM}" "${NC}")" confirm
	
	if [[ $confirm != y ]]; then
		info "Cancelled"
		enter
		return 0
	fi
	
	log_event "CLEANUP" "Starting cleanup of temp files and potfiles"
	
	rm -f "$HASHFILE"
	rm -f "$HCFILE"
	rm -f /tmp/crunch_tmp_*.txt
	rm -f "/home/$(logname)/.john/john.pot"
	rm -f "/root/.john/john.rec"
	rm -f "/home/$(logname)/.local/share/hashcat/hashcat.potfile"
	rm -f "/home/$(logname)/.hashcat/hashcat.potfile"
	rm -f ./*.restore
	rm -f "/home/$(logname)/handshake.hc22000"
	
	info "All temporary files and potfiles cleared"
	log_event "CLEANUP" "Cleanup completed successfully"
	enter
	return 0
}

extract_hash () {
	local tool=$1 file=$2
	"$tool" "$file" > "$HASHFILE"
	grep -oP '\$\w+\$.*?\$/\w+\$' "$HASHFILE" > "$HCFILE"
}

get_wordlist () {
	clear
	while true; do
	status_banner
	echo -e ""
	men "1) Use Existing Wordlist"
	men "2) Generate Temporary Wordlist (crunch)"
	
	read -rp ">> " wl_choice
	
	case $wl_choice in
		1)
			read -rp "$(printf "%sWordlist Name Whitout Extension (without .txt extension)%s\t" "${CYAN_DIM}" "${NC}")" wl_name
			if [ -z "$wl_name" ]; then
				err "Choose the Wordlist"
				log_event "ERROR" "Wordlist selection failed - empty name"
				return 1
			fi

			WORDLIST_DIR="/home/$(logname)/Air"
			WORDLIST_PATH="$WORDLIST_DIR/$wl_name.txt"

			if [[ ! -f "$WORDLIST_PATH" ]]; then
				err "Wordlist is empty or missing"
				log_event "ERROR" "Wordlist not found: $WORDLIST_PATH"
				warn "Available wordlists in $WORDLIST_DIR are:"
				available=$(ls "$WORDLIST_DIR"/*.txt 2>/dev/null)

				if [[ -z "$available" ]]; then
					warn "No .txt wordlists found in $WORDLIST_DIR"
				else
					printf "%s%s%s\n" "${GREEN}" "$available" "${NC}"
				fi

				return 1
			fi

			log_event "WORDLIST" "Using existing wordlist: $WORDLIST_PATH"
			return 0
	 		;;
		
		2)	read -rp "$(printf "%s Min Character %s\t" "${ORANGE}" "${NC}")" min
			read -rp "$(printf "%s Max Character %s\t" "${ORANGE}" "${NC}")" max
			read -rp "$(printf "%s Character %s\t" "${ORANGE}" "${NC}")" char
			
			WORDLIST_PATH="/tmp/crunch_tmp_$$.txt"
			
			info "Generating temporary wordlist..."
			log_event "WORDLIST" "Generating temporary wordlist (min:$min max:$max chars:$char)"
			crunch "$min" "$max" "$char" -o "$WORDLIST_PATH"
			if [[ ! -f "$WORDLIST_PATH" ]]; then
				err "Wordlist is empty or missing"
				log_event "ERROR" "Temporary wordlist generation failed"
				warn "Available wordlists in /home/$(logname)-- are -- /home/$(logname)/*.txt"
				return 1
			fi
			log_event "WORDLIST" "Temporary wordlist created: $WORDLIST_PATH"
			return 0 ;;

		*)error ;;
	esac
	done
}

file_selection () {
	
	while true; do

	echo -e ""
	info "File Should Be In Script Home Directory And Full With Extension"
	
	read -rp "Enter filename (or 'q' to quit): " file
	
	[[ "$file" == "q" ]] && { log_event "CANCEL" "File selection cancelled by user"; return 1; }
    if [[ -f $file ]]; then
        info "File Valid"
        log_event "FILE" "Selected file: $file"
        enter
        break
    else
        err "Wrong File/Wrong Name try again"
        warn "Make sure file exists in: $(pwd)"
		log_event "ERROR" "Invalid file selection: $file (not found in $(pwd))"
		enter
    fi
	
	done
}

zip_run () {
	
	info "Extracting HASH From $file"
	log_event "HASH_EXTRACT" "Extracting ZIP hash from $file"
	extract_hash zip2john "$file"
	
	    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        log_event "ERROR" "ZIP hash extraction failed for $file"
        return 1
    fi
    
    ext=13600
    log_event "HASH_EXTRACT" "ZIP hash extracted successfully (mode: 13600)"
    
    enter
    return 0
}
rar_run () {
		
		info "Extracting HASH From $file"
		log_event "HASH_EXTRACT" "Extracting RAR hash from $file"
		extract_hash rar2john "$file"
		
		# Guard against empty hash
		if [ ! -s "$HASHFILE" ]; then
			err "It's seem hash didn't loaded well try again"
			log_event "ERROR" "RAR hash extraction failed for $file"
			return 1
		fi
		
		ext=13000
		log_event "HASH_EXTRACT" "RAR hash extracted successfully (mode: 13000)"
		
		enter
		return 0
}
	
pdf_run () {
		
		info "Extracting HASH From $file"
		log_event "HASH_EXTRACT" "Extracting PDF hash from $file"
		extract_hash pdf2john "$file"
		
		    # Guard against empty hash
		if [ ! -s "$HASHFILE" ]; then
			err "It's seem hash didn't loaded well try again"
			log_event "ERROR" "PDF hash extraction failed for $file"
			return 1
		fi
		
		ext=10500
		log_event "HASH_EXTRACT" "PDF hash extracted successfully (mode: 10500)"
		
		enter
		return 0
}
sevenzip_run () {
		
		info "Extracting HASH From $file"
		log_event "HASH_EXTRACT" "Extracting 7Z hash from $file"
		extract_hash 7z2john "$file"
		
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        log_event "ERROR" "7Z hash extraction failed for $file"
        return 1
    fi
    
    ext=11600
    log_event "HASH_EXTRACT" "7Z hash extracted successfully (mode: 11600)"
    
    enter
    return 0
}
cap_run () {
		
		info "Extracting HASH From $file"
		log_event "HASH_EXTRACT" "Extracting CAP hash from $file"
		hcxpcapngtool -o "$HCFILE" "$file"
		
		if [ ! -s "$HCFILE" ]; then
			err "No handshake hash extracted from $file"
			log_event "ERROR" "CAP hash extraction failed for $file (no handshake found)"
			return 1
		fi
		
		ext=22000
		log_event "HASH_EXTRACT" "CAP hash extracted successfully (mode: 22000)"
		
		enter
		return 0
}
keepass_run () {
		
		info "Extracting HASH From $file"
		log_event "HASH_EXTRACT" "Extracting KeePass hash from $file"
		extract_hash keepass2john "$file"
	
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        log_event "ERROR" "KeePass hash extraction failed for $file"
        return 1
    fi
    
    ext=13400
    log_event "HASH_EXTRACT" "KeePass hash extracted successfully (mode: 13400)"
    
    enter
    return 0
}
office_run () {
		
		info "Extracting HASH From $file"
		log_event "HASH_EXTRACT" "Extracting Office hash from $file"
		extract_hash office2john "$file"
		
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        log_event "ERROR" "Office hash extraction failed for $file"
        return 1
    fi
    
    ext=9600
    log_event "HASH_EXTRACT" "Office hash extracted successfully (mode: 9600)"
    
    enter
    return 0
}

hashcat_run () {
	
	log_event "CRACK" "Starting Hashcat cracking (mode: $ext)"
	
	read -rp "Method of cracking (MASK--y / Wordlist--n) >> " way
	
	if [[ $way = y ]]; then
		mask_menu || return 1
		log_event "CRACK" "Hashcat using mask: $MASK"
		hashcat -d 1 -D 1 -a 3 -m "$ext" "$HCFILE" "$MASK" -w 3 -O --force
		if [[ $? -eq 0 ]]; then
			log_event "CRACK" "Hashcat mask attack completed successfully"
			hashcat -m "$ext" "$HCFILE" --show
		else
			log_event "ERROR" "Hashcat mask attack failed"
		fi
	
	else
	get_wordlist || return 1
	log_event "CRACK" "Hashcat using wordlist: $WORDLIST_PATH"
	read -rp "Press [Enter] to begin cracking"
	hashcat -d 1 -D 1 -a 0 -m "$ext" "$HCFILE" "$WORDLIST_PATH" -w 3 -O --force
	if [[ $? -eq 0 ]]; then
		log_event "CRACK" "Hashcat wordlist attack completed successfully"
		hashcat -m "$ext" "$HCFILE" --show
	else
		log_event "ERROR" "Hashcat wordlist attack failed"
	fi
	
	fi
	read -rp "Press [Enter] to Continue"
	
}

john_run () {
	
	log_event "CRACK" "Starting John cracking"
	
	rm -f /root/.john/john.pot
	if [[ ! $file =~ \.(zip|rar|pdf|7z|doc|docx|xls|xlsx|ppt|pptx|kdbx)$ ]]; then
		err "Invalid file — expected a different file format"
		log_event "ERROR" "John: Invalid file format for $file"
		read -rp "Press [Enter] to Continue"
		return 1
	fi
	
	read -rp "Method of cracking (MASK--y / Wordlist--n) >> " way
	
	if [[ $way = y ]]; then
	mask_menu || return 1
	log_event "CRACK" "John using mask: $MASK"
	john --mask="$MASK" "$HASHFILE"
	if [[ $? -eq 0 ]]; then
		log_event "CRACK" "John mask attack completed successfully"
	else
		log_event "ERROR" "John mask attack failed"
	fi
	
	else
	get_wordlist || return 1
	log_event "CRACK" "John using wordlist: $WORDLIST_PATH"
	john --wordlist="$WORDLIST_PATH" "$HASHFILE"
	if [[ $? -eq 0 ]]; then
		log_event "CRACK" "John wordlist attack completed successfully"
	else
		log_event "ERROR" "John wordlist attack failed"
	fi
	fi
	
	read -rp "Press [Enter] to Continue"
}

aircrack_run () {
	
		if [[ ! $file =~ \.(cap|pcap|pcapng)$ ]]; then
			err "Invalid extension — expected .cap/.pcap/.pcapng"
			log_event "ERROR" "Aircrack: Invalid file format for $file"
			read -rp "Press [Enter] to Continue"
			return 1
		fi
		get_wordlist || return 1
		
		while true; do
		if [[ -z $ap ]]; then
			read -rp "$(warn "Enter AP of Handshake 	")" ap
		else 
			info "The Saved AP is ${ap}"
			read -rp ">>"
		fi
		
		if [[ "$ap" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
			info "Value is correct"
			log_event "AIRCRACK" "Target AP: $ap"
			break
		else
			err "The AP format is wrong — expected XX:XX:XX:XX:XX:XX"
			log_event "ERROR" "Aircrack: Invalid AP format: $ap"
		fi
		done
		
	log_event "CRACK" "Aircrack-ng starting with wordlist: $WORDLIST_PATH"
	aircrack-ng -w "$WORDLIST_PATH" -b "$ap" "$file"
	if [[ $? -eq 0 ]]; then
		log_event "CRACK" "Aircrack-ng completed successfully"
	else
		log_event "ERROR" "Aircrack-ng failed"
	fi
	
	read -rp "Press [ENTER] to Continue"
}

number_value () {
        
        while true; do
            read -rp "How Many Digits/Letters	" digits
            if [[ ! $digits =~ ^[0-9]+$ ]]; then
                err "Please enter a positive whole number"
            elif [[ $digits -eq 0 ]]; then
                err "Value must be greater than 0"
            else
                eval "Value='$digits'"
                return 0
            fi
        done
}

mask_menu () {
	clear
	while true; do
	status_banner
	ask "1) Digits Only"
	ask "2) Lowercase Only"
	ask "3) Uppercase Only"
	ask "4) Merge (Upper+Lower+Digit)"
	buck "0) Back"
	
	read -rp ">> " mask_choice
	
	case $mask_choice in
		1)
			number_value
			MASK=""
			for ((i=0; i<digits; i++)); do
				MASK+="?d"
			done
			log_event "MASK" "Created mask: $MASK (digits only, $digits chars)"
			break
			;;
		2)
			number_value
			MASK=""
			for ((i=0; i<digits; i++)); do
				MASK+="?l"
			done
			log_event "MASK" "Created mask: $MASK (lowercase only, $digits chars)"
			break
			;;
		3)
			number_value
			MASK=""
			for ((i=0; i<digits; i++)); do
				MASK+="?u"
			done
			log_event "MASK" "Created mask: $MASK (uppercase only, $digits chars)"
			break
			;;
		4)
			while true; do
			read -rp "Enter order (uld/dul/ldu/dlu/udl/lud): " order
			order=$(echo "$order" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
			
			declare -A MASK_LABEL=( [u]="Uppercase" [l]="Lower Case" [d]="Digits" )
			declare -A MASK_TOKEN=( [u]="?u" [l]="?l" [d]="?d" )

			case $order in
    			uld|ldu|dul|dlu|udl|lud)
        		MASK=""
        		for (( i=0; i<${#order}; i++ )); do
            	key="${order:$i:1}"
            	read -rp "How Many ${MASK_LABEL[$key]} >> " count
            	validate_digit "$count" || return 1
            	for (( j=0; j<count; j++ )); do
	            MASK+="${MASK_TOKEN[$key]}"
            done
        done
        log_event "MASK" "Created mask: $MASK (custom order: $order)"
        return 0
        ;;
    *)error
        ;;
esac
			done
			;;
			
		0) return 1 ;;
		*)error
			;;
	esac
	
	done }

way_crack () {
	clear
	while true; do
	status_banner
	men "1) By Hashcat"
	men "2) By John"
	men "3) By Aircrack"
	buck "0) Back"
	
	userask
	
	case $choice in 
	
	1) tools="HASHCAT" ; hashcat_run;;
	2) tools="JOHN" ; john_run;;
	3) tools="AIRCRACK-NG" ; aircrack_run;;
	0) break;;
	*) error;;
	
	esac
	done
}

crack_menu () {
    
	clear
	while true; do
		status_banner
		print_hashcat
		echo -e ""
		men "1)ZIP"
		men "2)RAR"
		men "3)PDF"
		men "4)7Z"
		men "5)CAP"
		men "6)KEEPASS"
		men "7)OFFICE"
		men "8)Create a permanent list"
		buck "9)Clear Temp File"
		buck "0)Back"

        userask

        case $choice in 
            1)file_selection && zip_run && way_crack;;

            2)file_selection && rar_run && way_crack;;
            
			3)file_selection && pdf_run && way_crack;;
            
			4)file_selection && sevenzip_run && way_crack;;
            
			5)file_selection && cap_run && way_crack;;
            
			6)file_selection && keepass_run && way_crack;;
            
			7)file_selection && office_run && way_crack;;
            
			8)generate;;
            
			9)deletes;;
            
			0) break ;;
            
			*) error ;;

        esac 
    done
}

#!/bin/bash

generate () {
		
		info "Creating a permanent wordlist inside /home/$(logname)/filename.txt"
		read -rp "$(printf "%s Min Character %s\t" "${ORANGE}" "${NC}")" min
		read -rp "$(printf "%s Max Character %s\t" "${ORANGE}" "${NC}")" max
		read -rp "$(printf "%s Character %s\t" "${ORANGE}" "${NC}")" char
		read -rp "$(printf "%s File Name Without Extension >> %s\t" "${ORANGE}" "${NC}")" fill
		enter
		
		crunch "$min" "$max" "$char" -o "/home/$(logname)/$fill.txt"
		
		info "File Generated"
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
	relnext "1) Use Existing Wordlist"
	relnext "2) Generate Temporary Wordlist (crunch)"
	
	read -rp ">> " wl_choice
	
	case $wl_choice in
		1)
			read -rp "$(printf "%sWordlist Name Whitout Extension (without .txt extension)%s\t" "${CYAN_DIM}" "${NC}")" wl_name
			if [ -z "$wl_name" ]; then
				err "Choose the Wordlist"
				return 1
			fi

			WORDLIST_DIR="/home/$(logname)/Air"
			WORDLIST_PATH="$WORDLIST_DIR/$wl_name.txt"

			if [[ ! -f "$WORDLIST_PATH" ]]; then
				err "Wordlist is empty or missing"
				warn "Available wordlists in $WORDLIST_DIR are:"
				available=$(ls "$WORDLIST_DIR"/*.txt 2>/dev/null)

				if [[ -z "$available" ]]; then
					warn "No .txt wordlists found in $WORDLIST_DIR"
				else
					printf "%s%s%s\n" "${GREEN}" "$available" "${NC}"
				fi

				return 1
			fi

			return 0
	 		;;
		
		2)	read -rp "$(printf "%s Min Character %s\t" "${ORANGE}" "${NC}")" min
			read -rp "$(printf "%s Max Character %s\t" "${ORANGE}" "${NC}")" max
			read -rp "$(printf "%s Character %s\t" "${ORANGE}" "${NC}")" char
			
			WORDLIST_PATH="/tmp/crunch_tmp_$$.txt"
			
			info "Generating temporary wordlist..."
			crunch "$min" "$max" "$char" -o "$WORDLIST_PATH"
			if [[ ! -f "$WORDLIST_PATH" ]]; then
				err "Wordlist is empty or missing"
				warn "Available wordlists in /home/$(logname)-- are -- /home/$(logname)/*.txt"
				return 1
			fi
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
	
	[[ "$file" == "q" ]] && return 1
    if [[ -f $file ]]; then
        info "File Valid"
        enter
        break # if not applied ask again and again fo file name
    else
        err "Wrong File/Wrong Name try again"
        warn "Make sure file exists in: $(pwd)"
		enter
    fi
	
	done
}

zip_run () {
	
	info "Extracting HASH From $file"
	extract_hash zip2john "$file" #zip2john — reads the ZIP file's encryption header ;;;myfile.zip — your target file ;;; > hash.txt — saves the extracted hash to a file
	
	    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        return 1
    fi
    
    ext=13600
    
    enter
    return 0
}
rar_run () {
		
		info "Extracting HASH From $file"
		extract_hash rar2john "$file"
		
		# Guard against empty hash
		if [ ! -s "$HASHFILE" ]; then
			err "It's seem hash didn't loaded well try again"
			return 1
		fi
		
		ext=13000
		
		enter
		return 0
}
	
pdf_run () {
		
		info "Extracting HASH From $file"
		extract_hash pdf2john "$file"
		
		    # Guard against empty hash
		if [ ! -s "$HASHFILE" ]; then
			err "It's seem hash didn't loaded well try again"
			return 1
		fi
		
		ext=10500
		
		enter
		return 0
}
sevenzip_run () { #Note: function name 7zip_run starting with a digit is invalid in bash — function names can't start with a number.
		
		info "Extracting HASH From $file"
		extract_hash 7z2john "$file"
		
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        return 1
    fi
    
    ext=11600
    
    enter
    return 0
}
cap_run () {
		
		info "Extracting HASH From $file"
		hcxpcapngtool -o "$HCFILE" "$file"
		
		ext=22000
		
		enter
		return 0
}
keepass_run () {
		
		info "Extracting HASH From $file"
		extract_hash keepass2john "$file"
	
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        return 1
    fi
    
    ext=13400
    
    enter
    return 0
}
office_run () {
		
		info "Extracting HASH From $file"
		extract_hash office2john "$file"
		
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "It's seem hash didn't loaded well try again"
        return 1
    fi
    
    ext=9600
    
    enter
    return 0
}

hashcat_run () {
	
	read -rp "Method of cracking (MASK--y / Wordlist--n) >> " way
	
	if [[ $way = y ]]; then
		mask_menu || return 1
		hashcat -d 1 -D 1 -a 3 -m "$ext" "$HCFILE" "$MASK" -w 3 -O --force
		hashcat -m "$ext" "$HCFILE" --show
	
	else
	
	get_wordlist || return 1
	read -rp "Press [Enter] to begin cracking"
	hashcat -d 1 -D 1 -a 0 -m "$ext" "$HCFILE" "$WORDLIST_PATH" -w 3 -O --force
	hashcat -m "$ext" "$HCFILE" --show
	
	fi
	read -rp "Press [Enter] to Continue"
	
}

john_run () {
	
	rm -f /root/.john/john.pot
	if [[ ! $file =~ \.(zip|rar|pdf|7z|doc|docx|xls|xlsx|ppt|pptx|kdbx)$ ]]; then
		err "Invalid file — expected a different file format"	
		read -rp "Press [Enter] to Continue"
		return 1
	fi
	
	read -rp "Method of cracking (MASK--y / Wordlist--n) >> " way
	
	if [[ $way = y ]]; then
	mask_menu || return 1
	john --mask="$MASK" "$HASHFILE"
	
	else
	get_wordlist || return 1
	john --wordlist="$WORDLIST_PATH" "$HASHFILE"
	fi
	
	read -rp "Press [Enter] to Continue"
}

aircrack_run () {
	
		if [[ ! $file =~ \.(cap|pcap|pcapng)$ ]]; then
			err "Invalid extension — expected .cap/.pcap/.pcapng"
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
			break  # valid MAC — exit the retry loop, continue below
		else
			err "The AP format is wrong — expected XX:XX:XX:XX:XX:XX"
			
		fi
		done
		
	aircrack-ng -w "$WORDLIST_PATH" -b "$ap" "$file"	
	
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
			#read -rp "How Many Digits >> " digits
			#validate_digit "$digits" || return 1
			number_value
			MASK=""                              # start with an empty string, we'll build it up
			for ((i=0; i<digits; i++)); do       # loop runs exactly $digits times (i goes 0,1,2...digits-1)
				MASK+="?d"                        # each loop, append one "?d" placeholder to MASK
			done      
			break                            # after loop ends, MASK = "?d" repeated $digits times
			;;
		2)
			#read -rp "How Many Letters >> " letters
			#validate_digit "$letters" || return 1
			number_value
			MASK=""
			for ((i=0; i<digits; i++)); do
				MASK+="?l"
			done
			break
			;;
		3)
			#read -rp "How Many Letters >> " letters
			#validate_digit "$letters" || return 1
			number_value
			MASK=""
			for ((i=0; i<digits; i++)); do
				MASK+="?u"
			done
			break
			;;
		4)
			while true; do
			read -rp "Enter order (uld/dul/ldu/dlu/udl/lud): " order
			order=$(echo "$order" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
		
			#tr '[:upper:]' '[:lower:]' — normalizes case, so ULD, Uld, uLD all become uld. This forgives a common user mistake instead of rejecting it.
			#tr -d ' ' — strips spaces, so u l d or uld  (trailing space from a fat-fingered enter) still matches.
			
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
	
	# MASK should be fully built and ready here
	# to be used by hashcat_run (-a 3 "$MASK") and john_run (--mask="$MASK")
	
	done }


way_crack () {
	clear
	while true; do
	status_banner
	relnext "1) By Hashcat"
	relnext "2) By John"
	relnext "3) By Aircrack"
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
		relnext "1)ZIP"
		relnext "2)RAR"
		relnext "3)PDF"
		relnext "4)7Z"
		relnext "5)CAP"
		relnext "6)KEEPASS"
		relnext "7)OFFICE"
		relnext "8)Create a permanent list"
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

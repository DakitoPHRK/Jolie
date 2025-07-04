[ -e /tmp/.failsafe ] && export FAILSAFE=1

[ -n "$FAILSAFE" ] && cat /etc/banner.failsafe

grep -Fsq '/ overlay ro,' /proc/mounts && {
        echo 'Your JFFS2-partition seems full and overlayfs is mounted read-only.'
        echo 'Please try to remove files from /overlay/upper/... and reboot!'
}

export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
export HOME=$(grep -e "^${USER:-root}:" /etc/passwd | cut -d ":" -f 6)
export HOME=${HOME:-/root}
export PS1='\u@\h:\w\$ '
export ENV=/etc/shinit

case "$TERM" in
        xterm*|rxvt*)
                export PS1='\[\e]0;\u@\h: \w\a\]'$PS1
                ;;
esac

[ -x /bin/more ] || alias more='less'
[ -x /usr/bin/vim ] && alias vi='vim' || alias vim='vi'

alias l='ls -lF'
alias la='ls -a'
alias ll='ls -alF'
alias ls='ls --color=auto'

[ -z "$KSH_VERSION" -o \! -s /etc/mkshrc ] || . /etc/mkshrc

[ -x /usr/bin/arp -o -x /sbin/arp ] || arp() { cat /proc/net/arp; }
[ -x /usr/bin/ldd ] || ldd() { LD_TRACE_LOADED_OBJECTS=1 "$@"; }

[ -n "$FAILSAFE" ] || {
        for FILE in /etc/profile.d/*.sh; do
                [ -e "$FILE" ] && . "$FILE"
        done
        unset FILE
}

if grep -qs '^root::' /etc/shadow && [ -z "$FAILSAFE" ]; then
        cat << EOF
=== WARNING! =====================================
There is no root password defined on this device!
Use the "passwd" command to set up a new password
in order to prevent unauthorized SSH logins.
--------------------------------------------------
EOF
fi

if [ -z "$FAILSAFE" ] && [ -t 0 ]; then
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
BLUE='\033[34m'; MAGENTA='\033[35m'; CYAN='\033[36m'
BOLD_RED="${BOLD}${RED}"; BOLD_GREEN="${BOLD}${GREEN}"
BOLD_YELLOW="${BOLD}${YELLOW}"; BOLD_BLUE="${BOLD}${BLUE}"
BOLD_MAGENTA="${BOLD}${MAGENTA}"; BOLD_CYAN="${BOLD}${CYAN}"

print_banner() {
    clear
    echo -e "${BOLD_MAGENTA}==========================================${RESET}"
    echo -e "${BOLD_MAGENTA}              LISTA DE COMANDOS         ${RESET}"
    echo -e "${BOLD_MAGENTA}            TELEGRAM: @DAKITOLIES            ${RESET}"
    echo -e "${BOLD_MAGENTA}==========================================${RESET}"

    echo -e "${BOLD_BLUE} DEVICE MODEL     : ${BOLD_GREEN}$(cat /tmp/sysinfo/model 2>/dev/null || echo "UNKNOWN")"
    . /etc/os-release 2>/dev/null && echo -e "${BOLD_BLUE} OPENWRT VERSION  : ${BOLD_GREEN}$NAME $VERSION" || echo -e "${BOLD_BLUE} OPENWRT VERSION  : ${BOLD_GREEN}UNKNOWN"
    echo -e "${BOLD_BLUE} KERNEL VERSION   : ${BOLD_GREEN}$(uname -r)"
    echo -e "${BOLD_BLUE} ARCHITECTURE     : ${BOLD_GREEN}$(uname -m)"
    echo -e "${BOLD_BLUE} ROM AVAILABLE    : ${BOLD_GREEN}$(df -m /overlay 2>/dev/null | awk 'NR==2 {printf "%d MB", $4}' || echo "UNKNOWN")"
    echo -e "${BOLD_BLUE} RAM AVAILABLE    : ${BOLD_GREEN}$(free -m | awk '/Mem:/ {printf "%d MB", $7}' || echo "UNKNOWN")"

    cpu_temp="N/A"
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        cpu_temp=$(awk '{printf "%.0f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
    fi
    cpu_load=$(awk '{print $1}' /proc/loadavg)
    echo -e "${BOLD_BLUE} CPU TEMP/LOAD    : ${BOLD_GREEN}${cpu_temp}/${cpu_load}"

    echo -e "${BOLD_BLUE} DATE & TIME      : ${BOLD_GREEN}$(date +"%Y-%m-%d %H:%M")"
    echo -e "${BOLD_BLUE} UPTIME           : ${BOLD_GREEN}$(uptime | awk -F'[ ,:]+' '{print $3 " HRS, " $4 " MIN"}')"

    echo -e "${BOLD_MAGENTA}==========================================${RESET}"
    echo -e "${BOLD_YELLOW} Para cambiar el apn use los comandos:  ${RESET}"
    echo -e "${BOLD_YELLOW} movistar,entel,claro,wom  ${RESET}"
    echo -e "${BOLD_YELLOW} El comando '"internet"' iniciara el servicio de internet para Entel  ${RESET}"
    echo -e "${BOLD_YELLOW} El comando '"restart"' reiniciará el servicio de internet para Entel  ${RESET}"
    echo -e "${BOLD_MAGENTA}==========================================${RESET}"
}

        print_banner
fi

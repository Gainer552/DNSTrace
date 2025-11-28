#!/bin/bash

# ────────── Styling ────────── #
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)
BANNER="${CYAN}[DNS Config Drift Tracker]${RESET}"

# ────────── Baseline Capture ────────── #
capture_baseline() {
    timestamp=$(date +"%Y%m%d-%H%M%S")
    outfile="dns-baseline-$timestamp.txt"

    echo -e "${BANNER} Capturing system DNS configuration..."
    echo -e "Saving to: ${GREEN}${outfile}${RESET}"

    {
        echo "===== [TIMESTAMP] ====="
        date
        echo

        echo "===== [RESOLV.CONF] ====="
        grep -Ev '^\s*(#|$)' /etc/resolv.conf 2>/dev/null
        echo

        echo "===== [SYSTEMD-RESOLVED STATUS] ====="
        (systemd-resolve --status || resolvectl status) 2>/dev/null
        echo

        echo "===== [NMCLI DNS SETTINGS] ====="
        nmcli dev show 2>/dev/null | grep -iE 'dns|domain'
        echo

        echo "===== [NSSWITCH.CONF] ====="
        grep -v '^#' /etc/nsswitch.conf 2>/dev/null | grep 'hosts:'
        echo

        echo "===== [HOSTS FILE] ====="
        grep -Ev '^\s*(#|$)' /etc/hosts 2>/dev/null
        echo

        echo "===== [ACTIVE INTERFACES + DNS DOMAINS] ====="
        ip -br addr show
        echo

    } > "$outfile"

    chown "$(whoami):$(whoami)" "$outfile"
    sudo chattr +i "$outfile"

    echo -e "${GREEN}Baseline saved and locked (immutable).${RESET}  ${CYAN}✓${RESET}"
}

# ────────── Section Normalizer ────────── #
normalize_section() {
    echo "$1" | grep -Ev '^\s*(#|$)' | tr -s '[:space:]' ' ' | sed 's/ *$//' | sort
}

# ────────── Comparison Logic ────────── #
compare_baselines() {
    read -rp "Enter path to baseline file 1: " base1
    read -rp "Enter path to baseline file 2: " base2

    echo -e "${BANNER} Comparing configurations..."
    echo

    SECTIONS=(
        "RESOLV.CONF"
        "SYSTEMD-RESOLVED STATUS"
        "NMCLI DNS SETTINGS"
        "NSSWITCH.CONF"
        "HOSTS FILE"
    )

    for section in "${SECTIONS[@]}"; do
        echo -e "${BOLD}${YELLOW}🔹 Section: $section${RESET}"

        raw1=$(awk "/===== \[$section\] =====/{flag=1; next} /^===== \[/{flag=0} flag" "$base1")
        raw2=$(awk "/===== \[$section\] =====/{flag=1; next} /^===== \[/{flag=0} flag" "$base2")

        sec1=$(normalize_section "$raw1")
        sec2=$(normalize_section "$raw2")

        if diff <(echo "$sec1") <(echo "$sec2") > /dev/null; then
            echo -e "  ${GREEN}[No Change]${RESET}"
        else
            echo -e "  ${RED}- Baseline 1:${RESET}"
            echo "$sec1" | sed 's/^/    /'
            echo -e "  ${GREEN}+ Baseline 2:${RESET}"
            echo "$sec2" | sed 's/^/    /'
        fi
        echo
    done

    # 🔍 Special Handling: ACTIVE INTERFACES Section
    echo -e "${BOLD}${YELLOW}🔹 Section: ACTIVE INTERFACES + DNS DOMAINS${RESET}"

    iface1=$(awk '/===== \[ACTIVE INTERFACES \+ DNS DOMAINS\] =====/{flag=1; next} /^===== \[/{flag=0} flag' "$base1" | awk '{print $1}' | sort -u)
    iface2=$(awk '/===== \[ACTIVE INTERFACES \+ DNS DOMAINS\] =====/{flag=1; next} /^===== \[/{flag=0} flag' "$base2" | awk '{print $1}' | sort -u)

    if diff <(echo "$iface1") <(echo "$iface2") > /dev/null; then
        echo -e "  ${GREEN}[No Change]${RESET}"
    else
        echo -e "  ${RED}- Baseline 1 Interfaces:${RESET}"
        echo "$iface1" | sed 's/^/    /'
        echo -e "  ${GREEN}+ Baseline 2 Interfaces:${RESET}"
        echo "$iface2" | sed 's/^/    /'
    fi
    echo
}

# ────────── Menu ────────── #
echo -e "${BANNER} Choose an option:"
echo "1) Create DNS Configuration Baseline"
echo "2) Compare Two DNS Configuration Baselines"
read -rp "Enter your choice [1-2]: " choice

case "$choice" in
    1) capture_baseline ;;
    2) compare_baselines ;;
    *) echo -e "${RED}Invalid option.${RESET}" ;;
esac

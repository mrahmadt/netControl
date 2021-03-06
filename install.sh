#!/usr/bin/env bash
# Credit all goes to Pi Hole installation script https://github.com/pi-hole/pi-hole

# netControl: control your home internet access (Parental Control)
# (c) 2021 netControl, LLC (https://github.com/mrahmadt/netControl)
#
# Installs netControl
#
# This file is copyright under the latest version of the EUPL.
# Please see LICENSE file for your rights under this license.

#
# Install with this command (from your Linux machine):
#
# curl -sSL https://raw.githubusercontent.com/mrahmadt/netControl/master/install.sh | bash

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e

# shellcheck disable=SC1090

# Set these values so the installer can still run in color
COL_NC='\e[0m' # No Color
COL_LIGHT_GREEN='\e[1;32m'
COL_LIGHT_RED='\e[1;31m'
TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"
INFO="[i]"
# shellcheck disable=SC2034
DONE="${COL_LIGHT_GREEN} done!${COL_NC}"
OVER="\\r\\033[K"





######## VARIABLES #########
# For better maintainability, we store as much information that can change in variables
# This allows us to make a change in one place that can propagate to all instances of the variable
# These variables should all be GLOBAL variables, written in CAPS
# Local variables will be in lowercase and will exist only within functions
# It's still a work in progress, so you may see some variance in this guideline until it is complete

WAN_INTERFACE=${WAN_INTERFACE}
WAN_ADDRESS=${IPV4_ADDRESS}
LAN_INTERFACE=${LAN_INTERFACE}
LAN_ADDRESS=${LAN_ADDRESS}
DNS_SERVER_IP=127.0.0.1

TMP_DIR=/tmp/netControl
INSTALL_DIR=/etc/netControl
SCRIPT_DIR=${INSTALL_DIR}/scripts
ETC_DIR=${INSTALL_DIR}/etc
DATABASE_FILE=${ETC_DIR}/home.sqlite3
REMOVEOLDSETUP=0
netControlGitUrl="https://github.com/mrahmadt/netControl.git"
PiHoleInstalled=0
TRAFFICDBFILE="/var/log/netControl/traffic.db"

# Append common folders to the PATH to ensure that all basic commands are available.
# When using "su" an incomplete PATH could be passed: https://github.com/pi-hole/pi-hole/issues/3209
export PATH+=':/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

if [[ "${EUID}" -gt 0 ]]; then
    printf "  %b Root user check\\n" "${INFO}"
    printf "  %b %bScript called with non-root privileges%b\\n" "${INFO}" "${COL_LIGHT_RED}" "${COL_NC}"
    printf "      netControl requires elevated privileges to install and run\\n"
    printf "      Please check the installer for any concerns regarding this requirement\\n"
    printf "      Make sure to download this script from a trusted source\\n\\n"
    exit 1
else
    printf "  %b Root user check\\n" "${TICK}"
fi

is_command() {
    # Checks to see if the given command (passed as a string argument) exists on the system.
    # The function returns 0 (success) if the command exists, and 1 if it doesn't.
    local check_command="$1"

    command -v "${check_command}" >/dev/null 2>&1
}
ouiDatabase(){
    printf "  %b Downloading OUI file\\n" "${INFO}"
    wget http://standards-oui.ieee.org/oui/oui.txt -O ${INSTALL_DIR}/etc/oui.txt -o /dev/null
}

databaseSetup(){
    printf "  %b Creating new database\\n" "${INFO}"
    # create new database
    cat ${TMP_DIR}/templates/home.sqlite3.sql | sqlite3 ${ETC_DIR}/home.sqlite3
    # update database data
    sqlite3 ${DATABASE_FILE} "UPDATE config SET value='${WAN_INTERFACE}' WHERE name LIKE 'wan.interface'"
    sqlite3 ${DATABASE_FILE} "UPDATE config SET value='${WAN_ADDRESS}' WHERE name LIKE 'wan.ipaddr'"
    sqlite3 ${DATABASE_FILE} "UPDATE config SET value='${LAN_INTERFACE}' WHERE name LIKE 'lan.interface'"
    sqlite3 ${DATABASE_FILE} "UPDATE config SET value='${LAN_ADDRESS}' WHERE name LIKE 'lan.ipaddr'"
    sqlite3 ${DATABASE_FILE} "UPDATE config SET value='${DNS_SERVER_IP}' WHERE name LIKE 'lan.dnsserver1'"
    sqlite3 ${DATABASE_FILE} "UPDATE config SET value='${LAN_ADDRESS}' WHERE name LIKE 'system.portal.ip'"

    mkdir -p /var/log/netControl
    
    echo 'CREATE TABLE "traffics" ("macaddr"	TEXT NOT NULL,"bytes"	INTEGER NOT NULL DEFAULT 0,"dt"	TEXT NOT NULL);' | sqlite3 ${TRAFFICDBFILE}
    chmod 755 ${TRAFFICDBFILE}
}

# Installs a cron file
cronSetup() {
    # Install the cron job
    local str="Installing latest Cron script"
    printf "\\n  %b %s..." "${INFO}" "${str}"
    # Copy the cron file over from the local repo
    # File must not be world or group writeable and must be owned by root
    rm -rf /etc/cron.d/netcontrol
    install -D -m 644 -T -o root -g root ${TMP_DIR}/templates/netcontrol.cron /etc/cron.d/netcontrol
    printf "%b  %b %s\\n" "${OVER}" "${TICK}" "${str}"
}
bootSetup(){
    printf "\\n  %b Enabling service auto restart..." "${INFO}"
    includeConf=$(grep "netControl" /etc/rc.local 2>/dev/null | wc -l)
    if [ "${includeConf}" -eq "0" ]; then
        if [[ ! -f "/etc/rc.local" ]]; then
            echo '#!/bin/bash' >> /etc/rc.local
            echo '' >> /etc/rc.local
            chmod 755  /etc/rc.local
        fi
        echo "${INSTALL_DIR}/scripts/boot.sh &" >> /etc/rc.local
    fi
    
    ${INSTALL_DIR}/scripts/boot.sh >/dev/null 2>&1

}

lighttpdSetup(){
    local str="Installing lighttpd"
    printf "\\n  %b %s..." "${INFO}" "${str}"
    # and if the Web server conf directory does not exist,
    if [[ ! -d "/etc/lighttpd" ]]; then
        # make it and set the owners
        install -d -m 755 -o root -g root /etc/lighttpd
    # Otherwise, if the config file already exists
    elif [[ -f "/etc/lighttpd/lighttpd.conf" ]]; then
        if [ "${PiHoleInstalled}" -eq "0" ]; then
            # back up the original
            mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.orig
            # and copy in the config file Pi-hole needs
            install -D -m 644 -T ${TMP_DIR}/templates/${LIGHTTPD_CFG} /etc/lighttpd/lighttpd.conf
        fi
    fi
    rm -rf /etc/lighttpd/netcontrol.conf
    install -D -m 644 -T ${TMP_DIR}/templates/lighttpd.netcontrol.conf /etc/lighttpd/netcontrol.conf
    # Make sure the external.conf file exists, as lighttpd v1.4.50 crashes without it
    touch /etc/lighttpd/external.conf
    chmod 644 /etc/lighttpd/external.conf
    includeConf=$(grep "netcontrol" /etc/lighttpd/external.conf 2>/dev/null | wc -l)
    if [ "${includeConf}" -eq "0" ]; then
        echo 'include_shell "cat netcontrol.conf 2>/dev/null"' >> /etc/lighttpd/external.conf
    fi
    # Make the directories if they do not exist and set the owners
    mkdir -p /run/lighttpd
    chown ${LIGHTTPD_USER}:${LIGHTTPD_GROUP} /run/lighttpd
    mkdir -p /var/cache/lighttpd/compress
    chown ${LIGHTTPD_USER}:${LIGHTTPD_GROUP} /var/cache/lighttpd/compress
    mkdir -p /var/cache/lighttpd/uploads
    chown ${LIGHTTPD_USER}:${LIGHTTPD_GROUP} /var/cache/lighttpd/uploads

    ln -s ${INSTALL_DIR}/web/admin /var/www/html/netcontrol-admin
}

sudoerSetup(){
        # Install Sudoers file
    local str="Installing sudoer file"
    printf "\\n  %b %s..." "${INFO}" "${str}"
    # Make the .d directory if it doesn't exist,
    install -d -m 755 /etc/sudoers.d/
    # and copy in the sudoers file
    rm -rf /etc/sudoers.d/netcontrol
    install -m 0640 ${TMP_DIR}/templates/netcontrol.sudo /etc/sudoers.d/netcontrol

    
    # Add lighttpd user (OS dependent) to sudoers file
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: ${SCRIPT_DIR}/allow_device.sh" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: ${SCRIPT_DIR}/block_device.sh" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: ${SCRIPT_DIR}/boot.sh" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: ${SCRIPT_DIR}/disable.sh" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: ${SCRIPT_DIR}/enable.sh" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: ${SCRIPT_DIR}/limit_device.sh" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /usr/sbin/iptables" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /usr/sbin/tc" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /usr/sbin/ip" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /usr/sbin/arp" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /sbin/iptables" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /sbin/tc" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /sbin/ip" >> /etc/sudoers.d/netcontrol
    echo "${LIGHTTPD_USER} ALL=NOPASSWD: /sbin/arp" >> /etc/sudoers.d/netcontrol

    echo "Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:${SCRIPT_DIR}" >> /etc/sudoers.d/netcontrol
    # Set the strict permissions on the file
    chmod 0440 /etc/sudoers.d/netcontrol
    printf "%b  %b %s\\n" "${OVER}" "${TICK}" "${str}"
}

# Start/Restart service passed in as argument
restart_service() {
    # Local, named variables
    local str="Restarting ${1} service"
    printf "  %b %s..." "${INFO}" "${str}"
    # If systemctl exists,
    if is_command systemctl ; then
        # use that to restart the service
        systemctl restart "${1}" &> /dev/null
    else
        # Otherwise, fall back to the service command
        service "${1}" restart &> /dev/null
    fi
    printf "%b  %b %s...\\n" "${OVER}" "${TICK}" "${str}"
}

# Enable service so that it will start with next reboot
enable_service() {
    # Local, named variables
    local str="Enabling ${1} service to start on reboot"
    printf "  %b %s..." "${INFO}" "${str}"
    # If systemctl exists,
    if is_command systemctl ; then
        # use that to enable the service
        systemctl enable "${1}" &> /dev/null
    else
        #  Otherwise, use update-rc.d to accomplish this
        update-rc.d "${1}" defaults &> /dev/null
    fi
    printf "%b  %b %s...\\n" "${OVER}" "${TICK}" "${str}"
}

# Disable service so that it will not with next reboot
disable_service() {
    # Local, named variables
    local str="Disabling ${1} service"
    printf "  %b %s..." "${INFO}" "${str}"
    # If systemctl exists,
    if is_command systemctl ; then
        # use that to disable the service
        systemctl disable "${1}" &> /dev/null
    else
        # Otherwise, use update-rc.d to accomplish this
        update-rc.d "${1}" disable &> /dev/null
    fi
    printf "%b  %b %s...\\n" "${OVER}" "${TICK}" "${str}"
}


# A function that lets the user pick an interface to use with netControl
chooseInterface() {
    # Turn the available interfaces into an array so it can be used with a whiptail dialog
    local interfacesArray=()
    # Number of available interfaces
    local interfaceCount
    # Whiptail variable storage
    local chooseInterfaceCmd
    # Temporary Whiptail options storage
    local chooseInterfaceOptions
    # Loop sentinel variable
    local firstLoop=1
    # Find out how many interfaces are available to choose from
    interfaceCount=$(wc -l <<< "${availableInterfaces}")

    # If there is one interface,
    if [[ "${interfaceCount}" -eq 1 ]]; then
        # Set it as the interface to use since there is no other option
        LAN_INTERFACE="${availableInterfaces}"
    # Otherwise,
    else
        # While reading through the available interfaces
        while read -r line; do
            # Use a variable to set the option as OFF to begin with
            mode="OFF"
            # If it's the first loop,
            if [[ "${firstLoop}" -eq 1 ]]; then
                # set this as the interface to use (ON)
                firstLoop=0
                mode="ON"
            fi
            # Put all these interfaces into an array
            interfacesArray+=("${line}" "available" "${mode}")
        # Feed the available interfaces into this while loop
        done <<< "${availableInterfaces}"
        # The whiptail command that will be run, stored in a variable
        chooseInterfaceCmd=(whiptail --separate-output --radiolist "Choose LAN Interface (press space to toggle selection)" "${r}" "${c}" "${interfaceCount}")
        # Now run the command using the interfaces saved into the array
        chooseInterfaceOptions=$("${chooseInterfaceCmd[@]}" "${interfacesArray[@]}" 2>&1 >/dev/tty) || \
        # If the user chooses Cancel, exit
        { printf "  %bCancel was selected, exiting installer%b\\n" "${COL_LIGHT_RED}" "${COL_NC}"; exit 1; }
        # For each interface
        for desiredInterface in ${chooseInterfaceOptions}; do
            # Set the one the user selected as the interface to use
            LAN_INTERFACE=${desiredInterface}
            # and show this information to the user
            printf "  %b Using interface: %s\\n" "${INFO}" "${LAN_INTERFACE}"
        done
    fi
}

findWANInformation() {
    # Detects IPv4 address used for communication to WAN addresses.
    # Accepts no arguments, returns no values.
    # Named, local variables
    local route
    local IPv4bare
    # Find IP used to route to outside world by checking the the route to Google's public DNS server
    route=$(ip route get 8.8.8.8)
    # Get just the interface IPv4 address
    # shellcheck disable=SC2059,SC2086
    # disabled as we intentionally want to split on whitespace and have printf populate
    # the variable with just the first field.
    printf -v IPv4bare "$(printf ${route#*src })"
    # Get the default gateway IPv4 address (the way to reach the Internet)
    # shellcheck disable=SC2059,SC2086
    printf -v IPv4gw "$(printf ${route#*via })"
    if ! valid_ip "${IPv4bare}" ; then
        IPv4bare="127.0.0.1"
    fi
    # Append the CIDR notation to the IP address, if valid_ip fails this should return 127.0.0.1/8
    WAN_ADDRESS=${IPv4bare}
    WAN_INTERFACE=$(ip -oneline -family inet address show | grep "${IPv4bare}/" |  awk '{print $2}' | awk 'END {print}')
}


# Check an IP address to see if it is a valid one
valid_ip() {
    # Local, named variables
    local ip=${1}
    local stat=1
    # Regex matching one IPv4 component, i.e. an integer from 0 to 255.
    # See https://tools.ietf.org/html/rfc1340
    local ipv4elem="(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?|0)";
    # Regex matching an optional port (starting with '#') range of 1-65536
    local portelem="(#(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{0,3}|0))?";
    # Build a full IPv4 regex from the above subexpressions
    local regex="^${ipv4elem}\.${ipv4elem}\.${ipv4elem}\.${ipv4elem}${portelem}$"
    # Evaluate the regex, and return the result
    [[ $ip =~ ${regex} ]]
    stat=$?
    return "${stat}"
}

# Get available interfaces that are UP
get_available_interfaces() {
    # There may be more than one so it's all stored in a variable
    availableInterfaces=$(ip --oneline link show up | grep -v "lo" | awk '{print $2}' | cut -d':' -f1 | cut -d'@' -f1)
}

findLanInformation(){
    get_available_interfaces
    chooseInterface
    LAN_ADDRESS=$(ip -oneline -family inet address show | grep "${LAN_INTERFACE}" |  awk '{print $4}'| awk -F/ '{print $1}' | awk 'END {print}')
    if ! valid_ip "${LAN_ADDRESS}" ; then
        printf "%b  %b No valid LAN IPv4 address\\n" "${OVER}" "${CROSS}"
        exit;
    fi
}

isAlreadyInstalled(){
    if [ -d "${INSTALL_DIR}" ]; then
        printf "  %b netControl already installed...\\n" "${INFO}"
        read -p "Would you like to remove it? (Y/N) [N] " -n 3 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            printf "%b  %b Removing netControl\\n" "${OVER}"  "${TICK}"
            REMOVEOLDSETUP=1
        else
            exit
        fi
    else
        REMOVEOLDSETUP=1
        printf "%b  %b netControl check\\n" "${OVER}" "${TICK}"
    fi
}


# SELinux
checkSelinux() {
    local DEFAULT_SELINUX
    local CURRENT_SELINUX
    local SELINUX_ENFORCING=0
    # Check for SELinux configuration file and getenforce command
    if [[ -f /etc/selinux/config ]] && command -v getenforce &> /dev/null; then
        # Check the default SELinux mode
        DEFAULT_SELINUX=$(awk -F= '/^SELINUX=/ {print $2}' /etc/selinux/config)
        case "${DEFAULT_SELINUX,,}" in
            enforcing)
                printf "  %b %bDefault SELinux: %s%b\\n" "${CROSS}" "${COL_RED}" "${DEFAULT_SELINUX}" "${COL_NC}"
                SELINUX_ENFORCING=1
                ;;
            *)  # 'permissive' and 'disabled'
                printf "  %b %bDefault SELinux: %s%b\\n" "${TICK}" "${COL_GREEN}" "${DEFAULT_SELINUX}" "${COL_NC}"
                ;;
        esac
        # Check the current state of SELinux
        CURRENT_SELINUX=$(getenforce)
        case "${CURRENT_SELINUX,,}" in
            enforcing)
                printf "  %b %bCurrent SELinux: %s%b\\n" "${CROSS}" "${COL_RED}" "${CURRENT_SELINUX}" "${COL_NC}"
                SELINUX_ENFORCING=1
                ;;
            *)  # 'permissive' and 'disabled'
                printf "  %b %bCurrent SELinux: %s%b\\n" "${TICK}" "${COL_GREEN}" "${CURRENT_SELINUX}" "${COL_NC}"
                ;;
        esac
    else
        echo -e "  ${INFO} ${COL_GREEN}SELinux not detected${COL_NC}";
    fi
    # Exit the installer if any SELinux checks toggled the flag
    if [[ "${SELINUX_ENFORCING}" -eq 1 ]] && [[ -z "${NETCONTROL_SELINUX}" ]]; then
        printf "  netControl does not provide an SELinux policy as the required changes modify the security of your system.\\n"
        printf "  Please refer to https://wiki.centos.org/HowTos/SELinux if SELinux is required for your deployment.\\n"
        printf "      This check can be skipped by setting the environment variable %bNETCONTROL_SELINUX%b to %btrue%b\\n" "${COL_LIGHT_RED}" "${COL_NC}" "${COL_LIGHT_RED}" "${COL_NC}"
        printf "      e.g: export NETCONTROL_SELINUX=true\\n"
        printf "      By setting this variable to true you acknowledge there may be issues with Pi-hole during or after the install\\n"
        printf "\\n  %bSELinux Enforcing detected, exiting installer%b\\n" "${COL_LIGHT_RED}" "${COL_NC}";
        exit 1;
    elif [[ "${SELINUX_ENFORCING}" -eq 1 ]] && [[ -n "${NETCONTROL_SELINUX}" ]]; then
        printf "  %b %bSELinux Enforcing detected%b. NETCONTROL_SELINUX env variable set - installer will continue\\n" "${INFO}" "${COL_LIGHT_RED}" "${COL_NC}"
    fi
}

# A function for displaying the dialogs the user sees when first running the installer
welcomeDialogs() {
    # Display the welcome dialog using an appropriately sized window via the calculation conducted earlier in the script
    whiptail --msgbox --backtitle "Welcome" --title "netControl automated installer" "\\n\\nThis installer will transform your device into a network controller/router!
    
    netControl is a gateway so it needs few changes in your network
    
    - DHCP service to point all your network clients to this server as internet gateway (We recommend you to use Pi Hole https://pi-hole.net/ and make sure to enable DHCP service)
    - a STATIC IP ADDRESS to function properly.
    
    " "${r}" "${c}"

}

getDNSService(){
    DNS_SERVER_IP=127.0.0.1
    DNS_SERVER_IP=$(whiptail --backtitle "DNS Server" --title "DNS Server" --inputbox "Enter your desired DNS Server address" "${r}" "${c}" "${DNS_SERVER_IP}" 3>&1 1>&2 2>&3) || \
    # Canceling IPv4 settings window
    { dnsSettingsCorrect=False; echo -e "  ${COL_LIGHT_RED}Cancel was selected, exiting installer${COL_NC}"; exit 1; }
    if ! valid_ip "${DNS_SERVER_IP}" ; then
        printf "%b  %b No valid DNS Server address\\n" "${OVER}" "${CROSS}"
        exit;
    fi
    str="DNS Service"
    cmdResult="$(dig +short google.com @${DNS_SERVER_IP} 2>&1; echo $?)"
    # Gets the return code of the previous command (last line)
    digReturnCode="${cmdResult##*$'\n'}"

    if [ "${digReturnCode}" == "0" ]; then
        printf "  %b %s\\n" "${TICK}" "${str}"
    else
        printf "%b  %b %s not found\\n" "${OVER}" "${CROSS}" "${str}"
        exit
    fi
}



validateBasicServices(){
    local str="DHCP Service"
    SERVICE_PROCESS=$(ps -ef | grep dhcpcd | wc -l)
    if [[ "${SERVICE_PROCESS}" -eq 2 ]]; then
        printf "  %b %s\\n" "${TICK}" "${str}"
    else
        printf "%b  %b %s not found\\n" "${OVER}" "${CROSS}" "${str}"
    fi

    str="Pi Hole Service"
    SERVICE_PROCESS=$(pihole -v | wc -l)
    if [[ "${SERVICE_PROCESS}" -eq 3 ]]; then
        printf "  %b %s\\n" "${TICK}" "${str}"
        PiHoleInstalled=1
    else
        printf "%b  %b %s not found\\n" "${OVER}" "${CROSS}" "${str}"
        PiHoleInstalled=0
    fi

}


update_package_cache() {
    # Running apt-get update/upgrade with minimal output can cause some issues with
    # requiring user input (e.g password for phpmyadmin see #218)

    # Update package cache on apt based OSes. Do this every time since
    # it's quick and packages can be updated at any time.

    # Local, named variables
    local str="Update local cache of available packages"
    printf "  %b %s..." "${INFO}" "${str}"
    # Create a command from the package cache variable
    if eval "${UPDATE_PKG_CACHE}" &> /dev/null; then
        printf "%b  %b %s\\n" "${OVER}" "${TICK}" "${str}"
    else
        # Otherwise, show an error and exit
        printf "%b  %b %s\\n" "${OVER}" "${CROSS}" "${str}"
        printf "  %bError: Unable to update package cache. Please try \"%s\"%b" "${COL_LIGHT_RED}" "${UPDATE_PKG_CACHE}" "${COL_NC}"
        return 1
    fi
}

# Let user know if they have outdated packages on their system and
# advise them to run a package update at soonest possible.
notify_package_updates_available() {
    # Local, named variables
    local str="Checking ${PKG_MANAGER} for upgraded packages"
    printf "\\n  %b %s..." "${INFO}" "${str}"
    # Store the list of packages in a variable
    updatesToInstall=$(eval "${PKG_COUNT}")

    if [[ -d "/lib/modules/$(uname -r)" ]]; then
        if [[ "${updatesToInstall}" -eq 0 ]]; then
            printf "%b  %b %s... up to date!\\n\\n" "${OVER}" "${TICK}" "${str}"
        else
            printf "%b  %b %s... %s updates available\\n" "${OVER}" "${TICK}" "${str}" "${updatesToInstall}"
            printf "  %b %bIt is recommended to update your OS after installing the netControl!%b\\n\\n" "${INFO}" "${COL_LIGHT_GREEN}" "${COL_NC}"
        fi
    else
        printf "%b  %b %s\\n" "${OVER}" "${CROSS}" "${str}"
        printf "      Kernel update detected. If the install fails, please reboot and try again\\n"
    fi
}
# This counter is outside of install_dependent_packages so that it can count the number of times the function is called.
counter=0

install_dependent_packages() {
    # Local, named variables should be used here, especially for an iterator
    # Add one to the counter
    counter=$((counter+1))
    if [[ "${counter}" == 1 ]]; then
        # On the first loop, print a special message
        printf "  %b Installer Dependency checks...\\n" "${INFO}"
    else
        # On all subsequent loops, print a generic message.
        printf "  %b Main Dependency checks...\\n" "${INFO}"
    fi

    # Install packages passed in via argument array
    # No spinner - conflicts with set -e
    declare -a installArray

    # Debian based package install - debconf will download the entire package list
    # so we just create an array of packages not currently installed to cut down on the
    # amount of download traffic.
    # NOTE: We may be able to use this installArray in the future to create a list of package that were
    # installed by us, and remove only the installed packages, and not the entire list.
    if is_command apt-get ; then
        # For each package, check if it's already installed (and if so, don't add it to the installArray)
        for i in "$@"; do
            printf "  %b Checking for %s..." "${INFO}" "${i}"
            if dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep "ok installed" &> /dev/null; then
                printf "%b  %b Checking for %s\\n" "${OVER}" "${TICK}" "${i}"
            else
                printf "%b  %b Checking for %s (will be installed)\\n" "${OVER}" "${INFO}" "${i}"
                installArray+=("${i}")
            fi
        done
        # If there's anything to install, install everything in the list.
        if [[ "${#installArray[@]}" -gt 0 ]]; then
            test_dpkg_lock
            printf "  %b Processing %s install(s) for: %s, please wait...\\n" "${INFO}" "${PKG_MANAGER}" "${installArray[*]}"
            printf '%*s\n' "$columns" '' | tr " " -;
            "${PKG_INSTALL[@]}" "${installArray[@]}"
            printf '%*s\n' "$columns" '' | tr " " -;
            return
        fi
        printf "\\n"
        return 0
    fi

    # Install Fedora/CentOS packages
    for i in "$@"; do
    # For each package, check if it's already installed (and if so, don't add it to the installArray)
        printf "  %b Checking for %s..." "${INFO}" "${i}"
        if "${PKG_MANAGER}" -q list installed "${i}" &> /dev/null; then
            printf "%b  %b Checking for %s\\n" "${OVER}" "${TICK}" "${i}"
        else
            printf "%b  %b Checking for %s (will be installed)\\n" "${OVER}" "${INFO}" "${i}"
            installArray+=("${i}")
        fi
    done
    # If there's anything to install, install everything in the list.
    if [[ "${#installArray[@]}" -gt 0 ]]; then
        printf "  %b Processing %s install(s) for: %s, please wait...\\n" "${INFO}" "${PKG_MANAGER}" "${installArray[*]}"
        printf '%*s\n' "$columns" '' | tr " " -;
        "${PKG_INSTALL[@]}" "${installArray[@]}"
        printf '%*s\n' "$columns" '' | tr " " -;
        return
    fi
    printf "\\n"
    return 0
}

# Compatibility
distro_check() {
# If apt-get is installed, then we know it's part of the Debian family
if is_command apt-get ; then
    # Set some global variables here
    # We don't set them earlier since the family might be Red Hat, so these values would be different
    PKG_MANAGER="apt-get"
    # A variable to store the command used to update the package cache
    UPDATE_PKG_CACHE="${PKG_MANAGER} update"
    # The command we will use to actually install packages
    PKG_INSTALL=("${PKG_MANAGER}" -qq --no-install-recommends install)
    # grep -c will return 1 if there are no matches. This is an acceptable condition, so we OR TRUE to prevent set -e exiting the script.
    PKG_COUNT="${PKG_MANAGER} -s -o Debug::NoLocking=true upgrade | grep -c ^Inst || true"
    # Some distros vary slightly so these fixes for dependencies may apply
    # on Ubuntu 18.04.1 LTS we need to add the universe repository to gain access to dhcpcd5
    APT_SOURCES="/etc/apt/sources.list"
    if awk 'BEGIN{a=1;b=0}/bionic main/{a=0}/bionic.*universe/{b=1}END{exit a + b}' ${APT_SOURCES}; then
        if ! whiptail --defaultno --title "Dependencies Require Update to Allowed Repositories" --yesno "Would you like to enable 'universe' repository?\\n\\nThis repository is required by the following packages:\\n\\n- dhcpcd5" "${r}" "${c}"; then
            printf "  %b Aborting installation: Dependencies could not be installed.\\n" "${CROSS}"
            exit 1
        else
            printf "  %b Enabling universe package repository for Ubuntu Bionic\\n" "${INFO}"
            cp -p ${APT_SOURCES} ${APT_SOURCES}.backup # Backup current repo list
            printf "  %b Backed up current configuration to %s\\n" "${TICK}" "${APT_SOURCES}.backup"
            add-apt-repository universe
            printf "  %b Enabled %s\\n" "${TICK}" "'universe' repository"
        fi
    fi
    # Update package cache. This is required already here to assure apt-cache calls have package lists available.
    update_package_cache || exit 1
    # Debian 7 doesn't have iproute2 so check if it's available first
    if apt-cache show iproute2 > /dev/null 2>&1; then
        iproute_pkg="iproute2"
    # Otherwise, check if iproute is available
    elif apt-cache show iproute > /dev/null 2>&1; then
        iproute_pkg="iproute"
    # Else print error and exit
    else
        printf "  %b Aborting installation: iproute2 and iproute packages were not found in APT repository.\\n" "${CROSS}"
        exit 1
    fi
    # Check for and determine version number (major and minor) of current php install
    if is_command php ; then
        printf "  %b Existing PHP installation detected : PHP version %s\\n" "${INFO}" "$(php <<< "<?php echo PHP_VERSION ?>")"
        printf -v phpInsMajor "%d" "$(php <<< "<?php echo PHP_MAJOR_VERSION ?>")"
        printf -v phpInsMinor "%d" "$(php <<< "<?php echo PHP_MINOR_VERSION ?>")"
        # Is installed php version 7.0 or greater
        if [ "${phpInsMajor}" -ge 7 ]; then
            phpInsNewer=true
        fi
    fi
    # Several other packages depend on the version of PHP. If PHP is not installed, or an insufficient version,
    # those packages should fall back to the default (latest?)
    if [[ "$phpInsNewer" != true ]]; then
        # Prefer the php metapackage if it's there
        if apt-cache show php > /dev/null 2>&1; then
            phpVer="php"
        # Else fall back on the php5 package if it's there
        elif apt-cache show php5 > /dev/null 2>&1; then
            phpVer="php5"
        # Else print error and exit
        else
            printf "  %b Aborting installation: No PHP packages were found in APT repository.\\n" "${CROSS}"
            exit 1
        fi
    else
        # Else, PHP is already installed at a version beyond v7.0, so the additional packages
        # should match version with the current PHP version.
        phpVer="php$phpInsMajor.$phpInsMinor"
    fi

    # We also need the correct version for `php-json` (built-in php 8)
    if [[ "$phpInsMajor" != "8" ]]; then
        phpJson="${phpVer}-json"
    else
        phpJson=""
    fi
    
    if apt-cache show "${phpVer}-json" > /dev/null 2>&1; then
        phpSqlite="sqlite3"
    elif apt-cache show "${phpVer}-sqlite" > /dev/null 2>&1; then
        phpSqlite="sqlite"
    else
        printf "  %b Aborting installation: No SQLite PHP module was found in APT repository.\\n" "${CROSS}"
        exit 1
    fi

    # Packages required to run this install script (stored as an array)
    INSTALLER_DEPS=(git "${iproute_pkg}" whiptail sqlite3 dnsutils)
    # Packages required to run netControl (stored as an array)
    APP_DEPS=(netcat psmisc sqlite3 cron iputils-ping lsof curl unzip lighttpd php-common php-sqlite3 iptables iproute2 conntrack dnsutils sudo wget idn2 libcap2-bin dns-root-data libcap2 "${phpVer}-common" "${phpVer}-cgi" "${phpVer}-${phpSqlite}" "${phpVer}-xml" "${phpJson}" "${phpVer}-intl")

    # The Web server user,
    LIGHTTPD_USER="www-data"
    # group,
    LIGHTTPD_GROUP="www-data"
    # and config file
    LIGHTTPD_CFG="lighttpd.conf.debian"

    # This function waits for dpkg to unlock, which signals that the previous apt-get command has finished.
    test_dpkg_lock() {
        i=0
        # fuser is a program to show which processes use the named files, sockets, or filesystems
        # So while the lock is held,
        while fuser /var/lib/dpkg/lock >/dev/null 2>&1
        do
            # we wait half a second,
            sleep 0.5
            # increase the iterator,
            ((i=i+1))
        done
        # and then report success once dpkg is unlocked.
        return 0
    }
# If apt-get is not found, check for rpm to see if it's a Red Hat family OS
elif is_command rpm ; then
    # Then check if dnf or yum is the package manager
    if is_command dnf ; then
        PKG_MANAGER="dnf"
    else
        PKG_MANAGER="yum"
    fi

    # These variable names match the ones in the Debian family. See above for an explanation of what they are for.
    PKG_INSTALL=("${PKG_MANAGER}" install -y)
    PKG_COUNT="${PKG_MANAGER} check-update | egrep '(.i686|.x86|.noarch|.arm|.src)' | wc -l"
    INSTALLER_DEPS=(git iproute newt procps-ng which chkconfig bind-utils sqlite)
    APP_DEPS=(cronie curl findutils nmap-ncat sudo unzip libidn2 psmisc sqlite libcap lsof lighttpd lighttpd-fastcgi php-common php-cli php-pdo php-xml php-json php-intl)
    LIGHTTPD_USER="lighttpd"
    LIGHTTPD_GROUP="lighttpd"
    LIGHTTPD_CFG="lighttpd.conf.fedora"
    # If the host OS is Fedora,
    if grep -qiE 'fedora|fedberry' /etc/redhat-release; then
        # all required packages should be available by default with the latest fedora release
        : # continue
    # or if host OS is CentOS,
    elif grep -qiE 'centos|scientific' /etc/redhat-release; then
        # netControl currently supports CentOS 7+ with PHP7+
        SUPPORTED_CENTOS_VERSION=7
        SUPPORTED_CENTOS_PHP_VERSION=7
        # Check current CentOS major release version
        CURRENT_CENTOS_VERSION=$(grep -oP '(?<= )[0-9]+(?=\.?)' /etc/redhat-release)
        # Check if CentOS version is supported
        if [[ $CURRENT_CENTOS_VERSION -lt $SUPPORTED_CENTOS_VERSION ]]; then
            printf "  %b CentOS %s is not supported.\\n" "${CROSS}" "${CURRENT_CENTOS_VERSION}"
            printf "      Please update to CentOS release %s or later.\\n" "${SUPPORTED_CENTOS_VERSION}"
            # exit the installer
            exit
        fi
        # php-json is not required on CentOS 7 as it is already compiled into php
        # verifiy via `php -m | grep json`
        if [[ $CURRENT_CENTOS_VERSION -eq 7 ]]; then
            # create a temporary array as arrays are not designed for use as mutable data structures
            CENTOS7_APP_DEPS=()
            for i in "${!APP_DEPS[@]}"; do
                if [[ ${APP_DEPS[i]} != "php-json" ]]; then
                    CENTOS7_APP_DEPS+=( "${APP_DEPS[i]}" )
                fi
            done
            # re-assign the clean dependency array back to APP_DEPS
            APP_DEPS=("${CENTOS7_APP_DEPS[@]}")
            unset CENTOS7_APP_DEPS
        fi
        # CentOS requires the EPEL repository to gain access to Fedora packages
        EPEL_PKG="epel-release"
        rpm -q ${EPEL_PKG} &> /dev/null || rc=$?
        if [[ $rc -ne 0 ]]; then
            printf "  %b Enabling EPEL package repository (https://fedoraproject.org/wiki/EPEL)\\n" "${INFO}"
            "${PKG_INSTALL[@]}" ${EPEL_PKG} &> /dev/null
            printf "  %b Installed %s\\n" "${TICK}" "${EPEL_PKG}"
        fi

        # The default php on CentOS 7.x is 5.4 which is EOL
        # Check if the version of PHP available via installed repositories is >= to PHP 7
        AVAILABLE_PHP_VERSION=$("${PKG_MANAGER}" info php | grep -i version | grep -o '[0-9]\+' | head -1)
        if [[ $AVAILABLE_PHP_VERSION -ge $SUPPORTED_CENTOS_PHP_VERSION ]]; then
            # Since PHP 7 is available by default, install via default PHP package names
            : # do nothing as PHP is current
        else
            REMI_PKG="remi-release"
            REMI_REPO="remi-php72"
            rpm -q ${REMI_PKG} &> /dev/null || rc=$?
        if [[ $rc -ne 0 ]]; then
            # The PHP version available via default repositories is older than version 7
            if ! whiptail --defaultno --title "PHP 7 Update (recommended)" --yesno "PHP 7.x is recommended for both security and language features.\\nWould you like to install PHP7 via Remi's RPM repository?\\n\\nSee: https://rpms.remirepo.net for more information" "${r}" "${c}"; then
                # User decided to NOT update PHP from REMI, attempt to install the default available PHP version
                printf "  %b User opt-out of PHP 7 upgrade on CentOS. Deprecated PHP may be in use.\\n" "${INFO}"
                : # continue with unsupported php version
            else
                printf "  %b Enabling Remi's RPM repository (https://rpms.remirepo.net)\\n" "${INFO}"
                "${PKG_INSTALL[@]}" "https://rpms.remirepo.net/enterprise/${REMI_PKG}-$(rpm -E '%{rhel}').rpm" &> /dev/null
                # enable the PHP 7 repository via yum-config-manager (provided by yum-utils)
                "${PKG_INSTALL[@]}" "yum-utils" &> /dev/null
                yum-config-manager --enable ${REMI_REPO} &> /dev/null
                printf "  %b Remi's RPM repository has been enabled for PHP7\\n" "${TICK}"
                # trigger an install/update of PHP to ensure previous version of PHP is updated from REMI
                if "${PKG_INSTALL[@]}" "php-cli" &> /dev/null; then
                    printf "  %b PHP7 installed/updated via Remi's RPM repository\\n" "${TICK}"
                else
                    printf "  %b There was a problem updating to PHP7 via Remi's RPM repository\\n" "${CROSS}"
                    exit 1
                fi
            fi
        fi
    fi
    else
        # Warn user of unsupported version of Fedora or CentOS
        if ! whiptail --defaultno --title "Unsupported RPM based distribution" --yesno "Would you like to continue installation on an unsupported RPM based distribution?\\n\\nPlease ensure the following packages have been installed manually:\\n\\n- lighttpd\\n- lighttpd-fastcgi\\n- PHP version 7+" "${r}" "${c}"; then
            printf "  %b Aborting installation due to unsupported RPM based distribution\\n" "${CROSS}"
            exit
        else
            printf "  %b Continuing installation with unsupported RPM based distribution\\n" "${INFO}"
        fi
    fi
else
    # it's not an OS we can support,
    printf "  %b OS distribution not supported\\n" "${CROSS}"
    # so exit the installer
    exit
fi
}
####################################
######## Pre Installation ##########
####################################

#Validate Basic requirements
isAlreadyInstalled

#Validate Basic Services
validateBasicServices

#Check for supported distribution
distro_check

# Start the installer
# Notify user of package availability
notify_package_updates_available

# Install packages used by this installation script
install_dependent_packages "${INSTALLER_DEPS[@]}"

# Check if SELinux is Enforcing
checkSelinux

####################################
######## Installation ##############
####################################

# Display welcome dialogs
welcomeDialogs

#DNS Service
getDNSService

#WAN Information
findWANInformation

#LAN Information
findLanInformation

######## LAN Information #########
if whiptail --backtitle "Confirmation" --title "Confirmation" --yesno "Are these settings correct?


            Internet (WAN) Interface: ${WAN_INTERFACE}
            Internet (WAN) IP:        ${WAN_ADDRESS}
            LAN Interface:            ${LAN_INTERFACE}
            LAN IP:                   ${LAN_ADDRESS}
            DNS Server:               ${DNS_SERVER_IP}
            
" "${r}" "${c}"; then

    # Install the Core dependencies
    printf "  %b Install the Core dependencies\\n" "${INFO}"
    install_dependent_packages "${APP_DEPS[@]}"

    printf "  %b Cloning netControl\\n" "${INFO}"
    rm -rf ${TMP_DIR}
    cd /tmp
    git clone ${netControlGitUrl} netControl

    printf "  %b Create directory for netControl\\n" "${INFO}"
    rm -rf "${INSTALL_DIR}"
    mv netControl/src ${INSTALL_DIR}

    mkdir -p /var/log/netControl
    
    ouiDatabase
    databaseSetup

    printf "  %b netControl permission\\n" "${INFO}"
    chmod -R 755 ${INSTALL_DIR}
    chown -R ${LIGHTTPD_USER}:${LIGHTTPD_GROUP} ${INSTALL_DIR}
    sudoerSetup
    cronSetup


    lighttpdSetup
    enable_service lighttpd
    restart_service lighttpd
    bootSetup

    echo ""
    echo ""
    echo ""
    echo ""
    echo "Congratulation!. netControl installation completed successfully."
    echo "Go to http://${WAN_ADDRESS}/netcontrol-admin to access NetControl Admin page"
    echo "Username: admin"
    echo "Password: enter a new password and it will be saved for future use!"
    echo ""
    echo ""
    echo ""
    echo ""
fi


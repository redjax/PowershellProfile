#!/bin/bash

## Arg Default values
CLEAN=false
MODULE_NAME="ProfileModule"
CONFIG_FILE=""

## Parse arguments
PARSED_ARGS=$(getopt -o f: --long clean,module-name:,config-file: -n "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    ## getopt has complained about wrong arguments to stdout
    exit 1
fi

eval set -- "$PARSED_ARGS"

while true; do
    case "$1" in
        --clean)
            CLEAN=true
            shift
            ;;
        --module-name)
            MODULE_NAME="$2"
            shift 2
            ;;
        --config-file|-f)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

## Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

## Detect distro using /etc/os-release
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO_ID=$ID
else
  echo "Cannot detect Linux distribution."
  exit 1
fi

function deb_install_powershell {
    sudo apt update -y

    if ! command -v wget &>/dev/null; then
        sudo apt install -y wget
        if [[ $? -ne 0 ]]; then
            echo "Failed to install wget"
            return $?
        fi
    fi

    ## Get version of Debian
    source /etc/os-release

    ## Download GPG keys
    wget -q https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb
    if [[ $? -ne 0 ]]; then
        echo "Failed to download GPG keys"
        return $?
    fi

    ## Register the Microsoft repository GPG keys
    sudo dpkg -i packages-microsoft-prod.deb
    if [[ $? -ne 0 ]]; then
        echo "Failed to register the Microsoft repository GPG keys"
        return $?
    fi

    ## Delete the Microsoft repository GPG keys file
    rm packages-microsoft-prod.deb

    ## Update the list of packages after we added packages.microsoft.com
    sudo apt-get update -y

    ## Install Powershell
    sudo apt-get install -y powershell

    if [[ $? -ne 0 ]]; then
        echo "Failed to install Powershell"
        return $?
    else
        echo "Powershell installed successfully"
        return 0
    fi
}

function ubuntu_install_powershell {
    sudo apt-get update -y

    ## Install pre-requisite packages.
    sudo apt-get install -y \
        wget \
        apt-transport-https \
        software-properties-common

    ## Get the version of Ubuntu
    source /etc/os-release

    ## Download the Microsoft repository keys
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb

    if [[ $? -ne 0 ]]; then
        echo "Failed to download GPG keys"
        return $?
    fi

    ## Register the Microsoft repository keys
    sudo dpkg -i packages-microsoft-prod.deb

    if [[ $? -ne 0 ]]; then
        echo "Failed to registry Microsoft repeository GPG keys"
        return $?
    fi

    ## Delete the Microsoft repository keys file
    rm packages-microsoft-prod.deb

    ## Update the list of packages after we added packages.microsoft.com
    sudo apt-get update -y

    ## Install PowerShell
    sudo apt-get install -y powershell

    if [[ $? -ne 0 ]]; then
        echo "Failed to install Powershell"
        return $?
    else
        echo "Powershell installed successfully"
        return 0
    fi
}

function fedora_install_powershell {
    ## Import Microsoft GPG key
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    ## Get Fedora version
    FEDORA_VER=$(rpm -E %fedora)
    if [[ $? -ne 0 || -z $FEDORA_VER ]]; then
        echo "Failed to get Fedora version"
        return $?
    fi
    
    ## Add Microsoft repository
    sudo dnf config-manager --add-repo https://packages.microsoft.com/config/fedora/${FEDORA_VER}/prod.repo
    if [[ $? -ne 0 ]]; then
        echo "Failed to add Microsoft repository"
        return $?
    fi

    ## Install PowerShell
    sudo dnf install powershell
    if [[ $? -ne 0 ]]; then
        echo "Failed to install Powershell"
        return $?
    else
        echo "Powershell installed successfully"
        return 0
    fi
}

function rhel_family_install_powershell {
    # Import Microsoft GPG key
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    # Detect major version (e.g., 7, 8, 9)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        # VERSION_ID may be "8.9" or "8"
        RHEL_MAJOR_VERSION=$(echo $VERSION_ID | cut -d'.' -f1)
    else
        echo "Cannot detect OS version."
        return 1
    fi

    # Add Microsoft repository
    sudo curl -sSL "https://packages.microsoft.com/config/rhel/${RHEL_MAJOR_VERSION}/prod.repo" -o /etc/yum.repos.d/microsoft.repo
    if [[ $? -ne 0 ]]; then
        echo "Failed to add Microsoft repository"
        return $?
    fi

    # Install PowerShell
    if command -v dnf &>/dev/null; then
        sudo dnf install -y powershell
    else
        sudo yum install -y powershell
    fi

    if [[ $? -ne 0 ]]; then
        echo "Failed to install Powershell"
        return $?
    else
        echo "Powershell installed successfully"
        return 0
    fi
}

function opensuse_install_powershell {
    sudo zypper refresh
    sudo zypper install -y libicu libopenssl3

    # Download latest Red Hat RPM (update version as needed)
    LATEST_RPM_URL="https://github.com/PowerShell/PowerShell/releases/latest/download/powershell-7.4.10-1.rh.x86_64.rpm"
    sudo zypper --no-gpg-checks --allow-unsigned-rpm install $LATEST_RPM_URL

    if [[ $? -ne 0 ]]; then
        echo "Failed to install PowerShell"
        return $?
    else
        echo "PowerShell installed successfully"
        return 0
    fi
}

function arch_install_powershell {
    if command -v yay &>/dev/null; then
        yay -S --noconfirm powershell-bin
    else
        echo "Please install an AUR helper like yay to install PowerShell."
        return 1
    fi

    if [[ $? -ne 0 ]]; then
        echo "Failed to install PowerShell"
        return $?
    else
        echo "PowerShell installed successfully"
        return 0
    fi
}

function install_powershell {
    if ! command -v pwsh &>/dev/null; then
        echo "Installing Powershell" &>/dev/null

        ## Choose package manager and install powershell
        case "$DISTRO_ID" in
        debian)
            deb_install_powershell
            return $?
            ;;

        ubuntu)
            ubuntu_install_powershell
            return $?
            ;;
        fedora)
            fedora_install_powershell
            return $?
            ;;
        centos|rhel|almalinux|rocky)
            rhel_family_install_powershell
            return $?
            ;;
        opensuse*)
            opensuse_install_powershell
            return $?
            ;;
        arch)
            arch_install_powershell
            return $?
            ;;
        *)
            echo "Unsupported or unknown distribution: $DISTRO_ID"
            exit 2
            ;;
        esac
    else
        echo "Powershell is already installed"
        return 0
    fi
}
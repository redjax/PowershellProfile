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
    echo "--[ Install Powershell: Debian" >&2

    echo "Updating package list" >&2
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

    if [[ -z $VERSION_ID ]]; then
        echo "Failed to get Debian version"
        return $?
    fi

    echo "Downloading GPG keys" >&2
    ## Download GPG keys
    wget -q https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb
    if [[ $? -ne 0 ]]; then
        echo "Failed to download GPG keys"
        return $?
    fi

    echo "Registering the Microsoft repository GPG keys" >&2
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

    echo "Install Powershell with apt-get" >&2
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
    echo "--[ Install Powershell: Ubuntu" >&2

    echo "Updating package list" >&2
    sudo apt-get update -y

    echo "Installing pre-requisite packages" >&2
    ## Install pre-requisite packages.
    sudo apt-get install -y \
        wget \
        apt-transport-https \
        software-properties-common

    ## Get the version of Ubuntu
    source /etc/os-release

    if [[ -z $VERSION_ID ]]; then
        echo "Failed to get Ubuntu version"
        return $?
    fi

    echo "Downloading GPG keys" &>/dev/null
    ## Download the Microsoft repository keys
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb

    if [[ $? -ne 0 ]]; then
        echo "Failed to download GPG keys"
        return $?
    fi

    echo "Registering the Microsoft repository keys" >&2
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

    echo "Install Powershell with apt-get" >&2
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
    echo "--[ Install Powershell: Fedora" >&2

    echo "Adding Microsoft GPG key" >&2
    ## Import Microsoft GPG key
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    if [[ $? -ne 0 ]]; then
        echo "Failed to import Microsoft GPG key"
        return $?
    fi

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

    echo "Install Powershell with dnf" >&2
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
    echo "--[ Install Powershell: RedHat-family (RHEL, CentOS, AlmaLinux, Rocky Linux)" >&2

    echo "Adding Microsoft GPG key" &>/dev/null
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

    echo "Install Powershell with dnf/yum" >&2
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
    echo "--[ Install Powershell: OpenSUSE" >&2

    echo "Installing required packages" >&2
    
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
    echo "--[ Install Powershell: Arch" >&2

    echo "Installing required packages" >&2

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
    echo "Installing Powershell" &>/dev/null

    if [[ -z $DISTRO_ID ]]; then
        get_distro
        if [[ $? -ne 0 ]]; then
            echo "Failed to get distro"
            return $?
        fi
    fi
    echo "Checking install method for distro: $DISTRO_ID"

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
}

function main {
    if ! command -v pwsh &>/dev/null; then
        install_powershell
        if [[ $? -ne 0 ]]; then
            echo "Failed to install Powershell"
            return $?
        fi
    else
        echo "Powershell is already installed"
        return 0
    fi

    return 0
}

main
if [[ $? -ne 0 ]]; then
    echo "Failed to install Powershell"
    return $?
else
    exit 0
fi
#!/bin/bash
#
# mlty: A self-installing CLI tool that displays a message of the day.
#
# Usage:
#   To install: ./mlty --install
#   To uninstall: ./mlty --uninstall 
#   To show help: ./mlty --help
#   To run after installation: mlty

# Show help message
show_help() {
    echo "Usage:"
    echo "  ./mlty --install    Install mlty to system"
    echo "  ./mlty --uninstall  Remove mlty from system"
    echo "  ./mlty --help       Show this help message"
    echo "  mlty               Display message of the day"
    exit 0
}

# Get a random joke from an API
get_random_joke() {
    if command -v curl >/dev/null 2>&1; then
        joke=$(curl -s https://icanhazdadjoke.com/ -H "Accept: text/plain")
    else
        joke="Why don't programmers like nature? It has too many bugs!"
    fi
    echo "$joke"
}

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Detect OS
get_os() {
    case "$(uname -s)" in
        Linux*)     
            if [[ -f /etc/debian_version ]]; then
                echo "debian"
            elif [[ -f /etc/redhat-release ]]; then
                echo "redhat"
            elif [[ -f /etc/arch-release ]]; then
                echo "arch"
            else
                echo "linux"
            fi
            ;;
        Darwin*)    echo "macos";;
        CYGWIN*)   echo "windows";;
        MINGW*)    echo "windows";;
        MSYS*)     echo "windows";;
        *)         echo "unknown";;
    esac
}

# If help flag is provided, show help
if [[ $1 == "--help" ]]; then
    show_help
fi

# If the script is run with the --install flag, perform installation.
if [[ $1 == "--install" ]]; then
    # Check if running with sudo (except on Windows)
    OS_TYPE=$(get_os)
    if [[ "$OS_TYPE" != "windows" ]]; then
        sudo -v || {
            echo "Error: Installation requires sudo privileges"
            exit 1
        }
    fi

    cat << EOF
                                                                           
                        lllllll         tttt                               
                        l:::::l      ttt:::t                               
                        l:::::l      t:::::t                               
                        l:::::l      t:::::t                               
   mmmmmmm    mmmmmmm    l::::lttttttt:::::tttttttyyyyyyy           yyyyyyy
 mm:::::::m  m:::::::mm  l::::lt:::::::::::::::::t y:::::y         y:::::y 
m::::::::::mm::::::::::m l::::lt:::::::::::::::::t  y:::::y       y:::::y  
m::::::::::::::::::::::m l::::ltttttt:::::::tttttt   y:::::y     y:::::y   
m:::::mmm::::::mmm:::::m l::::l      t:::::t          y:::::y   y:::::y    
m::::m   m::::m   m::::m l::::l      t:::::t           y:::::y y:::::y     
m::::m   m::::m   m::::m l::::l      t:::::t            y:::::y:::::y      
m::::m   m::::m   m::::m l::::l      t:::::t    tttttt   y:::::::::y       
m::::m   m::::m   m::::ml::::::l     t::::::tttt:::::t    y:::::::y        
m::::m   m::::m   m::::ml::::::l     tt::::::::::::::t     y:::::y         
m::::m   m::::m   m::::ml::::::l       tt:::::::::::tt    y:::::y          
mmmmmm   mmmmmm   mmmmmmllllllll         ttttttttttt     y:::::y           
                                                        y:::::y            
                                                       y:::::y             
                                                      y:::::y              
                                                     y:::::y               
                                                    yyyyyyy                
EOF
    echo

    echo -e "\e[1;34mSystem Information:"
    echo "Date: $(date)"
    echo "OS: $OS_TYPE"
    echo -e "System: $(uname -srm)\e[0m"
    echo

    echo -e "\e[1;36mInstalling mlty...\e[0m"
    echo "Here's a joke while we install:"
    get_random_joke
    echo

    case "$OS_TYPE" in
        "debian"|"redhat"|"arch"|"linux")
            (sudo cp "$0" /usr/local/bin/mlty && sudo chmod +x /usr/local/bin/mlty) &
            ;;
        "macos")
            (sudo cp "$0" /usr/local/bin/mlty && sudo chmod +x /usr/local/bin/mlty) &
            ;;
        "windows")
            # For Windows, we'll install to the user's home directory
            WIN_INSTALL_DIR="$HOME/mlty"
            mkdir -p "$WIN_INSTALL_DIR"
            (cp "$0" "$WIN_INSTALL_DIR/mlty" && chmod +x "$WIN_INSTALL_DIR/mlty") &
            echo "Please add $WIN_INSTALL_DIR to your PATH"
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac
    
    spinner $!
    echo
    echo
    echo "Installation complete! You can now use the following commands:"
    echo "  mlty               Display message of the day"
    echo "  mlty --help        Show help message"
    echo "  mlty --uninstall   Remove mlty from system"
    exit 0
fi

# If the script is run with the --uninstall flag, perform uninstallation
if [[ $1 == "--uninstall" ]]; then
    OS_TYPE=$(get_os)
    
    # Check if running with sudo (except on Windows)
    if [[ "$OS_TYPE" != "windows" ]]; then
        sudo -v || {
            echo "Error: Uninstallation requires sudo privileges"
            exit 1
        }
    fi

    # Ask for confirmation
    read -p "Are you sure you want to uninstall mlty? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 1
    fi

    echo "Uninstalling mlty ..."
    case "$OS_TYPE" in
        "debian"|"redhat"|"arch"|"linux"|"macos")
            sudo rm -f /usr/local/bin/mlty &
            ;;
        "windows")
            rm -rf "$HOME/mlty" &
            ;;
    esac
    
    spinner $!
    echo "Uninstallation complete!"
    exit 0
fi

# Otherwise, display the message of the day.
cat << EOF                                                             
                                                                           
                        lllllll         tttt                               
                        l:::::l      ttt:::t                               
                        l:::::l      t:::::t                               
                        l:::::l      t:::::t                               
   mmmmmmm    mmmmmmm    l::::lttttttt:::::tttttttyyyyyyy           yyyyyyy
 mm:::::::m  m:::::::mm  l::::lt:::::::::::::::::t y:::::y         y:::::y 
m::::::::::mm::::::::::m l::::lt:::::::::::::::::t  y:::::y       y:::::y  
m::::::::::::::::::::::m l::::ltttttt:::::::tttttt   y:::::y     y:::::y   
m:::::mmm::::::mmm:::::m l::::l      t:::::t          y:::::y   y:::::y    
m::::m   m::::m   m::::m l::::l      t:::::t           y:::::y y:::::y     
m::::m   m::::m   m::::m l::::l      t:::::t            y:::::y:::::y      
m::::m   m::::m   m::::m l::::l      t:::::t    tttttt   y:::::::::y       
m::::m   m::::m   m::::ml::::::l     t::::::tttt:::::t    y:::::::y        
m::::m   m::::m   m::::ml::::::l     tt::::::::::::::t     y:::::y         
m::::m   m::::m   m::::ml::::::l       tt:::::::::::tt    y:::::y          
mmmmmm   mmmmmm   mmmmmmllllllll         ttttttttttt     y:::::y           
                                                        y:::::y            
                                                       y:::::y             
                                                      y:::::y              
                                                     y:::::y               
                                                    yyyyyyy                
                                                                           
                                                                           
Welcome to mlty!
Date: $(date)
System: $(uname -srm)
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

EOF

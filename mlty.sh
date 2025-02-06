#!/bin/bash
#
# mlty: A self-installing CLI tool that displays a message of the day.
#
# Usage:
#   To install: ./mlty --install
#   To uninstall: ./mlty --uninstall 
#   To show help: ./mlty --help
#   To check package manager: ./mlty --check
#   To install package: ./mlty --pkg <package-name>
#   To remove package: ./mlty --remove <package-name>
#   To run dev script: ./mlty --dev
#   To install package manager: ./mlty --install-pkg-manager
#   To install dependencies: ./mlty --install-deps
#   To run after installation: mlty

# Show help message
show_help() {
    echo "Usage:"
    echo "  ./mlty --install    Install mlty to system"
    echo "  ./mlty --uninstall  Remove mlty from system"
    echo "  ./mlty --help       Show this help message"
    echo "  ./mlty --check      Check project info in current directory"
    echo "  ./mlty --pkg <pkg>  Install package using detected package manager"
    echo "  ./mlty --remove <pkg> Remove package using detected package manager"
    echo "  ./mlty --dev        Run dev script using detected package manager"
    echo "  ./mlty --install-pkg-manager Install detected package manager"
    echo "  ./mlty --install-deps Install all project dependencies"
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

# Check project info in current directory
check_package_manager() {
    # Get project name from package.json
    if [[ -f "package.json" ]]; then
        PROJECT_NAME=$(cat package.json | grep '"name":' | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')
        echo "Project Name: $PROJECT_NAME"
        
        # Detect project stack
        if grep -q '"@nestjs/core"' package.json; then
            echo "Project Stack: NestJS"
        elif grep -q '"next"' package.json; then
            echo "Project Stack: NextJS"
        elif grep -q '"react"' package.json; then
            echo "Project Stack: React"
        elif grep -q '"@angular/core"' package.json; then
            echo "Project Stack: Angular"
        elif grep -q '"vue"' package.json; then
            echo "Project Stack: Vue"
        else
            echo "Project Stack: Unknown/Other"
        fi
        
        # Detect package manager and version
        if [[ -f "bun.lockb" ]]; then
            echo "Package Manager: bun"
            echo "Version: $(bun --version 2>/dev/null || echo 'not installed')"
        elif [[ -f "pnpm-lock.yaml" ]]; then
            echo "Package Manager: pnpm"
            echo "Version: $(pnpm --version 2>/dev/null || echo 'not installed')"
        elif [[ -f "yarn.lock" ]]; then
            echo "Package Manager: yarn"
            echo "Version: $(yarn --version 2>/dev/null || echo 'not installed')"
        elif [[ -f "package-lock.json" ]]; then
            echo "Package Manager: npm"
            echo "Version: $(npm --version 2>/dev/null || echo 'not installed')"
        else
            echo "No package manager lock file found"
            echo "Supported package managers: npm, yarn, pnpm, bun"
        fi
    else
        echo "No package.json found in current directory"
    fi
}

# Install package manager based on detection
install_package_manager() {
    OS_TYPE=$(get_os)
    
    if [[ -f "bun.lockb" ]]; then
        echo "Installing bun..."
        case "$OS_TYPE" in
            "debian"|"redhat"|"arch"|"linux"|"macos")
                curl -fsSL https://bun.sh/install | bash
                ;;
            "windows")
                echo "Bun is not officially supported on Windows"
                exit 1
                ;;
        esac
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "Installing pnpm..."
        case "$OS_TYPE" in
            "debian"|"redhat"|"arch"|"linux"|"macos")
                curl -fsSL https://get.pnpm.io/install.sh | sh -
                ;;
            "windows")
                iwr https://get.pnpm.io/install.ps1 -useb | iex
                ;;
        esac
    elif [[ -f "yarn.lock" ]]; then
        echo "Installing yarn..."
        if ! command -v npm &> /dev/null; then
            echo "npm is required to install yarn. Please install Node.js first."
            exit 1
        fi
        npm install -g yarn
    elif [[ -f "package-lock.json" ]] || [[ ! -f "package.json" ]]; then
        echo "Installing npm..."
        case "$OS_TYPE" in
            "debian")
                sudo apt-get update && sudo apt-get install -y nodejs npm
                ;;
            "redhat")
                sudo dnf install -y nodejs npm
                ;;
            "arch")
                sudo pacman -S nodejs npm
                ;;
            "macos")
                if command -v brew &> /dev/null; then
                    brew install node
                else
                    echo "Please install Homebrew first"
                    exit 1
                fi
                ;;
            "windows")
                echo "Please download Node.js installer from https://nodejs.org"
                exit 1
                ;;
        esac
    fi
    
    echo "Package manager installation complete!"
}

# Install package using detected package manager
install_package() {
    local package_name=$1
    
    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Detect package manager
    if [[ -f "bun.lockb" ]]; then
        echo "Using bun to install $package_name..."
        bun add "$package_name"
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "Using pnpm to install $package_name..."
        pnpm add "$package_name"
    elif [[ -f "yarn.lock" ]]; then
        echo "Using yarn to install $package_name..."
        yarn add "$package_name"
    elif [[ -f "package-lock.json" ]]; then
        echo "Using npm to install $package_name..."
        npm install "$package_name"
    else
        echo "No package manager detected. Using npm as default..."
        npm install "$package_name"
    fi
}

# Install all dependencies using detected package manager
install_dependencies() {
    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    echo "Installing project dependencies..."
    
    # Detect package manager
    if [[ -f "bun.lockb" ]]; then
        echo "Using bun to install dependencies..."
        bun install
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "Using pnpm to install dependencies..."
        pnpm install
    elif [[ -f "yarn.lock" ]]; then
        echo "Using yarn to install dependencies..."
        yarn install
    elif [[ -f "package-lock.json" ]]; then
        echo "Using npm to install dependencies..."
        npm install
    else
        echo "No package manager detected. Using npm as default..."
        npm install
    fi
    
    echo "Dependencies installation complete!"
}

# Remove package using detected package manager
remove_package() {
    local package_name=$1
    
    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Detect package manager
    if [[ -f "bun.lockb" ]]; then
        echo "Using bun to remove $package_name..."
        bun remove "$package_name"
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "Using pnpm to remove $package_name..."
        pnpm remove "$package_name"
    elif [[ -f "yarn.lock" ]]; then
        echo "Using yarn to remove $package_name..."
        yarn remove "$package_name"
    elif [[ -f "package-lock.json" ]]; then
        echo "Using npm to remove $package_name..."
        npm uninstall "$package_name"
    else
        echo "No package manager detected. Using npm as default..."
        npm uninstall "$package_name"
    fi
}

# Check if dependencies are installed
check_deps_installed() {
    if [[ ! -f "package.json" ]]; then
        return 1
    fi

    if [[ -d "node_modules" ]]; then
        return 0
    else
        return 1
    fi
}

# Run dev script using detected package manager
run_dev() {
    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Check if dependencies are installed
    if ! check_deps_installed; then
        echo "Dependencies not found. Installing dependencies first..."
        install_dependencies
    fi

    # Detect package manager
    if [[ -f "bun.lockb" ]]; then
        echo "Using bun to run dev script..."
        bun run dev
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "Using pnpm to run dev script..."
        pnpm run dev
    elif [[ -f "yarn.lock" ]]; then
        echo "Using yarn to run dev script..."
        yarn dev
    elif [[ -f "package-lock.json" ]]; then
        echo "Using npm to run dev script..."
        npm run dev
    else
        echo "No package manager detected. Using npm as default..."
        npm run dev
    fi
}

# If help flag is provided, show help
if [[ $1 == "--help" ]]; then
    show_help
fi

# If check flag is provided, check package manager
if [[ $1 == "--check" ]]; then
    check_package_manager
    exit 0
fi

# If install-pkg-manager flag is provided, install package manager
if [[ $1 == "--install-pkg-manager" ]]; then
    install_package_manager
    exit 0
fi

# If install-deps flag is provided, install dependencies
if [[ $1 == "--install-deps" ]]; then
    install_dependencies
    exit 0
fi

# If pkg flag is provided, install package
if [[ $1 == "--pkg" ]]; then
    if [[ -z $2 ]]; then
        echo "Error: Package name is required"
        echo "Usage: mlty --pkg <package-name>"
        exit 1
    fi
    install_package "$2"
    exit 0
fi

# If remove flag is provided, remove package
if [[ $1 == "--remove" ]]; then
    if [[ -z $2 ]]; then
        echo "Error: Package name is required"
        echo "Usage: mlty --remove <package-name>"
        exit 1
    fi
    remove_package "$2"
    exit 0
fi

# If dev flag is provided, run dev script
if [[ $1 == "--dev" ]]; then
    run_dev
    exit 0
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

    echo "System Information:"
    echo "Date: $(date)"
    echo "OS: $OS_TYPE"
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
    echo "  mlty --check       Check package manager in current directory"
    echo "  mlty --pkg <pkg>   Install package using detected package manager"
    echo "  mlty --remove <pkg> Remove package using detected package manager"
    echo "  mlty --dev         Run dev script using detected package manager"
    echo "  mlty --install-pkg-manager Install detected package manager"
    echo "  mlty --install-deps Install all project dependencies"
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

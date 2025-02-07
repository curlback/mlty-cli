#!/bin/bash
#
# mlty: A versatile command-line tool for managing projects and package managers. It provides utilities for installing/removing packages, running scripts, checking project info, and managing dependencies across npm, yarn, pnpm and bun package managers.
#
# Usage:
#   To install: ./mlty --install
#   To uninstall: ./mlty --uninstall 
#   To show help: ./mlty --help
#   To check package manager: ./mlty --check
#   To install package: ./mlty --pkg <package-name> [external-flag]
#   To use alternate package manager: ./mlty --altpkg <package-name> [external-flag]
#   To remove package: ./mlty --remove <package-name>
#   To run script: ./mlty --run <script-name>
#   To install package manager: ./mlty --install-pkg-manager
#   To install dependencies: ./mlty --install-deps
#   To update mlty: ./mlty --update
#   To start project: ./mlty --start
#   To run after installation: mlty

# Show help message
show_help() {
    echo "Usage:"
    echo "  ./mlty --install    Install mlty to system"
    echo "  ./mlty --uninstall  Remove mlty from system"
    echo "  ./mlty --help       Show this help message"
    echo "  ./mlty --check      Check project info in current directory"
    echo "  ./mlty --pkg <pkg> [external-flag]  Install package using detected package manager with optional external flag"
    echo "  ./mlty --altpkg <pkg> [external-flag]  Install package using alternate package manager with optional external flag"
    echo "  ./mlty --remove <pkg> Remove package using detected package manager"
    echo "  ./mlty --run <script>  Run script using detected package manager"
    echo "  ./mlty --install-pkg-manager Install detected package manager"
    echo "  ./mlty --install-deps Install all project dependencies"
    echo "  ./mlty --start      Start project setup and run scripts"
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

# Start project setup and run scripts
start_project() {
    # Get OS info
    OS_TYPE=$(get_os)
    echo "🖥️  Operating System: $OS_TYPE"
    
    # Get project info
    if [[ ! -f "package.json" ]]; then
        echo "❌ No package.json found in current directory"
        exit 1
    fi
    
    PROJECT_NAME=$(jq -r '.name' package.json)
    echo "📦 Project Name: $PROJECT_NAME"
    
    # Detect and verify package manager
    if [[ -f "bun.lockb" ]]; then
        PKG_MANAGER="bun"
        PKG_VERSION=$(bun --version 2>/dev/null || echo 'not installed')
    elif [[ -f "pnpm-lock.yaml" ]]; then
        PKG_MANAGER="pnpm"
        PKG_VERSION=$(pnpm --version 2>/dev/null || echo 'not installed')
    elif [[ -f "yarn.lock" ]]; then
        PKG_MANAGER="yarn"
        PKG_VERSION=$(yarn --version 2>/dev/null || echo 'not installed')
    elif [[ -f "package-lock.json" ]]; then
        PKG_MANAGER="npm"
        PKG_VERSION=$(npm --version 2>/dev/null || echo 'not installed')
    else
        PKG_MANAGER="npm"
        PKG_VERSION=$(npm --version 2>/dev/null || echo 'not installed')
    fi
    
    echo "📋 Package Manager: $PKG_MANAGER"
    echo "🔖 Version: $PKG_VERSION"
    
    # Check if package manager is installed
    if [[ $PKG_VERSION == "not installed" ]]; then
        echo "❌ $PKG_MANAGER is not installed"
        case $PKG_MANAGER in
            "bun")
                echo "📝 Install bun: https://bun.sh/docs/installation"
                ;;
            "pnpm") 
                echo "📝 Install pnpm: https://pnpm.io/installation"
                ;;
            "yarn")
                echo "📝 Install yarn: https://yarnpkg.com/getting-started/install"
                ;;
            "npm")
                echo "📝 Install npm: https://nodejs.org"
                ;;
        esac
        exit 1
    fi
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    echo "Here's a joke while you wait:"
    get_random_joke
    echo
    
    case $PKG_MANAGER in
        "bun")
            bun install &
            ;;
        "pnpm")
            pnpm install &
            ;;
        "yarn")
            yarn install &
            ;;
        "npm")
            npm install &
            ;;
    esac
    
    spinner $!
    echo "✅ Dependencies installed successfully!"
    
    # Get available scripts
    echo "📜 Available scripts:"
    SCRIPTS=$(jq -r '.scripts | keys[]' package.json)
    echo "$SCRIPTS" | nl -w2 -s') '
    
    # Ask user which script to run
    echo
    read -p "Enter the number of the script you want to run (or 0 to exit): " SCRIPT_NUM
    
    if [[ $SCRIPT_NUM == "0" ]]; then
        echo "👋 Goodbye!"
        exit 0
    fi
    
    SELECTED_SCRIPT=$(echo "$SCRIPTS" | sed -n "${SCRIPT_NUM}p")
    
    if [[ -z $SELECTED_SCRIPT ]]; then
        echo "❌ Invalid script number"
        exit 1
    fi
    
    echo "🚀 Running script: $SELECTED_SCRIPT"
    case $PKG_MANAGER in
        "bun")
            bun run "$SELECTED_SCRIPT"
            ;;
        "pnpm")
            pnpm run "$SELECTED_SCRIPT"
            ;;
        "yarn")
            yarn run "$SELECTED_SCRIPT"
            ;;
        "npm")
            npm run "$SELECTED_SCRIPT"
            ;;
    esac
}

# Check project info in current directory
check_package_manager() {
    # Get project name from package.json
    if [[ -f "package.json" ]]; then
        PROJECT_NAME=$(cat package.json | grep '"name":' | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')
        echo "📦 Project Name: $PROJECT_NAME"
        
        # Detect project stack
        if grep -q '"@nestjs/core"' package.json; then
            echo "🏗️  Project Stack: NestJS"
        elif grep -q '"next"' package.json; then
            echo "⚡ Project Stack: NextJS" 
        elif grep -q '"react"' package.json; then
            echo "⚛️  Project Stack: React"
        elif grep -q '"@angular/core"' package.json; then
            echo "🅰️  Project Stack: Angular"
        elif grep -q '"vue"' package.json; then
            echo "🟩 Project Stack: Vue"
        else
            echo "❓ Project Stack: Unknown/Other"
        fi
        
        # Detect package manager and version
        if [[ -f "bun.lockb" ]]; then
            echo "🥟 Package Manager: bun"
            echo "📊 Version: $(bun --version 2>/dev/null || echo 'not installed')"
        elif [[ -f "pnpm-lock.yaml" ]]; then
            echo "🚀 Package Manager: pnpm"
            echo "📊 Version: $(pnpm --version 2>/dev/null || echo 'not installed')"
        elif [[ -f "yarn.lock" ]]; then
            echo "🧶 Package Manager: yarn"
            echo "📊 Version: $(yarn --version 2>/dev/null || echo 'not installed')"
        elif [[ -f "package-lock.json" ]]; then
            echo "📦 Package Manager: npm"
            echo "📊 Version: $(npm --version 2>/dev/null || echo 'not installed')"
        else
            echo "⚠️  No package manager lock file found"
            echo "💡 Supported package managers: npm, yarn, pnpm, bun"
        fi
    else
        echo "❌ No package.json found in current directory"
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
    local external_flag=$2

    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Get project name from package.json
    local project_name=$(grep -m 1 '"name":' package.json | cut -d'"' -f4)

    # Detect and show package manager info
    if [[ -f "bun.lockb" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: bun"
        echo "🔖 Version: $(bun --version)"
        echo
        echo "Using bun to install $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! bun add "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! bun add "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: pnpm"
        echo "🔖 Version: $(pnpm --version)"
        echo
        echo "Using pnpm to install $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! pnpm add "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! pnpm add "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    elif [[ -f "yarn.lock" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: yarn"
        echo "🔖 Version: $(yarn --version)"
        echo
        echo "Using yarn to install $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! yarn add "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! yarn add "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    elif [[ -f "package-lock.json" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: npm"
        echo "🔖 Version: $(npm --version)"
        echo
        echo "Using npm to install $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! npm install "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! npm install "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    else
        echo "Error: No package manager detected. Please run 'mlty --install-pkg-manager' first"
        exit 1
    fi
}

# Install package using alternate package manager
install_package_alt() {
    local package_name=$1
    local external_flag=$2

    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Get project name from package.json
    local project_name=$(grep -m 1 '"name":' package.json | cut -d'"' -f4)

    # Detect and show package manager info
    if [[ -f "bun.lockb" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: bunx (alternate)"
        echo "🔖 Version: $(bun --version)"
        echo
        echo "Using bunx to run $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! bunx "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! bunx "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: pnpx (alternate)"
        echo "🔖 Version: $(pnpm --version)"
        echo
        echo "Using pnpx to run $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! pnpx "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! pnpx "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    elif [[ -f "yarn.lock" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: yarn dlx (alternate)"
        echo "🔖 Version: $(yarn --version)"
        echo
        echo "Using yarn dlx to run $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! yarn dlx "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! yarn dlx "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    elif [[ -f "package-lock.json" ]] || [[ ! -f "bun.lockb" && ! -f "pnpm-lock.yaml" && ! -f "yarn.lock" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: npx (alternate)"
        echo "🔖 Version: $(npm --version)"
        echo
        echo "Using npx to run $package_name..."
        if [[ -n "$external_flag" ]]; then
            if ! npx "${package_name}" "${external_flag}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        else
            if ! npx "${package_name}"; then
                if [[ $? -eq 130 ]]; then
                    echo "You cancelled the command"
                fi
                exit 1
            fi
        fi
    fi
}

# Install all dependencies using detected package manager
install_dependencies() {
    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Get project name from package.json
    local project_name=$(jq -r '.name' package.json)

    echo "Installing project dependencies..."
    
    # Detect package manager
    if [[ -f "bun.lockb" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: bun"
        echo "🔖 Version: $(bun --version)"
        echo
        echo "Using bun to install dependencies..."
        bun install
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: pnpm"
        echo "🔖 Version: $(pnpm --version)"
        echo
        echo "Using pnpm to install dependencies..."
        pnpm install
    elif [[ -f "yarn.lock" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: yarn"
        echo "🔖 Version: $(yarn --version)"
        echo
        echo "Using yarn to install dependencies..."
        yarn install
    elif [[ -f "package-lock.json" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: npm"
        echo "🔖 Version: $(npm --version)"
        echo
        echo "Using npm to install dependencies..."
        npm install
    else
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: npm (default)"
        echo "🔖 Version: $(npm --version)"
        echo
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

# Run script using detected package manager
run_script() {
    local script_name=$1

    if [[ ! -f "package.json" ]]; then
        echo "Error: No package.json found in current directory"
        exit 1
    fi

    # Get project name and available scripts from package.json
    local project_name=$(jq -r '.name' package.json)
    local available_scripts=$(jq -r '.scripts | keys[]' package.json)

    # Check if script exists in package.json
    if ! jq -e ".scripts[\"$script_name\"]" package.json >/dev/null 2>&1; then
        echo "Error: Script '$script_name' not found in package.json"
        echo "Available scripts:"
        echo "$available_scripts" | sed 's/^/  - /'
        exit 1
    fi

    # Check if dependencies are installed
    if ! check_deps_installed; then
        echo "Ouch! Couldn't find the deps, but don't worry, I am installing that now..."
        echo "Here is a joke for you while you wait:"
        get_random_joke
        echo
        install_dependencies &
        spinner $!
    fi

    # Detect package manager and show info
    if [[ -f "bun.lockb" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: bun"
        echo "🔖 Version: $(bun --version)"
        echo
        echo "Using bun to run script '$script_name'..."
        bun run "$script_name"
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: pnpm"
        echo "🔖 Version: $(pnpm --version)"
        echo
        echo "Using pnpm to run script '$script_name'..."
        pnpm run "$script_name"
    elif [[ -f "yarn.lock" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: yarn"
        echo "🔖 Version: $(yarn --version)"
        echo
        echo "Using yarn to run script '$script_name'..."
        yarn run "$script_name"
    elif [[ -f "package-lock.json" ]]; then
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: npm"
        echo "🔖 Version: $(npm --version)"
        echo
        echo "Using npm to run script '$script_name'..."
        npm run "$script_name"
    else
        echo "📦 Project: $project_name"
        echo "📋 Package Manager: npm (default)"
        echo "🔖 Version: $(npm --version)"
        echo
        echo "No package manager detected. Using npm as default..."
        npm run "$script_name"
    fi
}

# Existing functionality (unchanged)
# If help flag is provided, show help
if [[ $1 == "--help" ]]; then
    show_help
fi

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
        echo "Usage: mlty --pkg <package-name> [external-flag]"
        exit 1
    fi
    install_package "$2" "$3"
    exit 0
fi

# If altpkg flag is provided, install package using alternate package manager
if [[ $1 == "--altpkg" ]]; then
    if [[ -z $2 ]]; then
        echo "Error: Package name is required"
        echo "Usage: mlty --altpkg <package-name> [external-flag]"
        exit 1
    fi
    install_package_alt "$2" "$3"
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

# If run flag is provided, run script
if [[ $1 == "--run" ]]; then
    if [[ -z $2 ]]; then
        echo "Error: Script name is required"
        echo "Usage: mlty --run <script-name>"
        exit 1
    fi
    run_script "$2"
    exit 0
fi

# If start flag is provided, start project setup
if [[ $1 == "--start" ]]; then
    start_project
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
    echo "  mlty --pkg <pkg> [external-flag]   Install package using detected package manager"
    echo "  mlty --altpkg <pkg> [external-flag]   Install package using alternate package manager"
    echo "  mlty --remove <pkg> Remove package using detected package manager"
    echo "  mlty --run <script>  Run script using detected package manager"
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


# Auto-install when script is piped into bash
if [[ $# -eq 0 ]] && [[ ! -t 0 ]]; then
    echo -e "\n📦 Detected pipeline execution - Auto-installing mlty..."
    echo "⬇️  Downloading latest version from GitHub..."
   
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
        "debian"|"redhat"|"arch"|"linux"|"macos")
            echo "⬇️  Downloading the latest version of mlty..."
            sudo curl -sSL https://raw.githubusercontent.com/curlback/mlty-cli/master/mlty.sh -o /usr/local/bin/mlty
            sudo chmod +x /usr/local/bin/mlty
            ;;
        "windows")
            # For Windows, install to the user's home directory
            WIN_INSTALL_DIR="$HOME/mlty"
            mkdir -p "$WIN_INSTALL_DIR"
            curl -sSL https://raw.githubusercontent.com/curlback/mlty-cli/master/mlty.sh -o "$WIN_INSTALL_DIR/mlty"
            chmod +x "$WIN_INSTALL_DIR/mlty"
            echo "Please add $WIN_INSTALL_DIR to your PATH"
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac

    echo
    echo
    echo "Installation complete! You can now use the following commands:"
    echo "  mlty               Display message of the day"
    echo "  mlty --help        Show help message"
    echo "  mlty --uninstall   Remove mlty from system"
    echo "  mlty --check       Check package manager in current directory"
    echo "  mlty --pkg <pkg> [external-flag]   Install package using detected package manager"
    echo "  mlty --altpkg <pkg> [external-flag]   Install package using alternate package manager"
    echo "  mlty --remove <pkg> Remove package using detected package manager"
    echo "  mlty --run <script>  Run script using detected package manager"
    echo "  mlty --install-pkg-manager Install detected package manager"
    echo "  mlty --install-deps Install all project dependencies"
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
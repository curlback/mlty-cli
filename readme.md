# mlty.sh

A versatile command-line tool that combines system utilities with package management capabilities and functionality such as package management detection and installation.

## Features

- Checks package manager information in the current directory
- Installs and removes packages using the detected package manager
- Supports multiple operating systems (Linux, macOS, Windows)

## Installation

### Linux (Debian, RedHat, Arch, and others)

1. Clone the repository:
   ```bash
   git clone https://github.com/curlback/mlty-cli.git
   cd mlty-cli
   ```
2. Make the script executable:
   ```bash
   chmod +x mlty
   ```
3. Run the installation command:
   ```bash
   ./mlty --install
   ```
   This will copy `mlty` to `/usr/local/bin/` for global use.

### macOS

1. Clone the repository:
   ```bash
   git clone https://github.com/curlback/mlty-cli.git
   cd mlty-cli
   ```
2. Make the script executable:
   ```bash
   chmod +x mlty
   ```
3. Run the installation command:
   ```bash
   ./mlty --install
   ```
   This will copy `mlty` to `/usr/local/bin/` for global use.

### Windows

1. Clone the repository:
   ```cmd
   git clone https://github.com/curlback/mlty-cli.git
   cd mlty-cli
   ```
2. Move the script to a directory of your choice (e.g., `C:\mlty`).
3. Open Command Prompt and navigate to the directory:
   ```cmd
   cd C:\mlty
   ```
4. Add the directory to your system `PATH`:
   ```cmd
   setx PATH "%PATH%;C:\mlty"
   ```
5. Run the installation command:
   ```cmd
   mlty --install
   ```
   For Windows, manual PATH setup is required to use `mlty` globally.

## Usage

### Display the Message of the Day

# mlty.sh

A versatile command-line tool that combines system utilities with package management capabilities and functionality such as package management detection and installation.

## Features

- Checks package manager information in the current directory
- Installs and removes packages using the detected package manager
- Supports multiple operating systems (Linux, macOS, Windows)

## Installation

### Linux (Debian, RedHat, Arch, and others)

1. Download the `mlty` script:
   ```bash
   wget https://github.com/curlback/mlty-cli.git -O mlty
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

1. Download the `mlty` script:
   ```bash
   curl -o mlty https://github.com/curlback/mlty-cli.git
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

1. Download the `mlty` script manually from the repository.
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

```bash
mlty
```

### Show Help

```bash
mlty --help
```

### Uninstall mlty

```bash
mlty --uninstall
```

### Check Package Manager and Project Stack

```bash
mlty --check
```

### Install a Package

```bash
mlty --pkg <package-name>
```

### Remove a Package

```bash
mlty --remove <package-name>
```

## Supported Platforms

`mlty` supports the following operating systems:

- Linux (Debian, RedHat, Arch, and others)
- macOS
- Windows (manual PATH setup required)

## Package Manager Detection

When running `mlty --check`, it will detect the package manager based on the presence of lock files:

- `bun.lockb` → bun
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `package-lock.json` → npm

## Uninstallation

To remove `mlty` from your system:

```bash
mlty --uninstall
```

## License

This project is licensed under the MIT License.

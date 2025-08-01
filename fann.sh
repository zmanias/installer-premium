#!/bin/bash
# ===================================================================================
# Pterodactyl Advanced Installer & Management Script
# Refactored for clarity, robustness, and maintainability.
#
# "Perfection is achieved, not when there is nothing more to add, 
#  but when there is nothing left to take away." - Antoine de Saint-Exupéry
# ===================================================================================

# --- Script Configuration ---
# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# Pipelines return the exit status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Constants and Global Variables ---

# WARNING: Hardcoding tokens is a major security risk. It's like leaving your house key
# under the doormat. A better practice is to use environment variables.
# Example: GITHUB_TOKEN="${GITHUB_TOKEN:-your_default_token}"
readonly GITHUB_TOKEN="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"
readonly REPO_URL="https://KiwamiXq1031:${GITHUB_TOKEN}@github.com/KiwamiXq1031/installer-premium.git"
readonly TEMP_DIR="/tmp/installer-premium-$$" # Use process ID for unique temp dir

# Core Directories
readonly PTERO_DIR="/var/www/pterodactyl"
readonly PTERO_VIEWS_DIR="${PTERO_DIR}/resources/views/templates"
readonly CONFIG_FILE="${PTERO_DIR}/config/installer_config"

# Colors for better readability
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[1;33m'
readonly C_RESET='\033[0m'

# --- Helper Functions ---

# A unified function for displaying colored messages.
msg() {
    local color="$1"
    shift
    printf "${color}%s${C_RESET}\n" "$@"
}

# Spinner animation for long-running commands.
spinner() {
    local pid=$1
    local message=${2:-"Processing..."}
    local spinstr='|/-\'
    
    # Do not show spinner if animations are disabled
    if [[ "${DISABLE_ANIMATIONS:-0}" -eq 1 ]]; then
        wait "$pid"
        return
    fi
    
    while ps -p "$pid" > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$message"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\r"
    done
    printf " \r\033[K" # Clear the line
}

# Execute a command with a spinner.
run_with_spinner() {
    local message="$1"
    shift
    "$@" &
    spinner $! "$message"
    wait $! # Wait for the command and capture its exit code
}

# Ensure the script is run with root privileges.
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        msg "$C_RED" "Skrip ini harus dijalankan sebagai root. Silakan gunakan 'sudo'."
        exit 1
    fi
}

# Check for essential commands before starting.
check_dependencies() {
    local missing_deps=0
    for cmd in git curl unzip composer php yarn; do
        if ! command -v "$cmd" &> /dev/null; then
            msg "$C_RED" "Dependensi tidak ditemukan: $cmd"
            missing_deps=1
        fi
    done

    if [[ "$missing_deps" -eq 1 ]]; then
        msg "$C_YELLOW" "Silakan install dependensi yang hilang dan coba lagi."
        exit 1
    fi
}

# Load/Save animation preference.
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        DISABLE_ANIMATIONS=0
    fi
}

save_config() {
    echo "DISABLE_ANIMATIONS=${DISABLE_ANIMATIONS}" > "$CONFIG_FILE"
}

# --- Core Logic Functions ---

# Clone the private repository.
clone_repo() {
    msg "$C_BLUE" "Mengk-kloning repositori premium..."
    rm -rf "$TEMP_DIR"
    git clone --quiet "$REPO_URL" "$TEMP_DIR"
}

# Common Pterodactyl build steps.
run_ptero_build() {
    msg "$C_BLUE" "Menjalankan proses build Pterodactyl..."
    cd "$PTERO_DIR"
    run_with_spinner "Menginstall dependensi yarn..." yarn install --frozen-lockfile
    run_with_spinner "Membangun aset produksi..." yarn build:production
    php artisan view:clear
    php artisan config:clear
    msg "$C_GREEN" "Proses build selesai."
}

# Check if Blueprint is installed.
check_blueprint() {
    if [[ ! -f "${PTERO_DIR}/blueprint.sh" ]]; then
        msg "$C_RED" "Blueprint tidak ditemukan!"
        msg "$C_YELLOW" "Silakan install dependensi terlebih dahulu (Opsi 11)."
        exit 1
    fi
}

# Clean up temporary files.
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT # Ensure cleanup runs on script exit

# --- Menu Option Functions ---

display_header() {
    clear
    printf "${C_RED}"
    echo "╭━━━━┳━━━┳━━━┳━━━━╮"
    echo "╰━━╮━┃╭━━┫╭━╮┃╭╮╭╮┃"
    echo "╱╱╭╯╭┫╰━━┫╰━╯┃╭━━╮┃"
    echo "╱╭╯╭╯┃╭━━┫╭╮╭┫┃┃┃┃┃"
    echo "╭╯━╰━┫╰━━┫┃┃╰┫╰━━╯┃"
    echo "╰━━━━┻━━━┻╯╰━┻━━━━╯"
    printf "${C_RESET}"
    msg "$C_RED" "𝗢𝗪𝗡𝗘𝗥${C_BLUE}𝗗𝗘𝗩𝗘𝗟𝗢𝗣𝗘𝗥"
    msg "$C_GREEN" "WHATSAPP Fandirr : 083155619441"
    msg "$C_RED" "TELEGRAM : t.me/BotzFandirr"
    msg "$C_RED" "© Fandirr-DEVELOPER\n"
}

display_menu() {
    echo "𝗧𝗛𝗘𝗠𝗘 (𝗙𝗜𝗟𝗘𝗦)"
    echo " 1. Install Elysium Theme"
    echo " 2. Install Nebula Theme (Plugins)"
    echo " 3. Install Slate Admin Theme (Plugins)"
    echo
    echo "𝗔𝗗𝗗𝗢𝗡"
    echo " 4. Install Auto Suspend Addon"
    echo " 5. Install Google Analytics Addon"
    echo " 6. Install Enigma Premium Remake"
    echo " 10. Install Cookies Addon (Plugins)"
    echo
    echo "𝗣𝗘𝗡𝗚𝗘𝗟𝗢𝗟𝗔𝗔𝗡 & 𝗨𝗧𝗜𝗟𝗜𝗧𝗔𝗦"
    echo " 7. Ubah Background Login Pterodactyl"
    echo " 8. Reset Background (Hapus Kustom)"
    echo " 9. Reset Pterodactyl ke Awal (Hapus Semua Tema/Addon)"
    echo " 11. Install/Update Dependensi (Blueprint & Build Tools)"
    echo " 12. Aktifkan/Matikan Animasi Installer"
    echo
    echo "𝗛𝗔𝗣𝗨𝗦 𝗣𝗟𝗨𝗚𝗜𝗡𝗦"
    echo " 14. Hapus Nebula Theme"
    echo " 15. Hapus Slate Theme"
    echo " 16. Hapus Cookies Addon"
    echo
    echo " 13. Keluar"
    echo "────────────────────────────────────────"
}

# Function for options that use Blueprint
install_blueprint_plugin() {
    local plugin_name="$1"
    local zip_file="$2"
    
    msg "$C_YELLOW" "Menginstall plugin: ${plugin_name}..."
    check_blueprint
    clone_repo
    
    mv "${TEMP_DIR}/${zip_file}" "${PTERO_DIR}/"
    unzip -o "${PTERO_DIR}/${zip_file}" -d "${PTERO_DIR}/"
    
    cd "$PTERO_DIR"
    run_with_spinner "Menginstall ${plugin_name} dengan Blueprint..." ./blueprint.sh -install "${plugin_name}"
    
    # Cleanup
    rm "${PTERO_DIR}/${zip_file}" "${PTERO_DIR}/${plugin_name}.blueprint"
    
    msg "$C_GREEN" "Plugin '${plugin_name}' berhasil diinstall."
}

# Function to remove a Blueprint plugin
remove_blueprint_plugin() {
    local plugin_name="$1"

    msg "$C_YELLOW" "Mencoba menghapus plugin: ${plugin_name}..."
    check_blueprint
    
    if [[ ! -d "${PTERO_DIR}/public/extensions/${plugin_name}" && ! -d "${PTERO_DIR}/app/Blueprint/Extensions/slate" ]]; then
        msg "$C_RED" "Plugin '${plugin_name}' sepertinya tidak terinstall."
        return
    fi
    
    cd "$PTERO_DIR"
    if ./blueprint.sh -remove "${plugin_name}"; then
        msg "$C_GREEN" "Plugin '${plugin_name}' berhasil dihapus."
    else
        msg "$C_RED" "Gagal menghapus plugin '${plugin_name}'. Mungkin sudah dihapus sebagian."
    fi
}

install_elysium() {
    msg "$C_YELLOW" "Menginstall Elysium Theme..."
    clone_repo
    mv "${TEMP_DIR}/ElysiumTheme.zip" /var/www/
    unzip -o /var/www/ElysiumTheme.zip -d /var/www/
    rm /var/www/ElysiumTheme.zip
    
    msg "$C_BLUE" "Menginstall dependensi Node.js..."
    apt-get update -qq >/dev/null
    apt-get install -y -qq nodejs npm
    npm i -g yarn >/dev/null 2>&1
    
    run_ptero_build
    php artisan migrate --force
    msg "$C_GREEN" "Elysium Theme berhasil diinstall."
}

change_background() {
    local default_url="https://i.postimg.cc/s2wGzpHs/zerodev.jpg"
    read -p "Masukkan URL gambar (Enter untuk default): " user_url
    local url="${user_url:-$default_url}"

    msg "$C_BLUE" "Mengubah background dengan URL: $url"

    local wrapper_file="${PTERO_VIEWS_DIR}/wrapper.blade.php"
    
    # Create a backup first, just in case.
    cp "$wrapper_file" "${wrapper_file}.bak"
    msg "$C_YELLOW" "Backup file asli dibuat di ${wrapper_file}.bak"

    # Use sed to inject the style block cleanly before </head>
    sed -i "/<\/head>/i \
    <style> \
        body { \
            background-image: url('${url}'); \
            background-size: cover; \
            background-repeat: no-repeat; \
            background-attachment: fixed; \
        } \
    </style>" "$wrapper_file"

    msg "$C_GREEN" "Background berhasil diubah."
    msg "$C_YELLOW" "Jika terjadi masalah, pulihkan dari file .bak atau gunakan Opsi 8."
}

reset_background() {
    local wrapper_file="${PTERO_VIEWS_DIR}/wrapper.blade.php"
    
    if [[ -f "${wrapper_file}.bak" ]]; then
        msg "$C_BLUE" "Memulihkan background dari backup..."
        mv "${wrapper_file}.bak" "$wrapper_file"
        msg "$C_GREEN" "Background berhasil direset dari backup."
    else
        msg "$C_RED" "File backup tidak ditemukan. Gunakan Opsi 9 untuk reset total jika perlu."
    fi
}

reset_pterodactyl() {
    msg "$C_RED" "PERINGATAN: Ini akan MENGHAPUS SEMUA tema dan addon kustom."
    read -p "Anda yakin ingin mereset Pterodactyl ke kondisi awal? [y/N]: " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        msg "$C_YELLOW" "Reset dibatalkan."
        return
    fi

    cd "$PTERO_DIR"
    php artisan down
    run_with_spinner "Mengunduh file panel terbaru..." "curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv"
    
    chmod -R 755 storage/* bootstrap/cache
    run_with_spinner "Menginstall dependensi composer..." composer install --no-dev --optimize-autoloader
    
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data "${PTERO_DIR}/*"
    php artisan up
    msg "$C_GREEN" "Pterodactyl berhasil direset ke kondisi awal."
}

install_dependencies() {
    msg "$C_BLUE" "Menginstall/Update dependensi..."
    apt-get update -qq >/dev/null
    apt-get install -y -qq nodejs npm zip unzip git curl wget
    npm i -g yarn >/dev/null 2>&1
    
    # Install/Update Blueprint
    cd "$PTERO_DIR"
    run_with_spinner "Mengunduh Blueprint Framework..." "curl -sL https://github.com/BlueprintFramework/framework/releases/latest/download/blueprint.sh -o blueprint.sh"
    chmod +x blueprint.sh
    run_with_spinner "Menjalankan inisialisasi Blueprint..." ./blueprint.sh
    
    run_ptero_build
    msg "$C_GREEN" "Semua dependensi telah terinstall."
}

# --- Main Execution Block ---

main() {
    check_root
    load_config
    # Leaving dependency check commented out as option 11 handles it.
    # check_dependencies

    while true; do
        display_header
        display_menu
        read -p "Pilih Opsi: " OPTION

        clear
        display_header

        case "$OPTION" in
            1)  install_elysium ;;
            2)  install_blueprint_plugin "nebula" "nebulaptero.zip" ;;
            3)  install_blueprint_plugin "slate" "Slate-v1.0.zip" ;;
            4)  msg "$C_YELLOW" "Fitur 'Auto Suspend' masih dalam pengembangan di skrip ini." ;; # Placeholder
            5)  msg "$C_YELLOW" "Fitur 'Google Analytics' masih dalam pengembangan di skrip ini." ;; # Placeholder
            6)  msg "$C_YELLOW" "Fitur 'Enigma Remake' masih dalam pengembangan di skrip ini." ;; # Placeholder
            7)  change_background ;;
            8)  reset_background ;;
            9)  reset_pterodactyl ;;
            10) install_blueprint_plugin "cookies" "cookies.zip" ;;
            11) install_dependencies ;;
            12) 
                if [[ "$DISABLE_ANIMATIONS" -eq 1 ]]; then
                    DISABLE_ANIMATIONS=0
                    msg "$C_GREEN" "Animasi diaktifkan."
                else
                    DISABLE_ANIMATIONS=1
                    msg "$C_YELLOW" "Animasi dimatikan."
                fi
                save_config
                ;;
            13) 
                msg "$C_BLUE" "Terima kasih telah menggunakan installer ini. Sampai jumpa!"
                exit 0 
                ;;
            14) remove_blueprint_plugin "nebula" ;;
            15) remove_blueprint_plugin "slate" ;;
            16) remove_blueprint_plugin "cookies" ;;
            *) 
                msg "$C_RED" "Pilihan tidak valid. Silakan coba lagi." ;;
        esac
        
        msg "$C_YELLOW" "\nTekan [ENTER] untuk kembali ke menu utama."
        read -p ""
    done
}

# Run the main function
main
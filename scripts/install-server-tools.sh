#!/usr/bin/env bash
# Install Composer, Node.js 26 LTS, and Docker on the dev server.
# Choose all of them, or a list such as "1, 2".
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    printf 'Run as root: sudo %s\n' "$0" >&2
    exit 1
fi

if [[ ! -t 0 ]]; then
    printf 'This script needs an interactive terminal.\n' >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

install_composer=0
install_node=0
install_docker=0

ask_selection() {
    cat <<'EOF'

Install server tools

  1) Composer
  2) Node.js 26 (current LTS)
  3) Docker

Enter all, or the numbers to install (example: 1, 2):
EOF
    local answer normalized token
    read -r answer
    normalized="${answer,,}"
    normalized="${normalized//,/ }"

    if [[ -z "${normalized// }" ]]; then
        printf 'Nothing selected.\n' >&2
        return 1
    fi

    if [[ "$normalized" == "all" ]]; then
        install_composer=1
        install_node=1
        install_docker=1
        return 0
    fi

    for token in $normalized; do
        case "$token" in
            1) install_composer=1 ;;
            2) install_node=1 ;;
            3) install_docker=1 ;;
            *)
                printf 'Unknown choice: %s. Use all, or numbers 1, 2, and 3.\n' "$token" >&2
                install_composer=0
                install_node=0
                install_docker=0
                return 1
                ;;
        esac
    done
}

apt_update_once() {
    if [[ "${apt_updated:-0}" -eq 0 ]]; then
        apt-get update
        apt_updated=1
    fi
}

install_composer_pkg() {
    if command -v composer >/dev/null 2>&1; then
        printf 'Composer is already installed: %s\n' "$(composer --version)"
        return 0
    fi

    apt_update_once
    apt-get install -y php-cli unzip curl ca-certificates

    local expected actual
    expected="$(curl -fsSL https://composer.github.io/installer.sig)"
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
    actual="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
    if [[ "$expected" != "$actual" ]]; then
        rm -f /tmp/composer-setup.php
        printf 'Composer installer checksum did not match.\n' >&2
        exit 1
    fi

    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
    printf 'Installed %s\n' "$(composer --version)"
}

install_node_pkg() {
    if command -v node >/dev/null 2>&1; then
        local major
        major="$(node -p "process.versions.node.split('.')[0]")"
        if [[ "$major" -ge 26 ]]; then
            printf 'Node.js is already installed: %s\n' "$(node --version)"
            return 0
        fi
        printf 'Replacing Node.js %s with Node.js 26 LTS.\n' "$(node --version)"
    fi

    apt_update_once
    apt-get install -y ca-certificates curl gnupg
    mkdir -p /etc/apt/keyrings
    rm -f /etc/apt/keyrings/nodesource.gpg
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    printf 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_26.x nodistro main\n' \
        > /etc/apt/sources.list.d/nodesource.list
    apt_updated=0
    apt_update_once
    apt-get install -y nodejs
    printf 'Installed Node.js %s and npm %s\n' "$(node --version)" "$(npm --version)"
}

install_docker_pkg() {
    if command -v docker >/dev/null 2>&1; then
        printf 'Docker is already installed: %s\n' "$(docker --version)"
    else
        apt_update_once
        apt-get install -y ca-certificates curl
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sh /tmp/get-docker.sh
        rm -f /tmp/get-docker.sh
        printf 'Installed %s\n' "$(docker --version)"
    fi

    systemctl enable --now docker

    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
        usermod -aG docker "$SUDO_USER"
        printf 'Added %s to the docker group. Log out and back in before using docker without sudo.\n' "$SUDO_USER"
    fi
}

until ask_selection; do
    :
done

if [[ "$install_composer" -eq 1 ]]; then
    install_composer_pkg
fi
if [[ "$install_node" -eq 1 ]]; then
    install_node_pkg
fi
if [[ "$install_docker" -eq 1 ]]; then
    install_docker_pkg
fi

printf 'Done.\n'

#!/bin/bash
# Install Apache, MySQL, PHP 8.4, and phpMyAdmin on a fresh Ubuntu or Debian host.
# phpMyAdmin stays interactive so you can pick Apache and set the database password.
set -e

if [[ ! -r /etc/os-release ]] || ! grep -Eqi 'ubuntu|debian' /etc/os-release; then
    echo "This script supports Ubuntu and Debian only." >&2
    exit 1
fi

echo "=== 1. Updating system & adding Ondřej PHP 8.4 repository ==="
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates lsb-release curl

# ppa:ondrej/php is frozen. Ubuntu and Debian now get PHP from packages.sury.org.
# https://packages.sury.org/php/README.txt
if compgen -G "/etc/apt/sources.list.d/*ondrej*php*" > /dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common
    sudo add-apt-repository --remove -y ppa:ondrej/php
fi

sudo curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
sudo dpkg -i /tmp/debsuryorg-archive-keyring.deb
echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
sudo rm -f /tmp/debsuryorg-archive-keyring.deb
sudo apt update

echo "=== 2. Installing Apache & configuring firewall ==="
sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow in "Apache Full"
fi

echo "=== 3. Installing MySQL Server ==="
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server
sudo systemctl enable --now mysql

echo "=== 4. Installing PHP 8.4 + Math, PDF & CSV support modules ==="
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    php8.4 libapache2-mod-php8.4 php8.4-cli php8.4-common \
    php8.4-mysql \
    php8.4-bcmath php8.4-gmp \
    php8.4-gd php8.4-imagick \
    php8.4-curl php8.4-intl php8.4-mbstring php8.4-xml php8.4-zip php8.4-opcache

# Ensure PHP 8.4 is active in Apache and CLI
sudo a2dismod php* 2>/dev/null || true
sudo a2enmod php8.4
sudo update-alternatives --set php /usr/bin/php8.4

echo "=== 5. Installing phpMyAdmin (Interactive) ==="
# Interactive so you can select 'apache2' and set your MySQL password
sudo apt install -y phpmyadmin

echo "=== 6. Enabling phpMyAdmin & restarting Apache ==="
sudo a2enconf phpmyadmin || true
sudo systemctl restart apache2

echo "=== Installation Complete! ==="
php -v
echo "Apache:     http://$(hostname -I | awk '{print $1}')"
echo "phpMyAdmin: http://$(hostname -I | awk '{print $1}')/phpmyadmin"

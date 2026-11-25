# aws-scripts

Bash scripts for a fresh AWS instance. Copy one over, then run it there.

These scripts target **Ubuntu and Debian**. Amazon Linux uses a different package manager.

## Copy a script onto the instance

From this laptop, with the instance's key and public DNS or IP:

```bash
scp -i ~/.ssh/your-key.pem scripts/install-lamp-php84.sh ubuntu@YOUR_HOST:~/
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_HOST
chmod +x install-lamp-php84.sh
./install-lamp-php84.sh
```

Or download it on the instance after this repo is public:

```bash
curl -fsSL -o install-lamp-php84.sh \
  https://raw.githubusercontent.com/Wandji69/aws-scripts/main/scripts/install-lamp-php84.sh
chmod +x install-lamp-php84.sh
./install-lamp-php84.sh
```

Open ports **80** and **443** in the instance security group before you expect a browser to reach Apache. `ufw`, when it is installed, is allowed for "Apache Full" by the LAMP script. A security group still blocks traffic the firewall has allowed.

## Scripts

| Script | What it does |
| --- | --- |
| `scripts/install-lamp-php84.sh` | Apache, MySQL, PHP 8.4 (Ondřej Surý), and phpMyAdmin |

### `install-lamp-php84.sh`

- Ubuntu and Debian both use [packages.sury.org](https://packages.sury.org/php/README.txt). The `ppa:ondrej/php` archive is frozen, including on Ubuntu Resolute. If that PPA is already on the machine, the script removes it.
- PHP modules include MySQL, bcmath, gmp, gd, imagick, curl, intl, mbstring, xml, zip, and opcache.
- The phpMyAdmin package step is **interactive**. Choose `apache2` when it asks for the web server, and set the MySQL application password when prompted.
- When it finishes it prints the instance IP, Apache, and `/phpmyadmin`.

phpMyAdmin listens on the same host as the site. Restrict who can reach `/phpmyadmin` (security group, VPN, or HTTP auth) before you leave the instance up.

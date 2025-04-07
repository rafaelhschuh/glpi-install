# 📦 GLPI Installation on Debian

This guide explains how to install and configure **GLPI** on Debian. You can choose between **automated** or **manual** installation.

---

## ⚡ Automated Installation

Run the command below to install GLPI automatically:

```bash
sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/rafaelhschuh/glpi-install/refs/heads/main/auto-install.sh)"
```

---

## 🧰 Manual Installation

Follow the steps below for manual installation.

### 1️⃣ Become root

```bash
sudo su
```

---

### 2️⃣ Update the system

```bash
apt update && apt upgrade -y
```

---

### 3️⃣ Install required packages

```bash
apt install -y apache2 mariadb-server php php-{cli,apache2,gd,imap,ldap,mysql,xml,mbstring,xmlrpc,zip,bcmath,intl,redis} wget unzip
```

---

### 4️⃣ (Optional) Configure timezone and NTP

```bash
apt install -y openntpd && systemctl enable openntpd && systemctl start openntpd
dpkg-reconfigure tzdata
```

---

### 5️⃣ Secure MariaDB

```bash
mysql_secure_installation
```

---

### 6️⃣ Create database and user

```bash
mysql -u root -p <<EOF
CREATE DATABASE glpi CHARACTER SET utf8mb4;
CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpiuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF
```

---

### 7️⃣ Download and extract GLPI

```bash
cd /tmp
wget -O glpi.tgz https://github.com/glpi-project/glpi/releases/download/10.0.15/glpi-10.0.15.tgz
tar -zxvf glpi.tgz
mv glpi /var/www/html/glpi
```

---

### 8️⃣ Set correct permissions

```bash
chown -R www-data:www-data /var/www/html/glpi
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;
```

---

### 9️⃣ Configure Apache VirtualHost

```bash
cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName YOUR_DOMAIN_OR_IP
    DocumentRoot /var/www/html/glpi/public
    <Directory /var/www/html/glpi/public>
        AllowOverride All
        Options -Indexes
        Require all granted
    </Directory>
</VirtualHost>
EOF
```

```bash
cat > /etc/apache2/conf-available/glpi-web.conf << EOF
<Directory "/var/www/html/glpi/public/">
    AllowOverride All
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
    Options -Indexes
    Options -Includes -ExecCGI
    Require all granted
    <IfModule mod_php7.c>
        php_value max_execution_time 600
        php_value always_populate_raw_post_data -1
    </IfModule>
    <IfModule mod_php8.c>
        php_value max_execution_time 600
        php_value always_populate_raw_post_data -1
    </IfModule>
</Directory>
EOF
```

---

### 🔄 Enable modules and restart Apache

```bash
a2enmod rewrite
a2ensite glpi.conf
a2enconf glpi-web.conf
systemctl restart apache2
systemctl reload apache2
```

---

### ✅ Finish via browser

Access the installer:

```
http://YOUR_DOMAIN_OR_IP/install/install.php
```

Complete the setup via the web interface, then remove the installer:

```bash
rm -rf /var/www/html/glpi/install
```

---

## ❌ Automated Removal

To uninstall GLPI and related dependencies:

```bash
sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/rafaelhschuh/glpi-install/refs/heads/main/auto-remove.sh)"
```


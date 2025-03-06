#!/bin/bash

# Solicita o IP/Domínio e senha do banco de dados
echo "Informe o IP ou Domínio para acessar o GLPI:"
read SERVER_NAME
echo "Informe a senha para o usuário do banco de dados GLPI:"
read DB_PASSWORD

# Atualização do sistema
apt update && apt upgrade -y

# Configurar data e hora
apt install -y openntpd && systemctl enable openntpd && systemctl start openntpd
dpkg-reconfigure tzdata

# Instalação dos pacotes necessários
apt install -y apache2 mariadb-server php php-cli php-gd php-imap php-ldap php-mysql php-xml php-mbstring php-xmlrpc php-zip php-bcmath php-intl php-bz2 php-redis wget unzip curl php-curl
# Configuração segura do MariaDB
mysql_secure_installation

# Criação do banco de dados e usuário
mysql -u root -p <<EOF
CREATE DATABASE glpi CHARACTER SET utf8mb4;
CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpiuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Download e extração do GLPI
cd /tmp
wget -O glpi.tgz https://github.com/glpi-project/glpi/releases/download/10.0.15/glpi-10.0.15.tgz
tar -zxvf glpi.tgz
mv glpi /var/www/html/glpi

# Ajuste de permissões
chown -R www-data:www-data /var/www/html/glpi
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;

# Criação do VirtualHost do Apache
cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName $SERVER_NAME
    DocumentRoot /var/www/html/glpi/public
    <Directory /var/www/html/glpi/public>
        AllowOverride All
        Options -Indexes
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Configuração do diretório público do GLPI
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

# Ativação das configurações
a2enmod rewrite
a2ensite glpi.conf
a2enconf glpi-web.conf
systemctl restart apache2

# Exibe mensagem final
echo "Instalação concluída! Acesse http://$SERVER_NAME/install/install.php para finalizar a configuração pelo navegador."
echo "Banco de dados: localhost || Usuário: glpiuser || Senha: $DB_PASSWORD"
echo "Lembre-se de remover o diretório de instalação após concluir a configuração: rm -rf /var/www/html/glpi/install"


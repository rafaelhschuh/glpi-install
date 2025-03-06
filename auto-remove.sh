#!/bin/bash

# Solicita confirmação do usuário
echo "Tem certeza que deseja remover o GLPI e todas as suas configurações? (s/n)"
read -r CONFIRM
if [[ "$CONFIRM" != "s" ]]; then
    echo "Remoção cancelada."
    exit 1
fi

# Parar serviços relacionados
systemctl stop apache2
systemctl stop mariadb

# Remover banco de dados e usuário do GLPI
mysql -u root -p <<EOF
DROP DATABASE glpi;
DROP USER 'glpiuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Remover diretórios do GLPI
rm -rf /var/www/html/glpi
rm -rf /etc/apache2/sites-available/glpi.conf
rm -rf /etc/apache2/conf-available/glpi-web.conf

# Desativar configurações do Apache
a2dissite glpi.conf
a2disconf glpi-web.conf
systemctl restart apache2

# Remover pacotes instalados
apt remove --purge -y apache2 mariadb-server php php-cli php-gd php-imap php-ldap php-mysql php-xml php-mbstring php-xmlrpc php-zip php-bcmath php-intl php-redis wget unzip php-bz2 php-curl
apt autoremove -y

# Exibe mensagem final
echo "GLPI e todas as suas configurações foram removidos com sucesso."


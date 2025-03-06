# Guia de Instalação do GLPI no Debian

Este documento reúne todos os passos necessários para instalar o GLPI no Debian, incluindo a configuração do Apache, MariaDB, PHP e ajustes de permissões. 

# Instalação Automatizada

Execute o seguinte comando no terminal e siga as instruções
```bash
sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/rafaelhschuh/glpi-install/refs/heads/main/auto-install.sh)"
```
---

# Instalação Manual
---
## Antes, acesse o terminal de root:
```bash
sudo su
```
---

## Passo 1: Atualização do Sistema

Atualize os pacotes do sistema.

```bash
apt update && apt upgrade -y
```

---

## Passo 2: Instalação dos Pacotes Essenciais

Instale o Apache, MariaDB, PHP e demais dependências.

```bash
apt install -y apache2 mariadb-server php php-{cli,apache2,gd,imap,ldap,mysql,xml,mbstring,xmlrpc,zip,bcmath,intl,redis} wget unzip
```

---

## Passo 3: Configuração do Fuso Horário e NTP (Opcional)

Configure o fuso horário e, se desejar, instale o NTP para sincronização de hora.

```bash
apt install -y openntpd && systemctl enable openntpd && systemctl start openntpd
dpkg-reconfigure tzdata
```

---

## Passo 4: Configuração Segura do MariaDB

Execute o script de segurança do MariaDB.

```bash
mysql_secure_installation
```

---

## Passo 5: Criação do Banco de Dados e Usuário no MariaDB

Crie o banco de dados e o usuário para o GLPI.

```bash
mysql -u root -p <<EOF
CREATE DATABASE glpi CHARACTER SET utf8mb4;
CREATE USER 'glpiuser'@'localhost' IDENTIFIED BY 'SUA_SENHA';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpiuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF
```

---

## Passo 6: Download e Extração do GLPI

Baixe a versão desejada do GLPI e extraia os arquivos no diretório do Apache.

```bash
cd /tmp
wget -O glpi.tgz https://github.com/glpi-project/glpi/releases/download/10.0.15/glpi-10.0.15.tgz
tar -zxvf glpi.tgz
mv glpi /var/www/html/glpi
```

---

## Passo 7: Ajuste de Permissões dos Arquivos do GLPI

Configure as permissões corretas para os arquivos do GLPI.

```bash
chown -R www-data:www-data /var/www/html/glpi
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;
```

---

## Passo 8: Configuração do VirtualHost do Apache para o GLPI

Crie um VirtualHost para que o GLPI seja acessível pelo domínio ou IP.

```bash
cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerName SEU_DOMINIO_OU_IP
    DocumentRoot /var/www/html/glpi/public
    <Directory /var/www/html/glpi/public>
        AllowOverride All
        Options -Indexes
        Require all granted
    </Directory>
</VirtualHost>
EOF
```


Crie um arquivo de configuração para o diretório público do GLPI e habilite-o.

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

## Passo 9: Ativação do VirtualHost e Reinicialização do Apache

```bash
a2enmod rewrite
a2ensite glpi.conf
a2enconf glpi-web.conf
systemctl restart apache2
systemctl reload apache2
```

*Nota: Se desejar utilizar o nome "glpi-web.conf", adapte o comando `a2enconf` para utilizar esse nome.*

---

## Passo 11: Finalização

Após configurar o Apache, acesse o GLPI via navegador (http://SEU_DOMINIO_OU_IP/install/install.php) e conclua a instalação pela interface web. 

Ao finalizar, remova o diretório de instalação.

```bash
rm -rf /var/www/html/glpi/install
```

---

# REMOÇÃO Automatizada

Execute o seguinte comando no terminal para remover o glpi e suas dependências
```bash
sudo bash -c "$(wget -qLO - https://raw.githubusercontent.com/rafaelhschuh/glpi-install/refs/heads/main/auto-remove.sh)"



Este README.md reúne os passos para uma instalação funcional do GLPI no Debian. Certifique-se de ajustar os valores conforme necessário e consulte a documentação oficial do GLPI para detalhes adicionais e atualizações.

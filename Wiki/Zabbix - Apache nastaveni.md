Apache zapnuti SSL
----------------------
1. Vytvor adresar
```
sudo mkdir /etc/apache2/ssl
```

3. Vytvoreni selfsigned certifikatu
```
	sudo openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -out /etc/apache2/ssl/server.crt -keyout /etc/apache2/ssl/server.key
```
4. zapnuti podpory SSL na Apache serveru
```
	sudo a2enmod ssl
```
5. Vytvoreni symbolicke
```
	sudo ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/000-default-ssl.conf
```

6. Uprava config souboru /etc/apache2/sites-enabled/000-default-ssl.conf
```
	SSLCertificateFile    /etc/apache2/ssl/server.crt
	SSLCertificateKeyFile /etc/apache2/ssl/server.key
```

7. Restart Apache

Presmerovani na HTTPs
----------------------
1. Zapnut rewrite modulu
```
	sudo a2enmod rewrite
```

3. Pridat presmerovani do configu 000-default.conf do 80 virtualhost
```
	nano /etc/apache2/sites-enabled/000-default.conf
```
```
	RewriteEngine On
	RewriteCond %{HTTPS} off
	RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI}
```

Zapnuti HTST
------------
1. Zapnuti modulu
```
	sudo a2enmod headers
```
3. Pridani konfigurace do etc/apache2/sites-enabled/000-default-ssl.conf
```
	nano /etc/apache2/sites-enabled/000-default-ssl.conf
```
```
	Header set Strict-Transport-Security "max-age=31536000"
```
Vypnuti signature
-----------------
1. Pridat konfiguraci do /etc/apache2/conf-enabled/security.conf
```
	nano /etc/apache2/conf-enabled/security.conf
```
```
	ServerSignature Off 
	ServerTokens Prod
```

Zabbix na root webu
----------------------
1. Editovat /etc/apache2/sites-available/000-default.conf i SSL
```
	nano /etc/apache2/sites-available/000-default.conf
	nano /etc/apache2/sites-available/000-default-ssl.conf
```
```
	/var/www/html zmenit na /usr/share/zabbix
```
	
3. Editovat /etc/apache2/conf-available/zabbix.conf
```
	nano /etc/apache2/conf-available/zabbix.conf
```
Zakomentovat # Alias /zabbix /usr/share/zabbix


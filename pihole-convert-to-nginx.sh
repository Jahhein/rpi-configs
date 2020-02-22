#!/bin/bash

service lighttpd stop
apt-get -y install nginx php7.0-fpm php7.0-zip apache2-utils
systemctl disable lighttpd
systemctl enable php7.0-fpml  2
systemctl enable nginx

echo "edit /etc/nginx/sites-available/default to:"

cat << EOF
  server {
      listen 80 default_server;
      listen [::]:80 default_server;

      root /var/www/html;
      server_name _;
      autoindex off;

      index pihole/index.php index.php index.html index.htm;

      location / {
          expires max;
          try_files $uri $uri/ =404;
      }

      location ~ \.php$ {
          include fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
          fastcgi_pass unix:/run/php/php7.0-fpm.sock;
          fastcgi_param FQDN true;
          auth_basic "Restricted"; # For Basic Auth
          auth_basic_user_file /etc/nginx/.htpasswd; # For Basic Auth
      }

      location /*.js {
          index pihole/index.js;
          auth_basic "Restricted"; # For Basic Auth
          auth_basic_user_file /etc/nginx/.htpasswd; # For Basic Auth
      }

      location /admin {
          root /var/www/html;
          index index.php index.html index.htm;
          auth_basic "Restricted"; # For Basic Auth
          auth_basic_user_file /etc/nginx/.htpasswd; # For Basic Auth
      }

      location ~ /\.ht {
          deny all;
      }
  }
EOF

htpasswd -c /etc/nginx/.htpasswd exampleuser
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/www/html chmod -R 755 /var/www/html
service php7.0-fpm start
service php7.0-fpm start service nginx start

cat << EOF
  ## Optional configuration¶

      If you want to use your custom domain to access admin page (e.g.: http://mydomain.internal/admin/settings.php instead of http://pi.hole/admin/settings.php),
          make sure mydomain.internal is assigned to server_name in /etc/nginx/sites-available/default. E.g.: server_name mydomain.internal;

      If you want to use block page for any blocked domain subpage (aka Nginx 404), add this to Pi-hole server block in your Nginx configuration file:

      ``
      error_page 404 /pihole/index.php;
      ``

      When using nginx to serve Pi-hole, Let's Encrypt can be used to directly configure nginx. Make sure to use your hostname instead of _ in server_name _; line above.

      ``
      add-apt-repository ppa:certbot/certbot
      apt-get install certbot python-certbot-nginx

      certbot --nginx -m "$email" -d "$domain" -n --agree-tos --no-eff-email
      ``
EOF

# Este script permite automatizar la creación de usuarios de ftp, la creación
# de de una base de datos y de un sitio web. Se introduce el nombre del usuario
# de ftp ($1) y el nombre del nuevo dominio ($2).

#! /bin/sh

menu(){
    echo "Menú"
    echo " 1. Agregar usuario"
    echo " 2. borrar usuario"
    echo " "
    read -p "Introduzca una opción: " opcion
    while [ "$opcion" -ne 1 -a "$opcion" -ne 2 ]
    do
        echo "Error. Debe ser una de las 2 siguientes opciones"
        echo "Menú"
        echo " 1. Agregar usuario"
        echo " 2. Borraar usuario"
        echo " "
        read -p "Introduzca una opción: " opcion
    done
    acciones
}

acciones(){
    if [ "$opcion" -eq 1 ]
    then
        agregarUser
    else
        echo "borrarUser"
    fi
}

agregarUser(){
    read -p "Introduce el nombre del usuario: " user_name
    pssw=$(openssl rand -base64 5)
    useradd $user_name 
    echo $pssw | chpasswd
    echo "La contraseña del nuevo usuario es " $pssw   
    mkdir /usr/share/nginx/html/$user_name
    chown -R nginx:nginx /usr/share/nginx/html/$user_name 
    chcon -t http_sys_content_t /usr/share/nginx/html/$user_name -R   
    read -p "Introduce el nombre del nuevo sitio web: " prefijo_dominio
    touch /etc/nginx/conf.d/$prefijo_dominio.conf
    crearFichConfNignx $user_name $prefijo_dominio
    systemctl restart php-fpm
    systemctl restart nginx
}

crearFichConfNignx(){
    url=$2.paloma.gonzalonazareno.org
    echo '''server {
    listen	 80;
    server_name ' $url';
    rewrite ^ https://$server_name$request_uri permanent;
} 
server {
    listen 443 ssl;
    server_name ' $url';
    ssl on;
    ssl_certificate /etc/pki/tls/certs/paloma.gonzalonazareno.org.crt;
    ssl_certificate_key /etc/pki/tls/private/gonzalonazareno.pem;

    root   /usr/share/nginx/html/'$1';
    index index.php index.html index.htm;
    location / {
        try_files $uri $uri/ /index.php?$args;
         autoindex on;
    }

    location ~ \.php$ {
    try_files $uri =404;
    fastcgi_pass unix:/var/run/php-fpm/www.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
    }
}
    ''' > /etc/nginx/conf.d/$2.conf
}

menu

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
        borrar
    fi
}

agregarUser(){
    read -p "Introduce el nombre del usuario: " name
    user_name="user_$name"
    comprobarUser 1
    sudo mkdir /usr/share/nginx/html/$user_name
    sudo chown -R nginx:nginx /usr/share/nginx/html/$user_name 
    sudo chcon -t httpd_sys_content_t /usr/share/nginx/html/$user_name -R
    read -p "Introduce el nombre del nuevo sitio web: " prefijo_dominio
    crearFichConfNignx $user_name $prefijo_dominio
    sudo systemctl restart php-fpm
    sudo systemctl restart nginx
    baseDeDatos
    dns
    echo "---------------+-----------------------------------------------------"
    echo "USUARIO FTP    |" $user_name
    echo "---------------+-----------------------------------------------------"
    echo "CONTRASEÑA     |" $pssw
    echo "---------------+-----------------------------------------------------"
    echo "USUARIO MYSQL  |" $user_db 
    echo "---------------+-----------------------------------------------------"
    echo "CONTRASEÑA     |" $pass_db
    echo "---------------+-----------------------------------------------------"
    echo "BASE DE DATOS  |" $db_user
    echo "---------------+-----------------------------------------------------"
    echo "SITIO WEB      |" $prefijo_dominio
    echo "---------------+-----------------------------------------------------"
}

comprobarUser(){
    filtrado=$(cut -d: -f1 /etc/passwd | grep "^$user_name$")
    if [ $1 -ne 1 ]
    then
        while [ "$user_name" != "$filtrado" ]
        do
            echo "Error. El usuario no existe"
            read -p "Introduce el nombre del usuario que desea eliminar: " name
            user_name="user_$name"
            filtrado=$( cut -d: -f1 /etc/passwd | grep "^$user_name$")
        done
        sudo userdel $user_name
    else
        while [ "$user_name" == "$filtrado" ]
        do
            echo "Error. El usuario ya existe"
            read -p "Introduce el nombre del usuario: " name
            user_name="user_$name"
            filtrado=$( cut -d: -f1 /etc/passwd | grep "^$user_name$")
        done
        pssw=$(openssl rand -base64 5)
        sudo useradd $user_name -M
        echo $pssw | sudo passwd --stdin $user_name
    fi
}

dns(){
    reg_dns="sudo sed -i '\$a $prefijo_dominio IN CNAME salmorejo' /var/cache/bind/db.paloma.gonzalonazareno.org"
    ssh debian@croqueta $reg_dns
    ssh debian@croqueta sudo rndc reload
}

baseDeDatos(){
    user_db="my_$user_name"
    db_user="db_$user_name"
    pass_db=$(openssl rand -base64 5)
    crear_usuario='sudo mysql -e "CREATE USER \"'$user_db'\"@\"%\" IDENTIFIED BY \"'$pass_db'\";"'
    ssh ubuntu@tortilla $crear_usuario
    crear_db='sudo mysql -e "CREATE DATABASE '$db_user';"'
    ssh ubuntu@tortilla $crear_db
    privilegio='sudo mysql -e "GRANT ALL PRIVILEGES ON '$db_user'.* TO \"'$user_db'\"@\"%\""'
    ssh ubuntu@tortilla $privilegio
}

crearFichConfNignx(){
    url=$2.paloma.gonzalonazareno.org
    echo '''
    server {
    listen       80;
    server_name '$url';
    rewrite ^ https://$server_name$request_uri permanent;
}

server {
    listen 443 ssl;
    server_name  '$url';
    ssl on;
    ssl_certificate /etc/pki/tls/certs/paloma.gonzalonazareno.org.crt;
    ssl_certificate_key /etc/pki/tls/private/gonzalonazareno.pem;


    # note that these lines are originally from the "location /" block
    root   /usr/share/nginx/html/'$1';
    index index.php index.html index.htm info.php;

    location / {
	try_files $uri $uri/ /index.php?$args;
	autoindex on;
    disable_symlinks if_not_owner;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
    ''' | sudo tee /etc/nginx/conf.d/$1.conf > /dev/null
}

borrar (){
    read -p "Introduce el nombre del usuario que desea borrar: " name
    user_name="user_$name"
    comprobarUser 0
    borrarDNS
    borrarMYSQL
    sudo rm /etc/nginx/conf.d/$user_name.conf
    sudo rm -r /usr/share/nginx/html/$user_name
}

borrarDNS(){
    web=$(sudo sed -n 4p /etc/nginx/conf.d/$user_name.conf | cut -d " " -f6 | cut -d "." -f1)
    borrarRegDNS="sudo sed -i '/$web IN CNAME salmorejo/d' /var/cache/bind/db.paloma.gonzalonazareno.org"
    ssh debian@croqueta $borrarRegDNS
    ssh debian@croqueta 'sudo rndc reload'
}

borrarMYSQL(){
    user_db="my_$user_name"
    db_user="db_$user_name" 
    
    borrar_usuario='sudo mysql -e "DROP USER '$user_db';"'
    ssh ubuntu@tortilla $borrar_usuario

    borrar_db='sudo mysql -e "DROP DATABASE '$db_user';"'
    ssh ubuntu@tortilla $borrar_db
}

menu

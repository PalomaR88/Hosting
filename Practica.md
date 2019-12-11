# Creación de un hosting
Queremos que diferentes usuarios, puedan gestionar una página web en vuestro servidor que esté gestionada por medio de un FTP. También se creará una base de datos para cada usuario.

> Por ejemplo, el usuario josedom quiere hacer una página cuyo nombre será servicios:
- La página que vamos a crear será accesible en https://servicios.tunombre.gonzalonazareno.org.
- Se creará un usuario user_josedom, que tendrá una contraseña, para que accediendo a ftp.tunombre.gonzalonazareno.org, pueda gestionar los ficheros de su página web.
- Se creará un usuario en la base de datos llamado myjosedom. Este usuario tendrá una contraseña distinta a la del usuario del servidor FTP.
- Se creará una bases de datos para el usuario anteriormente creado. Para que los usuarios gestionen su base de datos se puede instalar la aplicación phpmyadmin a la que se accederá con la URL https://sql.tunombre.gonzalonmazareno.org.

Tarea: Configura manualmente los distintos servicios para crear un nuevo usuario que gestione su propia página web y tenga una base de datos a su disposición. Instala un CMS.
Mejora 1: Modifica la configuración del sistema para que se usen usuarios virtuales para el acceso por FTP, cuya información este guardada en vuestro directorio ldap.
Mejora 2: Realiza un script que automatice la creación/borrado de nuevos usuarios en el hosting.

### Instalación de proftpd
Se instalará en una máquina centos8.
Se actualiza centos:
~~~
[centos@salmorejo-3 ~]$ sudo dnf update
~~~

Se instala el repositorio epel:
~~~
[centos@salmorejo-3 ~]$ cd /tmp
[centos@salmorejo-3 tmp]$ wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
[centos@salmorejo-3 tmp]$ sudo dnf install epel-release-latest-7.noarch.rpm 
~~~

Se descarga el paquete:
~~~

[centos@salmorejo-3 tmp]$ wget http://mirror.centos.org/centos/7/os/x86_64/Packages/GeoIP-1.5.0-14.el7.x86_64.rpm
[centos@salmorejo-3 tmp]$ ls
[centos@salmorejo-3 tmp]$ sudo dnf install GeoIP-1.5.0-14.el7.x86_64.rpm
~~~

Se descarga la librería:
~~~
[centos@salmorejo-3 tmp]$ wget http://mirror.centos.org/centos/7/os/x86_64/Packages/tcp_wrappers-libs-7.6-77.el7.x86_64.rpm
[centos@salmorejo-3 tmp]$ sudo dnf install tcp_wrappers-libs-7.6-77.el7.x86_64.rpm 
~~~

Por último se instala proftpd:
~~~
[centos@salmorejo-3 tmp]$ sudo dnf install proftpd
~~~

Una vez instalado ya se puede iniciar el servicio proftpd:
~~~
[centos@salmorejo-3 tmp]$ sudo systemctl start proftpd
[centos@salmorejo-3 tmp]$ sudo systemctl enable proftpd
~~~

### Configuración de proftpd en Centos8
Se habilita el puerto de FTP en el cortafuegos:
~~~
[centos@salmorejo-3 tmp]$ sudo firewall-cmd --add-service=ftp --permanent --zone=public
[centos@salmorejo-3 tmp]$ sudo firewall-cmd --reload
~~~

### Creación de usuario del sistema
Se crea un usuario de Centos para que use más tarde FTP:
~~~
[centos@salmorejo-3 tmp]$ sudo useradd user_paloma
~~~

Se añade una contraseña:
~~~
[centos@salmorejo-3 tmp]$ sudo passwd user_paloma
~~~

### Creación de un virtual host
Se va a crear un sitio web con la dirección: https://space.paloma.gonzalonazareno.org.

Se crea el fichero /etc/nginx/conf.d/user_palomaspace.conf para la configuración de nginx:
~~~
server {
    listen	 80;
    server_name  space.paloma.gonzalonazareno.org;
    rewrite ^ https://$server_name$request_uri permanent;
}

server {
    listen 443 ssl;
    server_name  space.paloma.gonzalonazareno.org;
    ssl on;
    ssl_certificate /etc/pki/tls/certs/paloma.gonzalonazareno.org.crt;
    ssl_certificate_key /etc/pki/tls/private/gonzalonazareno.pem;

    # note that these lines are originally from the "location /" block
    root   /usr/share/nginx/html/user_paloma;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
~~~

A continuación se crea un directorio para el usuario en la ruta indicada en el documentRoot con un .html de prueba:
~~~
[centos@salmorejo-3 tmp]$ cd /usr/share/nginx/html/
[centos@salmorejo-3 html]$ sudo mkdir user_paloma
[centos@salmorejo-3 html]$ sudo touch user_paloma/index.html
[centos@salmorejo-3 html]$ sudo chown -R nginx:nginx user_paloma/ 
~~~

![imagen_de_prueba](image/aimg.png)

### Configuración de ftp
Se configura el fichero /etc/proftpd.conf:
~~~
DefaultRoot                     /usr/share/nginx/html/%u
~~~

Y se inicia el sistema proftpd:
~~~
[centos@salmorejo-3 html]$ sudo systemctl start proftpd
~~~

Para ver su correcto funcionamiento se añaden las siguientes líneas a /etc/nginx/conf.d/user_palomaspace.conf para que el servidor web permita listar los documentos:
~~~
    location / {
        try_files $uri $uri/ /index.php?$args;
        autoindex on;
        disable_symlinks if_not_owner;
    }
~~~

> Para hacer las comprobaciones hay que instalar el paquete ftp.

##### Comprobación en local
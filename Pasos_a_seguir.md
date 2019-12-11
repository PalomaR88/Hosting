# Pasos a seguir
#### 0. Instalar y configurar:
- proftpd
- phpmyadmin
- Dos nombres: ftp y sql.
#### 1. Crear el usuario 
Puede ser:
- Usuario del sistema
- LDAP
#### 2. Crear un virtual host en el servidor web 
- Se hace coincidir el documentRoot con el DefaultRoot.
> Ejemplo:
DocumentRoot /var/www/usuario
DefaultRoot (FTP) /var/www/%u
#### 3. Crear un CNAME con el nombre del virtual host
#### 4. Crear el usuario de la BD y la BD
----------------------------------------------------------
#### 5. Cambiar la configuración de usuarios para que use los usuarios de LDAP (con proftpd)
#### 6. Automatización a través de un script.
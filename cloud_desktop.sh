sudo apt-get update
sudo apt-get install curl

# Install Docker CE using oficial script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $(whoami)
sudo reboot

# Install guacamole containers
docker pull guacamole/guacamole
docker pull guacamole/guacd 
docker pull mysql

# Generate the database initialization script
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
mkdir /tmp/scripts 
mv initdb.sql /tmp/scripts

# Run MySQL
docker volume create mysql_volume
docker run --name guac-mysql -v /tmp/scripts:/tmp/scripts -v mysql_volume:/var/lib/mysql -e MYSQL_ROOT_PASSWORD='mysqlpassword' -d mysql:latest
docker exec -it guac-mysql bash

# Initialize Guacamole Database

mysql -u root -p 

CREATE DATABASE guacamole; 
CREATE USER 'guacamole' IDENTIFIED BY 'mysqlpassword';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole.* TO 'guacamole';
FLUSH PRIVILEGES; 
quit

cat /tmp/scripts/initdb.sql | mysql -u root -p guacamole
exit


# Run Guacamole Client

docker run --name guacd -d guacamole/guacd
docker run --name guacamole --link guacd:guacd --link guac-mysql:mysql -e MYSQL_DATABASE='guacamole' -e MYSQL_USER='guacamole' -e MYSQL_PASSWORD='mysqlpassword' -d -p 8080:8080 guacamole/guacamole


# Configure Tomcat

docker exec -it guacamole /bin/bash

sed -i 's/redirectPort="8443"/redirectPort="8443" server="" secure="true"/g' /usr/local/tomcat/conf/server.xml 
sed -i 's/Server port="8005" shutdown="SHUTDOWN"/Server port="-1" shutdown="SHUTDOWN"/g' /usr/local/tomcat/conf/server.xml 
rm -Rf /usr/local/tomcat/webapps/docs/ 
rm -Rf /usr/local/tomcat/webapps/examples/ 
rm -Rf /usr/local/tomcat/webapps/manager/ 
rm -Rf /usr/local/tomcat/webapps/host-manager/ 
chmod -R 400 /usr/local/tomcat/conf

exit


# MariaDB

## Reset root password
```
# run mariadb without authorization and network enabled
systemctl stop mariadb
mysqld_safe --skip-grant-tables --skip-networking

# use another terminal to update the password
mysql -u root
MariaDB> UPDATE mysql.user SET password=PASSWORD("new_password") where user='root';
MariaDB> FLUSH PRIVILEGES;
MariaDB> EXIT;

# start normal mariadb
$ mysqladmin shutdown
$ systemctl start mariadb
```

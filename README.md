# Shell Script Centos-7
 Install software (( PHP-FPM, PostgreSQL, Nginx)at the top of the script is the configuration of the web server settings (version PHP-fpm, PostgreSQL,) on Centos 7 server with 1 CPU 1Gb RAM.

 The bash script contains files for configuration settings. The script also contains all the files ( index.php and test config nginx file).

 This bash script creates a PostgreSQL user with a randomly generated password (login and password are written in the /home/centos/account_data.csv file) after creating the database configuration, changes are made to the authentication from trust to md5. The user has granted superuser rights.


![image](https://user-images.githubusercontent.com/122033209/235057550-b5f4e8b0-53a9-4125-9f9c-9a0aeeb6be8e.png)
  
  
  OR clean server using the "install.....sh" script


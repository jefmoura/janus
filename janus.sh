#!/bin/sh

############################
#                          #
# Author: Jeferson Moura   #
# Github: jefmoura         #
# Twitter: jefmmoreira     #
# 29/08/2016               #
#                          #
############################

LV="3.4.1"

__installDependencies(){
   sudo apt-get update
   sudo apt-get install -y openjdk-7-jre-headless
   sudo apt-get install -y libmysql-java
   sudo apt-get install -y cron
   sudo apt-get install -y gunzip
}

__setUpLiquibase(){
   source $HOME/.profile

   INSTALLED="$(command -v liquibase)"

   #If not added
   if [ -z "$LIQUIBASE_HOME" ]; then
      echo  'export MYSQL_JCONNECTOR=/usr/share/java/mysql-connector-java.jar'| sudo tee -a $HOME/.profile
      echo  'export LIQUIBASE_HOME=/usr/local/liquibase' | sudo tee -a $HOME/.profile
      echo  'export PATH=$PATH:$LIQUIBASE_HOME'| sudo tee -a $HOME/.profile
   fi

   #If not installed
   if [ -z "$INSTALLED" ]; then
      echo "[INFO]: Installing liquibase $LV "
      sudo rm -rf liquibase*
      wget https://github.com/liquibase/liquibase/releases/download/liquibase-parent-"$LV"/liquibase-"$LV"-bin.tar.gz -O liquibase-"$LV"-bin.tar.gz
      gunzip liquibase-"$LV"-bin.tar.gz
      sudo mkdir /usr/local/liquibase
      sudo tar -xf liquibase-"$LV"-bin.tar -C /usr/local/liquibase
      sudo chmod +x /usr/local/liquibase/liquibase
   else
      INSTALLED="$(liquibase --version)"
      echo "[INFO]: Liquibase is already installed, ${INSTALLED}"
   fi
}

__setUpJanus(){

   if [ ! -d "/opt/janus"  ]; then
      echo "[INFO]: Setting workspace for Janus. . ."
      sudo mkdir /opt/janus
      sudo mkdir /opt/janus/conf
      sudo chown -R ${USER} root /opt/janus
   fi

   sudo cp verifier.sh /opt/janus
   sudo cp conf/db.cfg /opt/janus/conf
   sudo cp conf/janus.cfg /opt/janus/conf
   sudo chmod +x /opt/janus/verifier.sh

   echo "[INFO]: Setting Janus as an Unix job. . ."
   sudo crontab -u ${USER} conf/job.cfg
   echo "[INFO]: Done"
}

__updateCron(){
   
   echo "[INFO]: Updating frequency of Janus' job. . ."
   sudo cp conf/db.cfg /usr/local/liquibase/conf
   sudo crontab -u ${USER} -r
   sudo crontab -u ${USER} conf/job.cfg
   echo "[INFO]: Done"
}

__removeAll(){

   echo "[INFO]: Removing Janus' folder. . ."
   sudo rm -r /opt/janus
   echo "[INFO]: Done"

   echo "[INFO]: Removing Crontab job. . ."
   sudo crontab -u ${USER} -r
   echo "[INFO]: Done"

   echo "[INFO]: Removing liquibase. . ."
   sudo rm -r /usr/local/liquibase
   echo "[INFO]: Done"
}

if [ "$1" == "install" ]; then
   __installDependencies
   __setUpLiquibase
   __setUpJanus
   sudo /bin/sh /opt/janus/verifier.sh

elif [ "$1" == "update-dbs" ]; then
   if [ -d "/opt/janus" ]; then
      echo "[INFO]: Updating list of databases. . ."
      sudo cp conf/db.cfg /opt/janus/conf
      echo "[INFO]: Done"
   else
      echo "[ERROR]: Janus was not installed."
      exit 0
   fi

elif [ "$1" == "update-cron" ]; then
   if [ -d "/opt/janus" ]; then
      echo "[INFO]: Updating frequency of update. . ."
      __updateCron
      echo "[INFO]: Done"
   else
      echo "[ERROR]: Janus was not installed."
      exit 0
   fi

elif [ "$1" == "now" ]; then
   if [ -d "/opt/janus" ]; then
      echo "[INFO]: Starting Janus verifier. . ."
      sudo /bin/sh /opt/janus/verifier.sh
      echo "[INFO]: Done"
   else
      echo "[ERROR]: Janus was not installed."
      exit 0
   fi

elif [ "$1" == "remove" ]; then
   if [ -d "/opt/janus" ]; then
      echo "[INFO]: Removing Janus from your computer. . ."
      __removeAll
      echo "[INFO]: Done"
   else
      echo "[ERROR]: Janus was not installed."
      exit 0
   fi

else
   echo '[WARNING] Use one of the valid commands [install|update-dbs|update-cron|now|remove]'
fi

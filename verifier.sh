#!/bin/sh

############################
#                          #
# Author: Jeferson Moura   #
# Github: jefmoura         #
# Twitter: jefmmoreira     #
# 30/08/2016               #
#                          #
############################

#Global variables
source "/opt/janus/conf/janus.cfg"
TODAY=$(date '+%D' | tr '/' '_')

#Create change logs of remote databases
#Create local databases with remote schemas

__initSystem() {

   while read DB_NAME; do
      echo "[INFO]:Generating change log from ${DB_NAME}"
      /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
           --classpath=${CONNECTOR_PATH} \
           --changeLogFile="${WORKSPACE_PATH}/db.init.changelog_${DB_NAME}.xml" --url="jdbc:mysql://${REMOTEDB_URL}/${DB_NAME}"  \
           --username=root   --password=root   generateChangeLog

      echo "[INFO]:Successfully generated change log."
      echo "[INFO]:Creating and setting local database..."

#      /usr/bin/mysql -uroot -proot -e "CREATE DATABASE ${DB_NAME}"

#      /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
#           --classpath=${CONNECTOR_PATH} \
#           --changeLogFile="${WORKSPACE_PATH}/db.init.changelog_${DB_NAME}.xml" --url="jdbc:mysql://localhost/${DB_NAME}"  \
#           --username=root   --password=root   update

      echo "[INFO]:Successfully created local database."
      echo "[INFO]:Creating folder of diff change log..."

      /bin/mkdir ${WORKSPACE_PATH}"/diff_"${DB_NAME}

      echo "[INFO]:Successfully create folder."
   done < /opt/janus/conf/db.cfg
}

#Verify difference between databases and generating a change log file with differences

__calcDiff() {

   while read DB_NAME; do
      echo "[INFO]:Verifying differences between local and remote ${DB_NAME}."

      /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
           --classpath=${CONNECTOR_PATH} \
           --url="jdbc:mysql://localhost/${DB_NAME}" \
           --username=root \
           --password=root \
           diffChangeLog \
           --referenceUrl="jdbc:mysql://${REMOTEDB_URL}/${DB_NAME}" \
           --referenceUsername=root \
           --referencePassword=root > "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml"

      echo "[INFO]:Done."
   done < /opt/janus/conf/db.cfg
}

#Apply found differences in local databases

__applyDiff() {

   while read DB_NAME; do
      if [ -f "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml" ]; then
         if [ $(xmlstarlet el "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml" | sort | uniq -c | wc -l) -gt  1 ]; then
             echo "[INFO]:Applying differences in ${DB_NAME}."

            /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
                 --classpath=${CONNECTOR_PATH} \
                 --changeLogFile="${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml" \
                 --url="jdbc:mysql://localhost/${DB_NAME}" \
                 --username=root   --password=root   update

            echo "[INFO]:Done."
         else
            echo "[INFO]:Have no changes in ${DB_NAME}."
#            /bin/rm -r "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml"
         fi
      fi
   done < /opt/janus/conf/db.cfg
}

#Create SQL files of change logs

__generateSQL() {

   while read DB_NAME; do
      if [ -f "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml" ]; then
#         if [ $(xmlstarlet el "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml" | sort | uniq -c | wc -l) -gt  1 ]; then
            echo "[INFO]:Generating SQL files of ${DB_NAME}."

            /bin/rm -f "${WORKSPACE_PATH}/db.last.changelog_${DB_NAME}.xml"

            /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
                 --classpath=${CONNECTOR_PATH} \
                 --changeLogFile="${WORKSPACE_PATH}/db.last.changelog_${DB_NAME}.xml" \
                 --url="jdbc:mysql://localhost/${DB_NAME}"  \
                 --username=root   --password=root   generateChangeLog

            /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
                 --classpath=${CONNECTOR_PATH} \
                 --changeLogFile="${WORKSPACE_PATH}/db.last.changelog_${DB_NAME}.xml" \
                 --url="jdbc:mysql://localhost/${DB_NAME}"  \
                 --username=root   --password=root   updateSQL > "${WORKSPACE_PATH}/db.last.${DB_NAME}.sql"

            /bin/sh /usr/local/liquibase/liquibase --driver=com.mysql.jdbc.Driver \
                 --classpath=${CONNECTOR_PATH} \
                 --changeLogFile="${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.xml" \
                 --url="jdbc:mysql://localhost/${DB_NAME}" \
                 --username=root   --password=root   updateSQL > "${WORKSPACE_PATH}/diff_${DB_NAME}/db.diff_${TODAY}.sql"

            echo "[INFO]:Successfully generated SQL files."
         else
            echo "[WARNING]:There is an empty diff file - /diff_${DB_NAME}/db.diff_${TODAY}.xml"
 #        fi
      fi
   done < /opt/janus/conf/db.cfg
}

#Execute verification of the system

if [ ! -e "${WORKSPACE_PATH}/.started" ]; then
   touch "${WORKSPACE_PATH}/.started"
   __initSystem

else
   while read DB_NAME; do
      if [ ! -d "${WORKSPACE_PATH}/diff_${DB_NAME}" ]; then
         echo "[ERROR]:Diff folder of ${DB_NAME} not have been created."
         exit
      fi
   done < /opt/janus/conf/db.cfg

   __calcDiff
   __applyDiff
   __generateSQL

fi

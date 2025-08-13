#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ..... $R Failure $N"
        exit 2
    else
        echo -e "$2...... $G Success $N"
    fi 
}

if [ $USERID -ne 0 ]
then
    echo " Please run this script with root access "
    exit 1 # manual exit if error occurs ( 1 to 127 for exit status)
else
    echo " You're super user "
fi

dnf install mongodb-org -y &>$LOGFILE
VALIDATE $? "Installing mongodb"

systemctl enable mongod &>$LOGFILE
VALIDATE $? "Enabling mongodb"

systemctl start mongod &>$LOGFILE
VALIDATE $? "Starting mongodb"
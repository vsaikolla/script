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

dnf module disable nodejs -y &>$LOGFILE
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>$LOGFILE
VALIDATE $? "Enabling nodejs:20 version"

dnf install nodejs -y &>$LOGFILE
VALIDATE $? "Installing nodejs"

id Roboshop &>$LOGFILE
if [ $? -ne 0 ]
then
    useradd Roboshop &>$LOGFILE
    VALIDATE $? "Creating Roboshop user"
    
    mkdir -p /app &>$LOGFILE
    VALIDATE $? "Creating app directory"

    curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>$LOGFILE
    VALIDATE $? "Downloading Catalogue code"

    cd /app &>$LOGFILE
    unzip /tmp/catalogue.zip &>$LOGFILE
    VALIDATE $? "Unzipping Code"

    npm install &>$LOGFILE
    VALIDATE $? "Installing nodejs Dependencies"

    # cp /home/ec2-user/script/catalogue.service /etc/systemd/system/catalogue.service &>$LOGFILE
    # VALIDATE $? "Copied Catalogue service"

    systemctl enable catalogue &>$LOGFILE
    VALIDATE $? "Enabling catalogue service"

    systemctl start catalogue &>$LOGFILE
    VALIDATE $? "Starting catalogue service"
else
    echo -e "Roboshop user already created...$Y SKIPPING $N"
fi



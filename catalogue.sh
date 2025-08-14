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
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "Roboshop user already created...$Y SKIPPING $N"
fi

mkdir -p /app &>$LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>$LOGFILE
VALIDATE $? "Downloading Catalogue code"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>$LOGFILE
VALIDATE $? "Unzipping Code"

npm install &>$LOGFILE
VALIDATE $? "Installing nodejs Dependencies"

cp /home/ec2-user/script/catalogue.service /etc/systemd/system/catalogue.service &>$LOGFILE
VALIDATE $? "Copied Catalogue service"

systemctl enable catalogue &>$LOGFILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue &>$LOGFILE
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo 

dnf install mongodb-mongosh -y &>$LOGFILE
VALIDATE $? "Installing mongodb client"

STATUS=$(mongosh --host mongodb.sainath.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.sainath.online </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi


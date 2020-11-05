#!/bin/bash

# ENV Variables
# BACKUP_S3 = true/false (DEFAULT OPTION if nothing is given)
# BACKUP_S3_BUCKET
# AWS_ASSUME_ARN
# AWS

MYSQL_FLAGS="--add-drop-database "
ACTION=${PERFORM_ACTION:-backup}

if [[ "${ACTION}" == "list" ]]; then
    if [[ ! -z "${AWS_ASSUME_ARN}" ]]; then
	session="$(aws sts assume-role --role-arn ${AWS_ASSUME_ARN} --role-session-name mysqlbackup_scheduled)"
	export AWS_ACCESS_KEY_ID=$(echo $session | jq -r  .Credentials.AccessKeyId)
	export AWS_SECRET_ACCESS_KEY=$(echo $session | jq -r .Credentials.SecretAccessKey)
	export AWS_SESSION_TOKEN=$(echo $session | jq -r .Credentials.SessionToken)
	export AWS_DEFAULT_REGION=us-east-1
	export AWS_REGION=us-east-1
    fi

    if [[ -z ${BACKUP_S3_BUCKET} ]]; then
	echo "Please include an S3 Bucket to restore from"
	exit
    fi

    aws s3 ls s3://${BACKUP_S3_BUCKET}

    exit
fi
    
if [[ "${ACTION}" == "restore" ]]; then
    if [[ ! -z "${AWS_ASSUME_ARN}" ]]; then
	session="$(aws sts assume-role --role-arn ${AWS_ASSUME_ARN} --role-session-name mysqlbackup_scheduled)"
	export AWS_ACCESS_KEY_ID=$(echo $session | jq -r  .Credentials.AccessKeyId)
	export AWS_SECRET_ACCESS_KEY=$(echo $session | jq -r .Credentials.SecretAccessKey)
	export AWS_SESSION_TOKEN=$(echo $session | jq -r .Credentials.SessionToken)
	export AWS_DEFAULT_REGION=us-east-1
	export AWS_REGION=us-east-1
    fi

    if [[ -z ${RESTORE_FILE} ]]; then
	echo "Please include a RESTORE_FILE to write to the database"
	exit
    fi

    if [[ -z ${BACKUP_S3_BUCKET} ]]; then
	echo "Please include an S3 Bucket to restore from"
	exit
    fi

    aws s3 cp s3://${BACKUP_S3_BUCKET}/${RESTORE_FILE} .

    if grep -q ".gz" <<< "${RESTORE_FILE}"; then
	echo "decompressing"
	gunzip ${RESTORE_FILE}
	RESTORE_FILE=${RESTORE_FILE:0:${#RESTORE_FILE}-3}
    fi

    CMD="mysql -h ${MYSQL_HOST} -u ${MYSQL_USERNAME} -p${MYSQL_PASSWORD} < ${RESTORE_FILE}"
    echo $CMD
    ${CMD}
    exit
fi

    
if [[ -z "${MYSQL_DATABASES}" ]]; then
    MYSQL_FLAGS="${MYSQL_FLAGS} --all-databases "
else
    MYSQL_FLAGS="${MYSQL_FLAGS} --databases "
    FS=$IFS
    IFS=","
    for db in ${MYSQL_DATABASES}; do
	MYSQL_FLAGS="${MYSQL_FLAGS} ${db} "
    done

    IFS=$FS
fi

DATE=`date "+%Y%m%d%H%M%S"`
FILENAME="mysql_backup-${DATE}.sql"
MYSQL_FLAGS="${MYSQL_FLAGS} $ADDITIONAL_MYSQL_FLAGS"


CMD="mysqldump $MYSQL_FLAGS -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD --result-file=${FILENAME}"
$CMD

if [[ ${COMPRESS_BAKCUP} -eq "true" ]]; then
    gzip $FILENAME
    FILENAME="${FILENAME}.gz"
fi

file $FILENAME

if [[ -z ${BACKUP_S3_BUCKET} ]]; then
    exit 0
fi


if [[ ! -z "${AWS_ASSUME_ARN}" ]]; then
    session="$(aws sts assume-role --role-arn ${AWS_ASSUME_ARN} --role-session-name mysqlbackup_scheduled)"
    export AWS_ACCESS_KEY_ID=$(echo $session | jq -r  .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo $session | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo $session | jq -r .Credentials.SessionToken)
    export AWS_DEFAULT_REGION=us-east-1
    export AWS_REGION=us-east-1
fi

aws s3 cp $FILENAME s3://${BACKUP_S3_BUCKET}/${FILENAME}

if [[ $? != 0 ]]; then
    echo "There was a problem uploading the file to S3"
    exit 1
fi

rm ${FILENAME}

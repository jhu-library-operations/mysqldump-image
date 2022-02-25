# mysqldump-container-image
This container image can be used to backup databases in container based deployments.

## Environment Variables
| Variable  | Description | Default | 
| --------- | ----------- | ------- | 
| BACKUP_S3 | Whether or not we backup to S3 | false |
| BACKUP_S3_BUCKET | The bucket to restore or backup to in AWS | N/A |
| AWS_ASSUME_ARN | The ARN to assume for S3 operations | N/A | 
| ACTION | `backup` or `restore` | backup | 
| MYSQL_FLAGS | flags to pass to `mysqldump` | `--add-drop-database` | 
| RESTORE_FILE | file to restore from in the S3 bucket | N/A | 
| MYSQL_HOST | the host for `mysqldump` to talk to | N/A | 
| MYSQL_USERNAME | the username for `mysqldump` | N/A | 
| MYSQL_PASSWORD | the password for `mysqldump` | N/A | 
| MYSQL_DATABASES | the database for `mysqldump` | N/A | 

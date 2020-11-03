FROM mysql:latest

LABEL org.opencontainers.image.source = "https://github.com/jhu-library-operations/mysqldump-image"
LABEL org.opencontainers.image.name = "MySQLDump"

RUN apt update && \
	apt install -y default-mysql-client jq && \
	apt install -y python3 python3-pip

RUN pip3 install awscli

COPY backupmysql.sh /opt/backupmysql.sh
RUN chmod +x /opt/backupmysql.sh

CMD [ "/opt/backupmysql.sh" ]

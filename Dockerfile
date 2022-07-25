# This is a base image for the merkur-mil-dwh-etl. 

# pull official base image
FROM python:3.9@sha256:a83c0aa6471527636d7331c30704d0f88e0ab3331bbc460d4ae2e53bbae64dca

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# label
LABEL description="This image is used for the Merkur MIL DWH ETL."

# # proxy is necessary for building this docker image (server and local)
ARG PROXY


## install necessary software with aptitude
RUN http_proxy=$PROXY apt-get update && http_proxy=$PROXY apt-get install -y  \
    unixodbc-dev \
    unixodbc \
    libpq-dev \
    pkg-config \
    build-essential \
    libpng-dev \
    unzip \
    libaio1 \
    curl

# needed for SCP
RUN which ssh-agent || ( http_proxy=$PROXY apt-get install -qq openssh-client )

# Install pyodbc dependencies for SQL Server (https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15)
RUN curl --proxy $PROXY https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl --proxy $PROXY https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN http_proxy=$PROXY apt-get update 
RUN ACCEPT_EULA=Y http_proxy=$PROXY apt-get -y install msodbcsql17


# Installing Oracle instant client
COPY external_libs/instantclient-basiclite-linux.x64-21.6.0.0.0dbru.zip .
RUN unzip instantclient-basiclite-linux.x64-21.6.0.0.0dbru.zip -d /opt/oracle \
    && rm -f instantclient-basiclite-linux.x64-21.6.0.0.0dbru.zip \
    && cd /opt/oracle/instantclient*  \
    && rm -f *jdbc* *occi* *mysql* *README *jar uidrvci genezi adrci \
    && echo /opt/oracle/instantclient* > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Installing Java for Adabas driver
RUN bash -c 'mkdir -p /usr/share/man/man{1,2,3,4,5,6,7,8}' && \
  http_proxy=$PROXY apt-get install -y openjdk-11-jre-headless && \
  rm -rf /usr/share/man/man*
# # Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME
# RUN java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'
# copy the ADABAS gateway into JAVA_HOME dir
COPY external_libs/connxjdbc.jar /usr/lib/jvm/java-11-openjdk-amd64/


# install the python packages
COPY requirements_docker.txt .
RUN python -m pip install --proxy=$PROXY -r requirements_docker.txt \
  && rm -f requirements_docker.txt





# create a folder for the code and copy some necessary files into it
WORKDIR /app/merkur-mil-dwh/src
COPY ./src /app/merkur-mil-dwh/src

# copy config file folders
COPY ./etl_config_files_mil/config_files /app/merkur-mil-dwh/etl_config_files_mil/config_files
COPY ./etl_config_files_mil/1_sql_configs /app/merkur-mil-dwh/etl_config_files_mil/1_sql_configs
COPY ./etl_config_files_mil/2_sql_configs /app/merkur-mil-dwh/etl_config_files_mil/2_sql_configs
COPY ./etl_config_files_mil/3_sql_configs /app/merkur-mil-dwh/etl_config_files_mil/3_sql_configs

# install custom pypi files
RUN python -m pip install dbconnectors --trusted-host gitlab.milsrv02.merkur.net --index-url https://gitlab+deploy-token-2:BJjHfubfxAgy7oRDqKJu@gitlab.milsrv02.merkur.net/api/v4/projects/26/packages/pypi/simple
RUN python -m pip install querybuilders --trusted-host gitlab.milsrv02.merkur.net --index-url https://gitlab+deploy-token-4:Yw1xhMVyYHevyoQt1N3r@gitlab.milsrv02.merkur.net/api/v4/projects/32/packages/pypi/simple
RUN python -m pip install etlhandlers --trusted-host gitlab.milsrv02.merkur.net --index-url https://mattermost-bots:5JGyZiryiRksZqiw8fsm@gitlab.milsrv02.merkur.net/api/v4/projects/31/packages/pypi/simple
#RUN python -m pip install etlhandlers --trusted-host gitlab.milsrv02.merkur.net --index-url https://gitlab+deploy-token-5:a4SKBPQBb4baN9b5obgo@gitlab.milsrv02.merkur.net/api/v4/projects/31/packages/pypi/simple


# create logs folder
RUN mkdir /logs


CMD ["bash"]






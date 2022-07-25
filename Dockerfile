# This is a base image for the merkur-mil-dwh-etl. 

# pull official base image
FROM python:3.9@sha256:a83c0aa6471527636d7331c30704d0f88e0ab3331bbc460d4ae2e53bbae64dca

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# label
LABEL description="This image is used for the Merkur MIL DWH ETL."




## install necessary software with aptitude
RUN apt-get update && apt-get install -y  \
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
RUN which ssh-agent || ( apt-get install -qq openssh-client )

# Install pyodbc dependencies for SQL Server (https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update 
RUN ACCEPT_EULA=Y apt-get -y install msodbcsql17


# Installing Java for Adabas driver
RUN bash -c 'mkdir -p /usr/share/man/man{1,2,3,4,5,6,7,8}' && \
  apt-get install -y openjdk-11-jre-headless && \
  rm -rf /usr/share/man/man*
# # Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME
# RUN java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'
# copy the ADABAS gateway into JAVA_HOME dir


# install the python packages
COPY requirements_docker.txt .
RUN python -m pip install -r requirements_docker.txt \
  && rm -f requirements_docker.txt





# create a folder for the code and copy some necessary files into it
WORKDIR /app/merkur-mil-dwh/src


# create logs folder
RUN mkdir /logs


CMD ["bash"]






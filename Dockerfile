FROM python:latest
COPY requirements_docker.txt requirements_docker.txt
RUN pip install -r requirements_docker.txt
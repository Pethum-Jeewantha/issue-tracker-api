FROM ballerina/ballerina:latest

WORKDIR /app

COPY --chown=ballerina:ballerina . /app

RUN bal build

EXPOSE 3900

CMD ["bal", "run", "./target/bin/issue_tracker_api.jar"]

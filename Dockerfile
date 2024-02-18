FROM ballerina/ballerina:latest

WORKDIR /app

RUN adduser -D -u 10001 -g '' appuser \
    && chown -R appuser:appuser /app

COPY --chown=ballerina:ballerina . /app

RUN bal build

USER 10001

EXPOSE 3900

CMD ["bal", "run", "./target/bin/issue_tracker_api.jar"]

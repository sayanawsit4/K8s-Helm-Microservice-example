FROM adoptopenjdk/openjdk11
VOLUME /tmp
COPY istio-experiments.jar app.jar
ENV JAVA_OPTS=""
ENTRYPOINT exec java -jar /app.jar --debug
CMD ["/bin/sh"]
FROM java:8-alpine

COPY target/uberjar/msa.jar /msa/app.jar

EXPOSE 3000

CMD ["java", "-jar", "/msa/app.jar"]

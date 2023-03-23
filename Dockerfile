FROM openjdk:8
COPY target/*.jar MavenHelloWorld-SNAPSHOT.jar
ENTRYPOINT ["sh", "-c", "java -jar /MavenHelloWorld-SNAPSHOT.jar"]

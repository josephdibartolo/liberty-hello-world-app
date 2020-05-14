FROM maven:3.6.0-jdk-8-slim AS build-stage
COPY . /project
WORKDIR /project
RUN mvn clean package
  
FROM ibmcom/websphere-liberty:kernel-ubi-min
 
ARG SSL=false
ARG MP_MONITORING=false
ARG HTTP_ENDPOINT=false
 
COPY --chown=1001:0 ./wlp/config/server.xml /opt/ibm/wlp/usr/servers/defaultServer/server.xml
COPY --chown=1001:0 --from=build-stage /project/target/hw-web.war /opt/ibm/wlp/usr/servers/defaultServer/apps/hw-web.war

USER root
RUN configure.sh
USER 1001


# ------

#IMAGE: Get the base image for Liberty
# FROM websphere-liberty:19.0.0.9-kernel


#BINARIES: Add in all necessary application binaries
# COPY wlp/config/server.xml /config/server.xml
# USER root
# RUN chown 1001:0 /config/server.xml
# USER 1001

# Generate Liberty config based on server.xml
# RUN configure.sh

# ADD target/hw-web.war /opt/ibm/wlp/usr/servers/defaultServer/apps

FROM openjdk:8-jre

# Environment Variables
ENV TRANSITCLOCK_LOGS /usr/local/transitclock/logs/
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH="${CATALINA_HOME}/bin:/usr/local/transitclock/bin:${PATH}"
ENV TOMCAT_MAJOR 9
ENV TOMCAT_VERSION 9.0.62
ENV TOMCAT_TGZ_URL https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN apt-get update
RUN apt-get install -y postgresql-client
RUN apt-get install -y wget

# TOMCAT CONFIG
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME
RUN set -x && curl -fsSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz && tar -xvf tomcat.tar.gz --strip-components=1 && rm bin/*.bat && rm tomcat.tar.gz*

# Install json parser so we can read API key for CreateAPIKey output
RUN wget http://stedolan.github.io/jq/download/linux64/jq && chmod +x ./jq && cp jq /usr/bin/

WORKDIR /
RUN mkdir /usr/local/transitclock
WORKDIR /usr/local/transitclock
ADD . /usr/local/transitclock
RUN mkdir db cache logs data

#RUN curl -s https://api.github.com/repos/TheTransitClock/transitime/releases/latest | jq -r ".assets[].browser_download_url" | grep 'Core.jar\|api.war\|web.war' | xargs -L1 wget

#commented above curl and changed source of TC and added build
RUN git clone https://github.com/goeuropa/transitime-1.git /transitime-core
RUN git checkout goeuropa_2_veh_to_blocks_endpoint_vehiclesdetails_fix
RUN mvn install -DskipTests
#end of change

# Deploy API which talks to core using RMI calls.
RUN mv api.war web.war /usr/local/tomcat/webapps

RUN sed -i 's/\r//' /usr/local/transitclock/bin/*.sh
RUN chmod 777 /usr/local/transitclock/bin/*.sh
RUN find /usr/local/transitclock -type d -print0 | xargs -0 chmod 777 
RUN find /usr/local/transitclock -type f -print0 | xargs -0 chmod 777

#set timezone
ENV TZ=Europe/Warsaw
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#add ssl support for tomcat
COPY ./tomcat-server-conf/. /usr/local/tomcat/conf
COPY ./ssl/. /usr/local/tomcat/conf

# Inserts agency IDs and GTFS-RT data into properties files
RUN . agency-looper.build.sh

EXPOSE 8080

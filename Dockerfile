FROM ubuntu:20.04

LABEL org.medatixx.image.authors="thomas.schramm@medatixx.de"

ENV TZ=Europe/Berlin
ENV TERM xterm
ENV LUCEE lucee-express-5.3.8.206.zip

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt-get update -y

RUN apt-get -y install \
    git \
    nano \
    wget \
    unzip \
    gpg \
    curl \
    supervisor \
    nginx \
    nginx-extras

# Install AdoptOpenJDK
RUN mkdir /tmp/adoptopenjdk && cd /tmp/adoptopenjdk \
    && wget https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public \
    && gpg --no-default-keyring --keyring ./adoptopenjdk-keyring.gpg --import public \
    && gpg --no-default-keyring --keyring ./adoptopenjdk-keyring.gpg --export --output adoptopenjdk-archive-keyring.gpg \
    && rm adoptopenjdk-keyring.gpg \
    && mv adoptopenjdk-archive-keyring.gpg /usr/share/keyrings \
    && chown root:root /usr/share/keyrings/adoptopenjdk-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/adoptopenjdk-archive-keyring.gpg] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb focal main" | tee /etc/apt/sources.list.d/adoptopenjdk.list \
    && apt-get update -y \
    && apt-get -y install adoptopenjdk-11-hotspot \
    && cd - \
    && rm -rf /tmp/adoptopenjdk

# Install Lucee
RUN mkdir /opt/lucee && cd /opt/lucee \
    && wget https://cdn.lucee.org/${LUCEE} \
    && unzip ${LUCEE} \
    && rm -f ${LUCEE} \
    && rm -rf __MACOSX \ 
    && chmod +x ./*.sh \
    && rm -f ./*.bat \
    && chmod +x ./bin/*.sh \
    && rm -f ./bin/*.bat \
    && mkdir -p ./server/lucee-server/context \
    && echo "password" > ./server/lucee-server/context/password.txt

# Install Tuckey UrlRewriteFilter
RUN curl --location 'https://search.maven.org/remotecontent?filepath=org/tuckey/urlrewritefilter/4.0.3/urlrewritefilter-4.0.3.jar' -o /opt/lucee/lib/urlrewritefilter-4.0.3.jar

# Cleanup
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /etc/nginx/sites-enabled \
    && rm -rf /var/www \
    && echo "alias ll='ls -lA'" >> /root/.bashrc

COPY /etc/ /etc/
COPY /var/www/ /var/www/
COPY /config/server.xml /opt/lucee/conf/server.xml
COPY /config/web.xml /opt/lucee/conf/web.xml
COPY /config/lucee-server.xml /opt/lucee/server/lucee-server/context/lucee-server.xml

EXPOSE 80

WORKDIR /var/www

# Set entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
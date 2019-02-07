# OS: Debian Linux
FROM rocker/shiny:3.4.4

# This container information
LABEL repository="https://github.com/NEONKID/RCDMViewer"
LABEL homepage="https://neonkid.xyz"
LABEL maintainer="Neon K.I.D <contact@neonkid.xyz>"

WORKDIR /srv/shiny-server

RUN apt-get update
RUN apt-get install -y libxml2-dev libssl-dev default-jdk default-jre libbz2-dev libicu-dev libpcre3-dev liblzma-dev libjpeg-dev libgeos-dev 

RUN mkdir -p RCDMViewer
ADD ./RCDMviewer.cfg /srv/shiny-server
ADD ./R /srv/shiny-server/RCDMViewer
RUN Rscript RCDMViewer/packageManager.R

CMD ["/usr/bin/shiny-server.sh"]
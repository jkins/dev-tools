#!/usr/bin/env bash

HOMEDIR=/home/vagrant
PACKAGE_DIR=/ozp-artifacts
STATIC_DEPLOY_DIR=/ozp-static-deployment

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
#						Configure and deploy backend	
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# stop the server and remove existing apps
sudo service tomcat stop
sudo rm -rf /var/lib/tomcat/webapps/marketplace /var/lib/tomcat/webapps/marketplace.war
# install new apps
sudo cp ${PACKAGE_DIR}/marketplace.war /var/lib/tomcat/webapps/
sudo chown tomcat /var/lib/tomcat/webapps/marketplace.war

# clear the elasticsearch data: 
curl -XDELETE 'http://localhost:9200/marketplace'
# delete the database
mysql -u root -ppassword -Bse "DROP DATABASE ozp; CREATE DATABASE ozp;"
# re-create the database
mysql -u ozp -pozp ozp < ${PACKAGE_DIR}/mysqlCreate.sql
# restart the server
sudo service tomcat start

cd ${HOMEDIR}/ozp-rest
# after the server is up and running, reload test data via newman. Note that 
# the urls for the applications in the test data need to be set accordingly, 
# perhaps something like this:
# WARNING: need to use actual IP address for IE9 VM (since it's localhost goes to 10.0.2.2)!!!!!
sed -i 's/http:\/\/ozone-development.github.io\/ozp-demo/https:\/\/localhost:7799\/demo_apps/g' postman/data/listingData.json
echo "Sleeping for 2 minutes waiting for server to start"
sleep 2m
newman -k -c postman/createSampleMetaData.json -e postman/env/localDev.json
newman -k -c postman/createSampleListings.json -e postman/env/localDev.json -n 32 -d postman/data/listingData.json

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
#						Configure and deploy frontend	
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

sudo mkdir -p ${STATIC_DEPLOY_DIR}
sudo rm -rf ${STATIC_DEPLOY_DIR}/center/*
sudo rm -rf ${STATIC_DEPLOY_DIR}/hud/*
sudo rm -rf ${STATIC_DEPLOY_DIR}/webtop/*
sudo rm -rf ${STATIC_DEPLOY_DIR}/iwc/*
sudo rm -rf ${STATIC_DEPLOY_DIR}/demo_apps/*

cd ${HOMEDIR}
sudo tar -C ${STATIC_DEPLOY_DIR}/center -xzf ${PACKAGE_DIR}/center.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/hud -xzf ${PACKAGE_DIR}/hud.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/webtop -xzf ${PACKAGE_DIR}/webtop.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/iwc -xzf ${PACKAGE_DIR}/iwc.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/demo_apps -xzf ${PACKAGE_DIR}/demo_apps.tar.gz --strip 2

# TODO: change all OzoneConfig.js files as needed

# IWC
sudo sed -i '0,/\(ozpIwc\.apiRootUrl=\).*/s//\1"https:\/\/localhost:7799\/marketplace\/api"/' ${STATIC_DEPLOY_DIR}/iwc/iframe_peer.html
sudo sed -i '0,/\(ozpIwc\.apiRootUrl=\).*/s//\1"https:\/\/localhost:7799\/marketplace\/api"/' ${STATIC_DEPLOY_DIR}/iwc/intentsChooser.html
sudo sed -i '0,/\(ozpIwc\.apiRootUrl=\).*/s//\1"https:\/\/localhost:7799\/marketplace\/api"/' ${STATIC_DEPLOY_DIR}/iwc/debugger.html

# Center
sudo sed -i '0,/\("API_URL":\).*/s//\1"https:\/\/localhost:7799\/marketplace"/' ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js
sudo sed -i '0,/\("CENTER_URL":\).*/s//\1"https:\/\/localhost:7799\/center"/' ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js
sudo sed -i '0,/\("HUD_URL":\).*/s//\1"https:\/\/localhost:7799\/hud"/' ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js
sudo sed -i '0,/\("WEBTOP_URL":\).*/s//\1"https:\/\/localhost:7799\/webtop"/' ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js

# HUD
# same as Center
sudo cp ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js ${STATIC_DEPLOY_DIR}/hud/

# Webtop
sudo sed -i '0,/\("API_URL":\).*/s//\1"https:\/\/localhost:7799\/marketplace\/api"/' ${STATIC_DEPLOY_DIR}/webtop/OzoneConfig.js
sudo sed -i '0,/\("IWC_URL":\).*/s//\1"https:\/\/localhost:7799\/iwc"/' ${STATIC_DEPLOY_DIR}/webtop/OzoneConfig.js
sudo sed -i '0,/\("CENTER_URL":\).*/s//\1"https:\/\/localhost:7799\/center"/' ${STATIC_DEPLOY_DIR}/webtop/OzoneConfig.js
sudo sed -i '0,/\("HUD_URL":\).*/s//\1"https:\/\/localhost:7799\/hud"/' ${STATIC_DEPLOY_DIR}/webtop/OzoneConfig.js
sudo sed -i '0,/\("WEBTOP_URL":\).*/s//\1"https:\/\/localhost:7799\/webtop"/' ${STATIC_DEPLOY_DIR}/webtop/OzoneConfig.js

# Demo Apps
sudo sed -i '0,/\(iwcUrl:\).*/s//\1"https:\/\/localhost:7799\/iwc"/' ${STATIC_DEPLOY_DIR}/demo_apps/OzoneConfig.js

sudo chown -R nginx ${STATIC_DEPLOY_DIR}
sudo service nginx restart
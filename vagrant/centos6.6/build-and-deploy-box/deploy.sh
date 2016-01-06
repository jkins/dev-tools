#!/usr/bin/env bash

HOMEDIR=/home/vagrant
PACKAGE_DIR=/ozp-artifacts
STATIC_DEPLOY_DIR=/ozp-static-deployment
# CHANGE ME to your host's IP address
HOST_IP="localhost"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#						Configure and deploy backend
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf "\n******************\n  Begin deploying backend \n******************\n"
# stop the server and remove existing apps
sudo service tomcat stop
sudo rm -rf /var/lib/tomcat/webapps/marketplace /var/lib/tomcat/webapps/marketplace.war
# install new apps
cd ${HOMEDIR}
tar -xzf ${PACKAGE_DIR}/rest-backend.tar.gz --strip 1
sudo mv marketplace.war /var/lib/tomcat/webapps/
sudo chown tomcat /var/lib/tomcat/webapps/marketplace.war

# copy MarketplaceConfig.groovy to tomcat
sudo cp /vagrant/configs/MarketplaceConfig.groovy /usr/share/tomcat/lib
sudo chown tomcat /usr/share/tomcat/lib/MarketplaceConfig.groovy

# copy OzoneConfig.properties to tomcat
sudo cp /vagrant/configs/OzoneConfig.properties /usr/share/tomcat/lib
sudo chown tomcat /usr/share/tomcat/lib/OzoneConfig.properties

# copy the security plugin files to tomcat
cd ${HOMEDIR}
sudo cp -r ozp-rest/grails-app/conf/ozone-security-beans /usr/share/tomcat/lib
sudo cp ozp-rest/grails-app/conf/SecurityContext.xml /usr/share/tomcat/lib
sudo cp ozp-rest/grails-app/conf/users.properties /usr/share/tomcat/lib

sudo chown -R tomcat /usr/share/tomcat/lib/ozone-security-beans
sudo chown tomcat /usr/share/tomcat/lib/SecurityContext.xml
sudo chown tomcat /usr/share/tomcat/lib/users.properties

# clear the elasticsearch data:
curl -XDELETE 'http://localhost:9200/marketplace'
# delete the database
mysql -u root -ppassword -Bse "DROP DATABASE ozp; CREATE DATABASE ozp;"
# re-create the database
mysql -u ozp -pozp ozp < ${HOMEDIR}/mysqlCreate.sql
# restart the server
rm ${HOMEDIR}/mysqlCreate.sql
sudo service tomcat start

cd ${HOMEDIR}/ozp-rest
# after the server is up and running, reload test data via newman. Note that
# the urls for the applications in the test data need to be set accordingly,
# perhaps something like this:
cp postman/data/listingData.json postman/data/modifiedListingData.json
sed -i "s/http:\/\/ozone-development.github.io\/ozp-demo/https:\/\/${HOST_IP}:7799\/demo_apps/g" postman/data/modifiedListingData.json
sed -i "s/http:\/\/ozone-development.github.io\/iwc\/owf7adapter.html?url=http%3A%2F%2Fozone-development.github.io%2Fozp-demo/https:\/\/${HOST_IP}:7799\/iwc\/owf7adapter.html?url=https%3A%2F%2F${HOST_IP}%3A7799%2Fdemo_apps/g" postman/data/modifiedListingData.json
printf "Sleeping for 2 minutes waiting for server to start"
sleep 2m

source ${HOMEDIR}/.nvm/nvm.sh
nvm use default
newman -k -c postman/createSampleMetaData.json -e postman/env/localDev.json
newman -k -c postman/createSampleListings.json -e postman/env/localDev.json -n 34 -d postman/data/modifiedListingData.json
printf "\n*****************\n  Finished deploying backend \n*****************\n"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#						Configure and deploy frontend
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf "\n******************\n  Begin deploying frontend \n******************\n"

sudo rm -rf ${STATIC_DEPLOY_DIR}
sudo mkdir ${STATIC_DEPLOY_DIR}
sudo mkdir ${STATIC_DEPLOY_DIR}/center
sudo mkdir ${STATIC_DEPLOY_DIR}/hud
sudo mkdir ${STATIC_DEPLOY_DIR}/webtop
sudo mkdir ${STATIC_DEPLOY_DIR}/demo_apps
sudo mkdir ${STATIC_DEPLOY_DIR}/iwc

cd ${HOMEDIR}
sudo tar -C ${STATIC_DEPLOY_DIR}/center -xzf ${PACKAGE_DIR}/center.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/hud -xzf ${PACKAGE_DIR}/hud.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/webtop -xzf ${PACKAGE_DIR}/webtop.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/iwc -xzf ${PACKAGE_DIR}/iwc.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/iwc -xzf ${PACKAGE_DIR}/iwc-owf7-widget-adapter.tar.gz --strip 2
sudo tar -C ${STATIC_DEPLOY_DIR}/demo_apps -xzf ${PACKAGE_DIR}/demo_apps.tar.gz --strip 2

# modify OzoneConfig.js files

# IWC
sudo sed -i "0,/\(ozpIwc\.apiRootUrl=\).*/s//\1'https:\/\/${HOST_IP}:7799\/marketplace\/api'/" ${STATIC_DEPLOY_DIR}/iwc/iframe_peer.html
sudo sed -i "0,/\(ozpIwc\.apiRootUrl=\).*/s//\1'https:\/\/${HOST_IP}:7799\/marketplace\/api'/" ${STATIC_DEPLOY_DIR}/iwc/intentsChooser.html
sudo sed -i "0,/\(ozpIwc\.apiRootUrl=\).*/s//\1'https:\/\/${HOST_IP}:7799\/marketplace\/api'/" ${STATIC_DEPLOY_DIR}/iwc/debugger/index.html


# Center
sudo sed -i "0,/\(\"API_URL\":\).*/s//\1\"https:\/\/${HOST_IP}:7799\/marketplace\",/" ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js
sudo sed -i "0,/\(\"CENTER_URL\":\).*/s//\1\"https:\/\/${HOST_IP}:7799\/center\",/" ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js
sudo sed -i "0,/\(\"HUD_URL\":\).*/s//\1\"https:\/\/${HOST_IP}:7799\/hud\",/" ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js
sudo sed -i "0,/\(\"WEBTOP_URL\":\).*/s//\1\"https:\/\/${HOST_IP}:7799\/webtop\",/" ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js

# HUD
# same as Center
sudo cp ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js ${STATIC_DEPLOY_DIR}/hud/

# Webtop
echo "window.OzoneConfig = {
	\"API_URL\": \"https://${HOST_IP}:7799/marketplace\",
    \"CENTER_URL\": \"https://${HOST_IP}:7799/center\",
    \"DEVELOPER_RESOURCES_URL\": \"#\",
    \"FEEDBACK_ADDRESS\": \"mailto:person@address.com\",
    \"HELPDESK_ADDRESS\": \"mailto:person@address.com\",
    \"HELP_URL\": \"#\",
    \"HUD_URL\": \"https://${HOST_IP}:7799/hud\",
    \"IWC_URL\": \"https://${HOST_IP}:7799/iwc\",
    \"METRICS_URL\": \"/path/to/metrics\",
    \"METRICS_WEBTOP_SITE_ID\": 3,
    \"WEBTOP_URL\": \"https://${HOST_IP}:7799/webtop\"
};" | sudo tee ${STATIC_DEPLOY_DIR}/webtop/OzoneConfig.js


# Demo Apps
# copy over IWC+Legacy Adapter to bower ozp-iwc
sudo cp -r ${STATIC_DEPLOY_DIR}/iwc ${STATIC_DEPLOY_DIR}/demo_apps/bower_components/ozp-iwc/dist
sudo sed -i "0,/\(iwcUrl:\).*/s//\1\"https:\/\/${HOST_IP}:7799\/iwc\"/" ${STATIC_DEPLOY_DIR}/demo_apps/OzoneConfig.js

sudo chown -R nginx ${STATIC_DEPLOY_DIR}

# copy and modify nginx conf file
sudo cp /vagrant/configs/static_nginx.conf /etc/nginx/conf.d/
sudo sed -i "s/\$host_ip/${HOST_IP}/g" /etc/nginx/conf.d/static_nginx.conf

sudo service nginx restart
printf "\n****************\n  Finished deploying frontend \n****************\n"

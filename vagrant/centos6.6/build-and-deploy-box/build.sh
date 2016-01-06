#!/usr/bin/env bash


HOMEDIR=/home/vagrant
# Not sure what is causing these permission issues, but fix them here
sudo chown -R vagrant ${HOMEDIR}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#							Build backend
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
cd ${HOMEDIR}
rm -rf ozp-rest
printf "\n********************\n cloning ozp-rest \n********************\n"
git clone https://github.com/ozone-development/ozp-rest.git
printf "\n******************\n finished cloning ozp-rest \n******************\n"
cd ${HOMEDIR}/ozp-rest/
source ${HOMEDIR}/.sdkman/bin/sdkman-init.sh
sdk use grails 2.3.7
sdk current grails
grails war
printf "\n****************\n  finished compiling war file \n****************\n"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#							Build frontend
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
cd ${HOMEDIR}
rm -rf ozp-hud ozp-center ozp-iwc ozp-webtop ozp-demo ozp-iwc-owf7-widget-adapter

printf "\n******************\n  cloning front-end repos \n******************\n"
git clone https://github.com/ozone-development/ozp-hud.git
git clone https://github.com/ozone-development/ozp-center.git
git clone https://github.com/ozone-development/ozp-iwc.git
git clone https://github.com/ozone-development/ozp-iwc-owf7-widget-adapter.git
git clone https://github.com/ozone-development/ozp-webtop.git
git clone https://github.com/ozone-development/ozp-demo.git
printf "\n**************\n  finished cloning front-end repos \n*************\n"

# stop Bower from promting user about usage statistics
# http://stackoverflow.com/questions/22387857/stop-bower-from-asking-for-statistics-when-installing
export CI=true

source ${HOMEDIR}/.nvm/nvm.sh
nvm use default

# - - - - - - - - - - - - - - - - - - -
# 				Webtop
# - - - - - - - - - - - - - - - - - - -
# NOTE: for some strange reason, it seems webtop (sometimes) needs to be built
# first
printf "\n********************\n  Building Webtop \n********************\n"
cd ${HOMEDIR}/ozp-webtop
npm install
bower install
npm run build
npm run compile
printf "\n******************\n  Finished Building Webtop \n******************\n"

# - - - - - - - - - - - - - - - - - - -
# 				IWC
# - - - - - - - - - - - - - - - - - - -
printf "\n********************\n  Building IWC \n********************\n"
cd ${HOMEDIR}/ozp-iwc
# checkout latest tag
git checkout $(git describe --tags `git rev-list --tags --max-count=1`)
npm install
bower install
npm run build
printf "\n*******************\n  Finished Building IWC \n*******************\n"

# - - - - - - - - - - - - - - - - - - -
# 				IWC Legacy Adapter
# - - - - - - - - - - - - - - - - - - -
printf "\n********************\n  Building IWC Legacy Adapter \n********************\n"
cd ${HOMEDIR}/ozp-iwc-owf7-widget-adapter
# checkout latest tag
git checkout $(git describe --tags `git rev-list --tags --max-count=1`)
npm install
bower install
npm run build
printf "\n*******************\n  Finished Building IWC Legacy Adapter \n*******************\n"

# - - - - - - - - - - - - - - - - - - -
# 				Center
# - - - - - - - - - - - - - - - - - - -
printf "\n********************\n  Building Center \n********************\n"
cd ${HOMEDIR}/ozp-center
npm install
npm run build
printf "\n******************\n  Finished Building Center \n******************\n"

# - - - - - - - - - - - - - - - - - - -
# 				Hud
# - - - - - - - - - - - - - - - - - - -
printf "\n********************\n  Building HUD \n********************\n"
cd ${HOMEDIR}/ozp-hud
npm install
npm run build
printf "\n*******************\n  Finished Building HUD \n*******************\n"

# - - - - - - - - - - - - - - - - - - -
# 				Demo apps
# - - - - - - - - - - - - - - - - - - -
printf "\n********************\n  Building Demo Apps \n********************\n"
cd ${HOMEDIR}/ozp-demo
bower install
npm run prestart
printf "\n****************\n  Finished Building Demo Apps \n****************\n"

#!/usr/bin/env bash

# Use case: testing a branch for ozp-center

BRANCH_NAME="short-description-charcount"

# make sure these variables are the same as those used during the initial
# vagrant up, or this will not work
HOMEDIR=/home/vagrant
STATIC_DEPLOY_DIR=/ozp-static-deployment
# CHANGE ME to your host's IP address (if desired)
HOST_IP="localhost"

# write important data here for easy grepping later
OUTPUT_FILE=${HOMEDIR}/${BRANCH_NAME}/output.txt

################################################################################
#							Pull code
################################################################################
cd ${HOMEDIR}
mkdir -p ${BRANCH_NAME}
cd ${BRANCH_NAME}
rm -rf ${OUTPUT_FILE}
touch ${OUTPUT_FILE}
rm -rf ozp-center
git clone https://github.com/ozone-development/ozp-center.git | tee -a ${OUTPUT_FILE}
cd ozp-center
git checkout ${BRANCH_NAME} | tee -a ${OUTPUT_FILE}

################################################################################
#							Build
################################################################################
# stop Bower from promting user about usage statistics
# http://stackoverflow.com/questions/22387857/stop-bower-from-asking-for-statistics-when-installing
export CI=true
rm -rf node_modules
rm -rf bower_components
source ${HOMEDIR}/.nvm/nvm.sh
nvm use default
npm install | tee -a ${OUTPUT_FILE}
bower install | tee -a ${OUTPUT_FILE}
npm run build | tee -a ${OUTPUT_FILE}

################################################################################
#							Run tests
################################################################################
# run the tests
npm run test | tee -a ${OUTPUT_FILE}

################################################################################
#							Deploy
################################################################################
# use the existing OzoneConfig.js file
cp -f ${STATIC_DEPLOY_DIR}/center/OzoneConfig.js dist/
# remove old deployment
sudo rm -rf ${STATIC_DEPLOY_DIR}/center/*
sudo cp -r dist/* ${STATIC_DEPLOY_DIR}/center/

# fix ownership and restart nginx
sudo chown -R nginx ${STATIC_DEPLOY_DIR}
sudo service nginx restart
printf '\n***********\n  Finished center rebuild and re-deploy for branch ${BRANCH_NAME} \n***********\n' | tee -a ${OUTPUT_FILE}

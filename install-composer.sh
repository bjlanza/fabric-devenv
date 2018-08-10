#!/usr/bin/env bash

FABRIC_DEV_SERVERS_URL=https://raw.githubusercontent.com/hyperledger/composer-tools/master/packages/fabric-dev-servers/fabric-dev-servers.tar.gz

if [ -z $1 ]; then
  COMPOSER_VERSION=latest
else
  COMPOSER_VERSION=$1
fi

if [ ${COMPOSER_VERSION} = 'none' ]; then
  echo "Skipping Composer install"
  exit 0
elif [ ${COMPOSER_VERSION:0:5} = '0.16.' ]; then
  export FABRIC_VERSION=hlfv1
elif [ ${COMPOSER_VERSION:0:5} = '0.18.' -o ${COMPOSER_VERSION:0:5} = '0.19.' ]; then
  export FABRIC_VERSION=hlfv11
elif [ ${COMPOSER_VERSION} = 'latest' -o ${COMPOSER_VERSION} = 'unstable' -o ${COMPOSER_VERSION:0:5} = '0.20.' ]; then
  export FABRIC_VERSION=hlfv12
else
  >&2 echo "Unexpected COMPOSER_VERSION ${COMPOSER_VERSION}"
  >&2 echo "COMPOSER_VERSION must be a 0.16.x, 0.18.x, 0.19.x, or 0.20.x (latest) version"
  >&2 echo "Alternatively use 'none' to skip the Composer install"
  exit 1
fi

export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"

# Install Composer modules
npm ls -g composer-cli@${COMPOSER_VERSION} >/dev/null 2>&1 || npm install -g composer-cli@${COMPOSER_VERSION}
npm ls -g composer-rest-server@${COMPOSER_VERSION} >/dev/null 2>&1 || npm install -g composer-rest-server@${COMPOSER_VERSION}
npm ls -g generator-hyperledger-composer@${COMPOSER_VERSION} >/dev/null 2>&1 || npm install -g generator-hyperledger-composer@${COMPOSER_VERSION}
npm ls -g composer-playground@${COMPOSER_VERSION} >/dev/null 2>&1 || npm install -g composer-playground@${COMPOSER_VERSION}

# Install and start Fabric dev env for Composer
FABRIC_DIR="$HOME/fabric-dev-servers"
if [ ! -d ${FABRIC_DIR} ]; then
  mkdir -p ${FABRIC_DIR}
  cd ${FABRIC_DIR}

  curl -O "$FABRIC_DEV_SERVERS_URL"
  tar -xvzf fabric-dev-servers.tar.gz

  ./downloadFabric.sh
  sg docker ./startFabric.sh
  ./createPeerAdminCard.sh
fi

#
# add devenv section to .profile
#
# Note: this will remove any existing devenv section so that
# multiple 'vagrant provision' commands do not cause duplication
#
DEVENV_START_COMMENT="# ---BEGIN-COMPOSER-DEVENV-PROFILE-SECTION---"
DEVENV_END_COMMENT="# ---END-COMPOSER-DEVENV-PROFILE-SECTION---"

sed -i.bak "/$DEVENV_START_COMMENT/,/$DEVENV_END_COMMENT/d" ~/.profile

cat << END-PROFILE-SECTION >> ~/.profile
$DEVENV_START_COMMENT

# set fabric version
export FABRIC_VERSION=$FABRIC_VERSION

$DEVENV_END_COMMENT
END-PROFILE-SECTION

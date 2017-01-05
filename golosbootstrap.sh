#!/bin/bash

GOLOS_REPO="https://github.com/GolosChain/golos"

set -e
set -x

MODE=build_and_install
if [ ! -z $1 ]; then
	[ x"build_only" == x"$1" ] && MODE=build_only
fi


# Only works on Ubuntu
OS=`cat /etc/lsb-release 2>/dev/null| grep DISTRIB_ID | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]'`
if [[ "x$OS" != "xubuntu" ]]; then
	echo "ERROR: Unsupported OS"
	exit 1
fi

# Build Options
BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Release -DLOW_MEMORY_NODE=ON -DCLEAR_VOTES=ON"

# Test Physical Memory
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
if (( PHYMEM < 14 )); then
	echo "WARN: You have Physical Memory < 16Gb, will build LOW_MEMORY_NODE"
	BUILD_OPTIONS="$BUILD_OPTIONS -DLOW_MEMORY_NODE=ON -DCLEAR_VOTES=ON"
elif (( PHYMEM < 2 )); then
	echo "ERROR: You have no enough Physical Memory (min: 2Gb)"
	exit 1
fi

# Get number of processors
CPUNUM=$(getconf _NPROCESSORS_ONLN)

BASEDIR=`mktemp -d`
trap 'rm -rf $BASEDIR' EXIT
pushd $BASEDIR

# Unpack contribute files
base64 -d <<CONTRIBEOF | tar xz
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
bf8Hn3oZjgBQAAA=

CONTRIBEOF

##################################
# Preparing System
##################################


# Check if required packages are not installed
PACKAGES_TO_INSTALL=""
for pkg in git cmake g++ python-dev autotools-dev libicu-dev build-essential libbz2-dev libboost-all-dev libssl-dev libncurses5-dev doxygen libreadline-dev dh-autoreconf build-essential; do
	PKG_OK=no
	dpkg-query -W --showformat='${Status}\n' $pkg | grep "install ok installed" > /dev/null && PKG_OK=yes
	echo Checking for $pkg: $PKG_OK
	if [ x"no" == x"$PKG_OK" ]; then
		  PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $pkg"
	fi
done

# If found missed packages - install
if [ x"" != x"$PACKAGES_TO_INSTALL" ]; then
	sudo apt-get update || :
	sudo apt-get install -y $PACKAGES_TO_INSTALL
fi


# Upgrade system (not sure)
# apt-get -y upgrade

##################################
# Building Golosnode
##################################

# Create folder for installing node
DEB_PATH=$BASEDIR/package/golos
GOLOS_PATH=$BASEDIR/package/golos/opt/golos
mkdir -p $DEB_PATH
mkdir -p $GOLOS_PATH

# Clone Golos
git clone $GOLOS_REPO
cd golos
git checkout master
git submodule update --init --recursive

# Build
cmake $BUILD_OPTIONS .
make -j$CPUNUM

# Preparing golosnode package
install -m 0755 programs/golosd/golosd $GOLOS_PATH/
install -m 0644 programs/golosd/snapshot5392323.json $GOLOS_PATH
install -m 0755 programs/cli_wallet/cli_wallet $GOLOS_PATH
cd ..

# Copying contrib files to package
mkdir $GOLOS_PATH/witness_node_data_dir
cp $BASEDIR/contrib/config.ini $GOLOS_PATH/witness_node_data_dir/config.ini
mkdir -p $DEB_PATH/lib/systemd/system
cp $BASEDIR/contrib/golosd.service $DEB_PATH/lib/systemd/system/
cp -r $BASEDIR/contrib/debian $DEB_PATH/DEBIAN

# Fixing package version
GOLOS_VERSION=$(cat $BASEDIR/golos/libraries/chain/include/steemit/chain/config.hpp | grep -m 1 STEEMIT_BLOCKCHAIN_VERSION | grep -oP '(\d+(, )?){3}' | sed 's/, /./g')
UNIXTIME=$(date +%s)
sed -i "s/##GOLOS_VERSION##/$GOLOS_VERSION/" $DEB_PATH/DEBIAN/control
sed -i "s/##UNIXTIME##/$UNIXTIME/" $DEB_PATH/DEBIAN/control

# Make deb package
fakeroot dpkg-deb --build $DEB_PATH

mv -v $DEB_PATH/../golos.deb /tmp/golos-$GOLOS_VERSION-$UNIXTIME.deb

echo 
echo "#############################################################"
echo "DEB package path: /tmp/golos-${GOLOS_VERSION}-${UNIXTIME}.deb"
echo "#############################################################"
echo 

if [ x"$MODE" == x"build_and_install" ]; then
	sudo dpkg -i /tmp/golos-$GOLOS_VERSION-$UNIXTIME.deb
fi

popd # basedir


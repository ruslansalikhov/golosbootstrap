#!/usr/bin/env bash

PROGNAME=$(basename $0)

# Settings
GOLOS_REPO="https://github.com/GolosChain/golos"
MODE=build_and_install
LOG_FILE=/tmp/golosbootstrap.log

# Build Options
BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Release"

{ # this ensures the entire script is downloaded #


# Setup logging output of each command to log file
BASEDIR=""

function cleanup
{
	exec 2>&4 1>&3
	[ ! -z $BASEDIR ] && rm -rf $BASEDIR
}


function error_exit
{
	echo "${PROGNAME}: ERROR - ${1:-"Unknown Error"}" >&4
	exit 1
}

function print_info
{
	bold=`tput bold`
	reset=`tput sgr0`
	echo "${bold}$1${reset}" >&3
}

function print_warn
{
	bold=`tput dim`
	reset=`tput sgr0`
	echo "${bold}WARN: $1${reset}" >&4
}

exec 3>&1 4>&2
exec 1>$LOG_FILE 2>&1
trap cleanup EXIT INT TERM QUIT

# Parsing arguments
if [ ! -z $1 ]; then
	[ x"build_only" == x"$1" ] && MODE=build_only
fi

# ###################
# Checking system
# ###################

print_info "* CHECKING SYSTEM"

# Only works on Ubuntu
OS=`cat /etc/lsb-release 2>/dev/null| grep DISTRIB_ID | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]'`
if [[ "x$OS" != "xubuntu" ]]; then
	error_exit "ERROR: Unsupported OS"
fi

# Test Physical Memory
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
if (( PHYMEM < 2 )); then
	error_exit "You have no enough Physical Memory (min: 2Gb)"
elif (( PHYMEM < 14 )); then
	print_warn "You have Physical Memory < 16Gb, will build LOW_MEMORY_NODE"
	BUILD_OPTIONS="$BUILD_OPTIONS -DLOW_MEMORY_NODE=ON -DCLEAR_VOTES=ON"
fi

# Get number of processors
CPUNUM=$(getconf _NPROCESSORS_ONLN)

BASEDIR=`mktemp -d`
if [ $? -ne 0 ]; then
	error_exit "Cannot create tempopary directory"
fi
pushd $BASEDIR >/dev/null

# Unpack contribute files
base64 -d <<CONTRIBEOF | tar xz
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

CONTRIBEOF

##################################
# Preparing System
##################################


# Check if required packages are not installed
print_info "** CHECKING REQUIRED PACKAGES FROM BUILDING"
PACKAGES_TO_INSTALL=""
for pkg in git cmake g++ python-dev autotools-dev libicu-dev build-essential libbz2-dev libboost-all-dev libssl-dev libncurses5-dev doxygen libreadline-dev dh-autoreconf build-essential; do
	PKG_OK=no
	dpkg-query -W --showformat='${Status}\n' $pkg | grep "install ok installed" > /dev/null && PKG_OK=yes
	print_info " - Checking for $pkg: $PKG_OK"
	if [ x"no" == x"$PKG_OK" ]; then
		  PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $pkg"
	fi
done

# If found missed packages - install
if [ x"" != x"$PACKAGES_TO_INSTALL" ]; then
	sudo apt-get update || : 
	sudo apt-get install -y $PACKAGES_TO_INSTALL || error_exit "Cannot Install Required Packages"
fi


# Upgrade system (not sure)
# apt-get -y upgrade

##################################
# Building Golosnode
##################################

print_info "* BULDING GOLOS"

# Create folder for installing node
DEB_PATH=$BASEDIR/package/golos
GOLOS_PATH=$BASEDIR/package/golos/opt/golos
mkdir -p $DEB_PATH
mkdir -p $GOLOS_PATH

# Clone Golos
print_info "** DOWNLOADING SOURCE CODE"
git clone $GOLOS_REPO || error_exit "Cannot clone sources"
cd golos
git checkout master
git submodule update --init --recursive

# Build
print_info "** COMPILING"
cmake $BUILD_OPTIONS . || error_exit "Cannot configure project"
make -j$CPUNUM || error_exit "Cannot compile project"

# Preparing golosnode package
print_info "** PREPARING FILES FOR PACKAGING"
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
print_info "** PACKAGING"
fakeroot dpkg-deb --build $DEB_PATH || error_exit "Cannot make DEB"

mv $DEB_PATH/../golos.deb /tmp/golos-$GOLOS_VERSION-$UNIXTIME.deb

if [ x"$MODE" == x"build_and_install" ]; then
	print_info "* INSTALLING"
	sudo dpkg -i /tmp/golos-$GOLOS_VERSION-$UNIXTIME.deb || error_exit "Cannot install package"
fi

print_info "* DONE"
print_info
print_info "- DEB package path: /tmp/golos-${GOLOS_VERSION}-${UNIXTIME}.deb"
print_info
print_info "-- To run golosd use: systemctl start golosd"
print_info "-- To check golosd use: systemctl status golosd"
print_info "-- To stop golosd use: systemctl stop golosd"
print_info "-- Golos path: /opt/golos"
print_info 

popd > /dev/null # basedir

} # this ensures the entire script is downloaded #

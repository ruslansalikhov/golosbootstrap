#!/bin/bash

set -e
set -x

# Only works under root
if [[ $EUID -ne 0 ]]; then
	echo "ERROR: This script must be run as root"
	exit 1
fi

# Only works on Ubuntu
OS=`cat /etc/lsb-release 2>/dev/null| grep DISTRIB_ID | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]'`
if [[ "x$OS" != "xubuntu" ]]; then
	echo "ERROR: Unsupported OS"
	exit 1
fi

create_golosd_service_file() {
	cat > $1 <<EOF
[Unit]
Description=Golos Node Service

[Service]
Restart=always
WorkingDirectory=/opt/golosnode
ExecStart=/opt/golosnode/golosd
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=golosd
StartLimitInterval=1
Type=simple
User=golos
TimeoutSec=7200
TimeoutStopSec=7200

[Install]
WantedBy=multi-user.target
EOF
}

create_golos_config_file() {
	cat > $1 <<EOF
# Endpoint for P2P node to listen on
p2p-endpoint = 0.0.0.0:4243

# Maxmimum number of incoming connections on P2P endpoint
# p2p-max-connections = 

# P2P nodes to connect to on startup (may specify multiple times)
# seed-node = 
seed-node = 88.99.13.48:4243
seed-node = golos.imcoins.org:4243
seed-node = node.golostools.ru:4243
seed-node = 138.68.101.115:4243
seed-node = 178.62.224.148:4242

# Pairs of [BLOCK_NUM,BLOCK_ID] that should be enforced as checkpoints.
# checkpoint =

# Endpoint for websocket RPC to listen on
rpc-endpoint = 127.0.0.1:8080

# Endpoint for TLS websocket RPC to listen on
# rpc-tls-endpoint =

# The TLS certificate file for this server
# server-pem =

# Password for this certificate
# server-pem-password =

# API user specification, may be specified multiple times
# api-user =

# Set an API to be publicly available, may be specified multiple times
public-api = database_api login_api

# Plugin(s) to enable, may be specified multiple times
enable-plugin = witness account_history

# Maximum age of head block when broadcasting tx via API
max-block-age = 200

# Defines a range of accounts to track as a json pair ["from","to"] [from,to]
# track-account-range =

# Ignore posting operations, only track transfers and account updates
# filter-posting-ops =

# Track account statistics by grouping orders into buckets of equal size measured in seconds specified as a JSON array of numbers
account-stats-bucket-size = [60,3600,21600,86400,604800,2592000]

# How far back in time to track history for each bucker size, measured in the number of buckets (default: 100)
account-stats-history-per-bucket = 100

# Which accounts to track the statistics of. Empty list tracks all accounts.
account-stats-tracked-accounts = []

# Track blockchain statistics by grouping orders into buckets of equal size measured in seconds specified as a JSON array of numbers
chain-stats-bucket-size = [60,3600,21600,86400,604800,2592000]

# How far back in time to track history for each bucket size, measured in the number of buckets (default: 100)
chain-stats-history-per-bucket = 100

# Database edits to apply on startup (may specify multiple times)
# edit-script =

# RPC endpoint of a trusted validating node (required)
# trusted-node =

# Set the maximum size of cached feed for an account
follow-max-feed-size = 500

# Track market history by grouping orders into buckets of equal size measured in seconds specified as a JSON array of numbers
market-history-bucket-size = [15,60,300,3600,86400]

# How far back in time to track history for each bucket size, measured in the number of buckets (default: 5760)
market-history-buckets-per-size = 5760

# Defines a range of accounts to private messages to/from as a json pair ["from","to"] [from,to)
# pm-account-range =

# Enable block production, even if the chain is stale.
enable-stale-production = false

# Percent of witnesses (0-99) that must be participating in order to produce blocks
required-participation = false

# name of witness controlled by this node (e.g. initwitness )
# witness =

# name of miner and its private key (e.g. ["account","WIF PRIVATE KEY"] )
# miner =

# Number of threads to use for proof of work mining
# mining-threads =

# WIF PRIVATE KEY to be used by one or more witnesses or miners
# private-key =

# Account creation fee to be voted on upon successful POW - Minimum fee is 100.000 STEEM (written as 100000)
# miner-account-creation-fee =

# Maximum block size (in bytes) to be voted on upon successful POW - Max block size must be between 128 KB and 750 MB
# miner-maximum-block-size =

# SBD interest rate to be vote on upon successful POW - Default interest rate is 10% (written as 1000)
# miner-sbd-interest-rate =

# declare an appender named "stderr" that writes messages to the console
[log.console_appender.stderr]
stream=std_error

# declare an appender named "p2p" that writes messages to p2p.log
[log.file_appender.p2p]
filename=logs/p2p/p2p.log
# filename can be absolute or relative to this config file

# route any messages logged to the default logger to the "stderr" logger we
# declared above, if they are info level are higher
[logger.default]
level=warn
appenders=stderr

# route messages sent to the "p2p" logger to the p2p appender declared above
[logger.p2p]
level=warn
appenders=p2p
EOF
}

# Build Options

BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Release -DLOW_MEMORY_NODE=ON -DCLEAR_VOTES=ON"

# Test Physical Memory
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
if (( PHYMEM < 14 )); then
	echo "WARN: You have Physical Memory < 16Gb, will build LOW_MEMOTY_NODE"
	BUILD_OPTIONS="$BUILD_OPTIONS -DLOW_MEMORY_NODE=ON -DCLEAR_VOTES=ON"
elif (( PHYMEM < 2 )); then
	echo "ERROR: You have no enough Physical Memory (min: 2Gb)"
	exit 1
fi

# Get number of processors
CPUNUM=$(getconf _NPROCESSORS_ONLN)

BASEDIR=`mktemp -d`
pushd $BASEDIR

##################################
# Preparing System
##################################

# Update packages list
apt-get update || :

# Upgrade system
apt-get -y upgrade

# Install Build Requirements
apt-get -y install git cmake g++ python-dev autotools-dev libicu-dev build-essential libbz2-dev libboost-all-dev libssl-dev libncurses5-dev doxygen libreadline-dev dh-autoreconf 

##################################
# Building Golosnode
##################################

# Create folder for installing node
mkdir golosnode

# Clone Golos
git clone https://github.com/GolosChain/golos
cd golos
git checkout master
git submodule update --init --recursive

# Build
cmake $BUILD_OPTIONS .
make -j$CPUNUM

# Preparing golosnode package
install -m 0755 programs/golosd/golosd ../golosnode/
install -m 0644 programs/golosd/snapshot5392323.json ../golosnode/
install -m 0755 programs/cli_wallet/cli_wallet ../golosnode/
cd ../golosnode
mkdir witness_node_data_dir
create_golos_config_file witness_node_data_dir/config.ini
mkdir extra
create_golosd_service_file extra/golosnode.service
cd ..


##################################
# Installing Golosnode
##################################

# Creating user for golos
/usr/bin/getent group golos >/dev/null || groupadd -r golos
/usr/bin/getent passwd golos >/dev/null || useradd -g golos -r -d /opt/golosnode -s /sbin/nologin golos
/usr/bin/getent passwd golos >/dev/null || useradd -g golos -r -d /opt/golosnode -s /sbin/nologin golos

# Installing golos to /opt/golosnode folder
cp -ra golosnode /opt/
chown -R golos:golos /opt/golosnode

# Setup golosnode as a service
install -o root -g root -m 0644 /opt/golosnode/extra/golosnode.service /lib/systemd/system/golosnode.service
systemctl preset golosnode.service
systemctl start golosnode
systemctl enable golosnode

popd # basedir


##################################
# Clean Up
##################################
rm -rf $BASEDIR/golos
rm -rf $BASEDIR/golosnode
rmdir $BASEDIR


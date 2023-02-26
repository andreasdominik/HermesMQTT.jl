#!/bin/bash
#
# Copy the framwork from .julia to the Rhasspy installation.
#
#  A. Dominik, Feb. 2023
#
PACKAGE_DIR=$1
DIR=$2 

if [[ -z $DIR ]] ; then
  echo "Usage: $0 <Rhasspy skill installation directory>"
  exit 1
fi

echo "Copying HermesMQTT to $DIR ..."

mkdir -p $DIR
mkdir -p $DIR/bin

cp -r $PACKAGE_DIR/bin $DIR
cp $PACKAGE_DIR/config.ini.template $DIR/config.ini.template
cp $PACKAGE_DIR/config.ini.template $DIR/config.ini


echo "done."
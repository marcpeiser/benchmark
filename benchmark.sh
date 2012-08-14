#!/bin/bash

echo "Checking for required dependencies"

function requires() {
  if [ `$1 >/dev/null; echo $?` -ne 0 ]; then
    TO_INSTALL="$TO_INSTALL $2"
  fi 
}
function requires_command() { 
  requires "which $1" $1 
}

TO_INSTALL=""

if [ `which apt-get >/dev/null 2>&1; echo $?` -ne 0 ]; then
  PACKAGE_MANAGER='yum'

  requires 'yum list installed kernel-devel' 'kernel-devel'
  requires 'yum list installed gcc-c++' 'gcc-c++'
  requires 'perl -MTime::HiRes -e 1' 'perl-Time-HiRes'
else
  PACKAGE_MANAGER='apt-get'
  MANAGER_OPTS='--fix-missing'
  UPDATE='apt-get update'

  requires 'dpkg -s build-essential' 'build-essential'
  requires 'perl -MTime::HiRes -e 1' 'perl'
fi

requires_command 'gcc'
requires_command 'make'
requires_command 'curl'
requires_command 'traceroute'

if [ "`whoami`" != "root" ]; then
  SUDO='sudo'
fi

if [ "$TO_INSTALL" != '' ]; then
  echo "Using $PACKAGE_MANAGER to install$TO_INSTALL"
  if [ "$UPDATE" != '' ]; then
    echo "Doing package update"
    $SUDO $UPDATE
  fi 
  $SUDO $PACKAGE_MANAGER install -y $TO_INSTALL $MANAGER_OPTS
fi

PID=`cat .sb-pid 2>/dev/null`
UNIX_BENCH_VERSION='5.1.3'
UNIX_BENCH_DIR=UnixBench-$UNIX_BENCH_VERSION
IOPING_VERSION=0.6
IOPING_DIR=ioping-$IOPING_VERSION
UPLOAD_ENDPOINT='http://promozor.com/uploads.text'

if [ ! -f $IOPING_DIR ] ; then
  if [ ! -f ioping-$IOPING_VERSION.tar.gz ] ; then
    wget -q https://github.com/nerens/Benchmark/raw/master/ioping-$IOPING_VERSION.tar.gz
  fi
  tar -xzf ioping-$IOPING_VERSION.tar.gz
fi

if [ -e "`pwd`/.sb-pid" ] && ps -p $PID >&- ; then
  echo "Benchmark job is already running (PID: $PID)"
  exit 0
fi
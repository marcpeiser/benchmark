#!/bin/bash

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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

cat > run-upload.sh << EOF
#!/bin/bash

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

rm -rf UnixBench

if ! [ -e "`pwd`/$UNIX_BENCH_DIR" ]; then
  echo "Getting UnixBench $UNIX_BENCH_VERSION..."
  wget -q https://byte-unixbench.googlecode.com/files/UnixBench5.1.3.tgz
  tar -xzf UnixBench5.1.3.tgz
  mv UnixBench $UNIX_BENCH_DIR
fi

echo "Running Benchmark as a background task."
echo "You can log out/Ctrl-C any time while this is happening (it's running through nohup)."

echo "Checking server stats..."
echo "Distro:
\`cat /etc/issue 2>&1\`
\`cat /etc/redhat-release 2>&1\`
CPU Info:
\`cat /proc/cpuinfo 2>&1\`
Disk space: 
\`df --total 2>&1\`
Free: 
\`free 2>&1\`" > benchmark-output.log

echo "Running dd I/O benchmark..."

echo "dd 1Mx1k dsync: \`dd if=/dev/zero of=sb-io-test bs=1M count=1k oflag=dsync 2>&1\`" >> benchmark-output.log
echo "dd 64kx16k dsync: \`dd if=/dev/zero of=sb-io-test bs=64k count=16k oflag=dsync 2>&1\`" >> benchmark-output.log
echo "dd 1Mx1k fdatasync: \`dd if=/dev/zero of=sb-io-test bs=1M count=1k conv=fdatasync 2>&1\`" >> benchmark-output.log
echo "dd 64kx16k fdatasync: \`dd if=/dev/zero of=sb-io-test bs=64k count=16k conv=fdatasync 2>&1\`" >> benchmark-output.log

rm -f sb-io-test

echo "Running IOPing I/O benchmark..."
cd $IOPING_DIR
make >> setup-output.log
echo "IOPing I/O: \`./ioping -c 10 . 2>&1 \`
IOPing seek rate: \`./ioping -RD . 2>&1 \`
IOPing sequential: \`./ioping -RL . 2>&1\`
IOPing cached: \`./ioping -RC . 2>&1\`" >> ../benchmark-output.log
cd ..

#function download_benchmark() {
#  echo "Benchmarking download from \$1 (\$2)"
#  DOWNLOAD_SPEED=\`wget -O /dev/null \$2 2>&1 | awk '/\\/dev\\/null/ {speed=\$3 \$4} END {gsub(/\\(|\\)/,"",speed); print speed}'\`
#  echo "Got \$DOWNLOAD_SPEED"
#  echo "Download \$1: \$DOWNLOAD_SPEED" &>> sb-output.log
#}

#echo "Running bandwidth benchmark..."

#download_benchmark 'Cachefly' 'http://cachefly.cachefly.net/100mb.test'
#download_benchmark 'Linode, Atlanta, GA, USA' 'http://atlanta1.linode.com/100MB-atlanta.bin'
#download_benchmark 'Linode, Dallas, TX, USA' 'http://dallas1.linode.com/100MB-dallas.bin'
#download_benchmark 'Linode, Tokyo, JP' 'http://tokyo1.linode.com/100MB-tokyo.bin'
#download_benchmark 'Linode, London, UK' 'http://speedtest.london.linode.com/100MB-london.bin'
#download_benchmark 'OVH, Paris, France' 'http://proof.ovh.net/files/100Mio.dat'
#download_benchmark 'SmartDC, Rotterdam, Netherlands' 'http://mirror.i3d.net/100mb.bin'
#download_benchmark 'Hetzner, Nuremberg, Germany' 'http://hetzner.de/100MB.iso'
#download_benchmark 'iiNet, Perth, WA, Australia' 'http://ftp.iinet.net.au/test100MB.dat'
#download_benchmark 'Leaseweb, Haarlem, NL, USA' 'http://mirror.leaseweb.com/speedtest/100mb.bin'
#download_benchmark 'Softlayer, Singapore' 'http://speedtest.sng01.softlayer.com/downloads/test100.zip'
#download_benchmark 'Softlayer, Seattle, WA, USA' 'http://speedtest.sea01.softlayer.com/downloads/test100.zip'
#download_benchmark 'Softlayer, San Jose, CA, USA' 'http://speedtest.sjc01.softlayer.com/downloads/test100.zip'
#download_benchmark 'Softlayer, Washington, DC, USA' 'http://speedtest.wdc01.softlayer.com/downloads/test100.zip'

#echo "Running traceroute..."
#echo "Traceroute (cachefly.cachefly.net): \`traceroute cachefly.cachefly.net 2>&1\`" >> sb-output.log

#echo "Running ping benchmark..."
#echo "Pings (cachefly.cachefly.net): \`ping -c 10 cachefly.cachefly.net 2>&1\`" >> sb-output.log

echo "Running UnixBench benchmark..."
cd $UNIX_BENCH_DIR
./Run &>> ../benchmark-output.log
cd ..

echo "Completed! Your benchmark results are in benchmark-output.log"
kill -15 \`ps -p \$\$ -o ppid=\` &> /dev/null

exit 0
EOF

chmod u+x run-upload.sh

rm -f sb-script.log
nohup ./run-upload.sh &>> sb-script.log & &>/dev/null

echo $! > .sb-pid

tail -f sb-script.log
#!/bin/bash

SGPATH=$1
if [ -z "$SGPATH" ]
then
  SGPATH=/home/mquinson/install-3.7
fi

maxpow=30
clSize=1024
degree=64
cmd="./goal_test --cfg=network/model:SMPI platform.xml"

timefmt="clock:%e user:%U sys:%S swapped:%W exitval:%x max:%Mk avg:%Kk # %C"

echo "Check the CPU frequency:"
cpufreq-info | grep "current policy:"

echo "(recompile the binary against $SGPATH)"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SGPATH/lib"
gcc goal_test.c -lsimgrid -L$SGPATH/lib -I$SGPATH/include -o goal_test

test -e tmp || mkdir tmp
me=tmp/`hostname -s`

function roll() {
  max=$1
  rand=`dd if=/dev/urandom count=1 2> /dev/null | cksum | cut -f1 -d" "`
  res=`expr $rand % $max`
  echo $res
}

for pow in `seq 1 25` ; do
  echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

  #pow=`roll $maxpow`
  size=`dc -e "2 $pow ^p"`

  echo "pow:$pow size:$size clusterSize:$clSize degree:$degree "
  ./create_hierarchical_clusters.pl $pow $clSize $degree > platform.xml
#  sed "s/THESIZE/$size/" platform.xml.in > platform.xml

  killall -KILL goal_test 2>/dev/null

  # pow:$pow only added to allow tracing of processes in top(1) output
  /usr/bin/time -f "$timefmt" -o $me.timings $cmd pow:$pow

  if grep "Command terminated by signal" $me.timings ; then
    echo "Damn, error detected:"
  elif grep "Command exited with non-zero status" $me.timings ; then
    echo "Damn, error detected:"
  else
    echo
    echo -n "XXXX PRECIOUS_RESULT XXXX pow:$pow size:$size "
  fi
  cat $me.timings

done

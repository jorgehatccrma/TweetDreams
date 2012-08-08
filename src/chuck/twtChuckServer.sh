#!/bin/bash


##########################################################
# 
# This script should be working, but has been deprecated
# 
##########################################################


# get the local machine's IP address
ip=$(ipconfig getifaddr en0)				# wired
#ip=$(ipconfig getifaddr en1)				# wifi's
echo $ip

# kill all instances of chuck that might be running
k="killall chuck"
$k

# ip addresses for other machines
proc_client="192.168.176.21"
pyth_client="localhost"


# run the chuck patch

TEST=0
while getopts "t" OPTION
do
	TEST=1
done

if [ "$TEST" = 0 ]
then
	echo "Expecting real tweets ..."
	chuck="chuck --bufsize2048 twtNodeSynth3.ck twtSynthControlLOCAL3.ck twtSynthControlMASTER.ck:$pyth_client:$proc_client" 
	#chuck="chuck --bufsize2048 -c8 --dac3 twtNodeSynth3.ck twtSynthControlLOCAL3.ck twtSynthControlMASTER.ck:$pyth_client:$proc_client" 
	#chuck="chuck --bufsize2048 -c8 --dac2 twtNodeSynth3.ck twtSynthControlLOCAL3.ck twtSynthControlMASTER.ck:$pyth_client:$proc_client" 


else
	echo "Using test script ..."
	# chuck="chuck --bufsize2048 twtNodeSynth.ck twtSynthControlLOCAL.ck twtSynthControlMASTER.ck twtTest5.ck"
  # chuck="chuck --bufsize2048 twtNodeSynth2.ck twtSynthControlLOCAL2.ck twtSynthControlMASTER.ck twtTest5.ck"
  chuck="chuck --bufsize2048 --srate44100  twtNodeSynth3.ck twtSynthControlLOCAL3.ck twtSynthControlMASTER.ck twtTest5.ck"
  #chuck="chuck --bufsize2048 twtNodeSynth3.ck twtSynthControlLOCAL3.ck twtSynthControlMASTER.ck twtTest5.ck"
fi

$chuck

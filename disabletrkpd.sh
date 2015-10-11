#!/bin/bash
##############################################################
#  This script disables the trackpad for a given time if the 
#  pointing stick of a laptop is used.  This is meant to prevent
#  accidental touches of the trackpad while using the pointing
#  stick.
#
#  Add to startup programs ("sudo /path/to/disabletrkpd.sh").
#  For security, be sure that unpriveledged users do not have 
#  write access to this script file before adding it to visudo 
#  exceptions (this is so that the script can run without being 
#  prompted for a password.)  
#
#  Note that specific details, (specifically the hardware names) 
#  in your machine will likely vary. Run command "xinput" to find 
#  the name of your device.
##############################################################


##############################################################
#  Fields meant for user-modification
##############################################################

#give a time (in ms) for the program to wait after the last 
#trackstick use before reactivating the touchpad
TIMEOUT=1500

#Hardware names. Run command "xinput" to find the name of 
#your device.
touchpad_name='SynPS/2 Synaptics TouchPad'
trackpoint_name='TPPS/2 IBM TrackPoint'

#time (in s) to wait between successive checks of trackpoint use
WAIT_TIME=0.1
##############################################################
#  Functions
##############################################################
function enable_trkpd
{
    xinput -set-prop "$touchpad_name" "Device Enabled" 1
    trkpd_state="on"
}

function disable_trkpd
{
    xinput -set-prop "$touchpad_name" "Device Enabled" 0
    trkpd_state="off"
}

#parse the /proc/bus/input/devices file for the trackpoint handler filename
function get_trkpt_handler
{
    echo `grep -i "$trackpoint_name" -A 10 /proc/bus/input/devices | grep "event[0-9]." -o`
}

function get_time
{
    echo `date +"%s%3N"`
}

#re-evaluate the checksum of the temporary file
function get_checksum
{
    echo `md5sum /tmp/disabletrkpd_mousemove | awk '{print $1}'`
}


###############################################################
#  Initialize temp file and related actions
###############################################################
trackpoint_handler=$(get_trkpt_handler)

#initialize temp file
cat /dev/input/$trackpoint_handler > /tmp/disabletrkpd_mousemove &

#initialize counter to prevent temp file from growing
counter="0"

#iterations allowed before clearing the temp file
ITER_BETWEEN_CLEAR=300



##############################################################
#  Ensure trackpad is on, before entering main loop
##############################################################
enable_trkpd
new_checksum=$(get_checksum)

while true ; do 
    counter="$[ $counter + 1 ]"

    old_checksum=$new_checksum
    new_checksum=$(get_checksum)
    nowtime=$(get_time)
    
    #Logic for deciding to turn off/on the trackpad
    if [ $trkpd_state = "off" -a "$nowtime" -gt "$[ $offtime + $TIMEOUT ]" ]; then
        enable_trkpd
    elif [ "$old_checksum" != "$new_checksum" ]; then
        disable_trkpd
        offtime=$(get_time)
    fi
	
    #check for count to keep poll file smaller
    if [ "$counter" -ge "$ITER_BETWEEN_CLEAR" ]; then
        echo '' > /tmp/disabletrkpd_mousemove
        counter="0"
        new_checksum=$(get_checksum)
    fi

    sleep $WAIT_TIME
done

#/bin/bash

PORT="$1"
ACTION="$2"

#######
INSTALL="false"
DEVICE_NAME="2109:2817 VIA Labs, Inc. USB2.0 Hub, USB 2.10, 4 ports"
DEVICE_ID_REGEX='hub (.*) \['
PORT_STATUS_REGEX=".*Port $PORT: [0-9]{4} (off|power)$"


function getID () {

	local device="$1"

	local deviceString=$(uhubctl | grep "$device")

	[[ $deviceString =~ $DEVICE_ID_REGEX ]]

	local usbID=${BASH_REMATCH[1]}

	echo "$usbID"

}

function switchPort () {

	local usbID=$1
	local port=$2
	local status=$3

	echo $(uhubctl -l $usbID -a $status -p $port -r 200)

}

function checkResponse () {

	local response="$1"

	[[ $response =~ $PORT_STATUS_REGEX ]]

	local portStatus=${BASH_REMATCH[1]}

	echo "$portStatus"


}


if [[ "$ACTION" = "on" || "$ACTION" = "off" ]]; then
   
	usbID=$(getID "$DEVICE_NAME")
	
	echo "Switching hub $usbID port $PORT to $ACTION"	

	result=$(switchPort "$usbID" "$PORT" "$ACTION")

	newStatus=$(checkResponse "$result")


	if [[ "$ACTION" = "on" && "$newStatus" = "power" ]] || [[ "$ACTION" = "off" && "$newStatus" = "off" ]]; then

		echo "Hub $usbID port $PORT is $ACTION"
		exit 0

	else

		echo "ERROR: $ACTION was sent, hub $usbID port $PORT is $newStatus"
		exit 1

	fi

else

	echo "Call: ./switchUsbPower.sh \$port \$status"
	echo -e  "\\t./switchUsbPower.sh {1-4} {on|off}"
	echo -e  "\\t./switchUsbPower.sh 1 on"
	exit 1

fi
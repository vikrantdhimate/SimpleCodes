#!/bin/bash
# ===========================================================================================================================

# Author: Vikrant Dhimate
# Create date: 09-07-2018
# Description: The script after execution  delete all existing neworks

# ===========================================================================================================================
ethernetNetworks=yes
fcoeNetworks=yes
fcNetworks=yes
#Generating trusted token
auth_header=$(/ci/bin/get-trustedtoken.sh)

#Getting x_api_version dynamically
x_api_version=`jq '.currentVersion' /ci/etc/partner-api-version-info.json`;
if [ "$x_api_version" == "null" ] || [ -z "$x_api_version" ];
then
    x_api_version=600
fi
#echo $x_api_version

if [ $ethernetNetworks == 'yes' ]
then
	res=$( psql -U postgres -d cidb -t -c "SELECT id FROM \"crm-core\".networkimpl")
	echo "List of Ids"
	for word in $res
	do
     		curl -H 'auth: '${auth_header} -H 'Content-Type: application/json' -H 'X-API-Version: '${x_api_version} -X DELETE -i https://localhost/rest/ethernet-networks/$word
		
	done
	echo "Delete Ethernet Networks Completed"
fi

if [ $fcoeNetworks == 'yes' ]
then
	res=$( psql -U postgres -d cidb -t -c "SELECT id FROM \"crm-core\".fcoenetworkentity")
	echo "List of Ids"
	for word in $res
	do
     		curl -H 'auth: '${auth_header} -H 'Content-Type: application/json' -H 'X-API-Version: '${x_api_version} -X DELETE -i https://localhost/rest/fcoe-networks/$word
		
	done
	echo "Delete Fcoe Networks Completed"
fi

if [ $fcNetworks == 'yes' ]
then
	res=$( psql -U postgres -d cidb -t -c "SELECT id FROM \"crm-core\".fc_network")
	echo "List of Ids"
	for word in $res
	do
     		curl -H 'auth: '${auth_header} -H 'Content-Type: application/json' -H 'X-API-Version: '${x_api_version} -X DELETE -i https://localhost/rest/fc-networks/$word
		
	done
	echo "Delete Fc Networks Completed"
fi




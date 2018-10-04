#!/bin/bash
# ===========================================================================================================================

# Author: Vikrant Dhimate
# Create date: 28-06-2018
# Description: The script after execution  shows all orphan LIs, removes all orphan snmp configurations, creates a dummy snmpconfiguration \
#              and associates it with existing orphan LI <provided as input to script>

# ===========================================================================================================================

echo "--------------------------------------------------------------------------------------------------------------"
echo -e "\e[1;31mPlease provide LI id from Below orphan LI List :\e[0m"
echo "--------------------------------------------------------------------------------------------------------------"
echo -e "\033[0m"

echo -e "\033[32m Orphan LI/s :"
echo -e "\033[0m"

#Showing List of all Orphan LIs with name
psql -U postgres -d cidb -c "SELECT id,name FROM  \"crm-core\".logicalswitchentity WHERE id NOT IN (SELECT SPLIT_PART(logicalinterconnecturi,'/',4) FROM  perm.logicalinterconnect)"

res=$( psql -U postgres -d cidb -t -c "SELECT count(1) FROM \"crm-core\".logicalswitchentity WHERE id NOT IN (SELECT SPLIT_PART(logicalinterconnecturi,'/',4) FROM  perm.logicalinterconnect)")
echo $res

if [ "$res" -gt 0 ]
then
        echo -n -e "\e[1;31mEnter id of LI to be deleted: "
    echo -e "\033[0m"
        read userinput

        #validating input LI Id
        exists=$( psql -U postgres -d cidb -t -c "SELECT count(1) FROM \"crm-core\".logicalswitchentity WHERE id='${userinput}'")

        if [ "$exists" -gt 0 ]
        then
                psql -U postgres -d cidb -f updateSnmpConfig.sql -v LI="'$userinput'"
                echo -e "\033[32m\n"

                #Generating trusted token
                auth_header=$(/ci/bin/get-trustedtoken.sh)

                #Getting x_api_version dynamically
                x_api_version=`/usr/local/bin/jq '.currentVersion' /ci/etc/partner-api-version-info.json`;
                if [ "$x_api_version" == "null" ] || [ -z "$x_api_version" ];
                then
                        x_api_version=600
                fi
                #echo $x_api_version

                curl -H 'auth: '${auth_header} -H 'Content-Type: application/json' -H 'X-API-Version: '${x_api_version} -X DELETE -i https://localhost/rest/logical-interconnects/$userinput
                echo -e "\033[0m\n"
                echo -e "\e[1;35mLI Delete Request sent successfully. Deleting requested LI { id : $userinput  }\n"
    else
                echo -e "\033[0m\n"
                echo -e "\e[1;35mThere are no LIs with specified { id : $userinput }. Please verify Id.\n"
        fi
else
        echo -n -e "\e[1;35mThere are no Orphan LIs \n"
fi
echo -e "\033[0m"

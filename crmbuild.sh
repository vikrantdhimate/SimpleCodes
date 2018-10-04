#!/bin/bash
# ===========================================================================================================================

# Author: Vikrant Dhimate
# Create date: 09-07-2018
# Description: The script can build and deploy (jar/war depending on current folder) with options, sync UI and Connect to any ip using ssh.

# ===========================================================================================================================

#start

#Commands and General Description
usage() 
{
echo "                                                                                                                         "
echo "                                                                                                                         "
echo "                                                                                                                         "
echo "========================================================================================================================="
echo "===----------------------------------------------- BUILD SIMPLIFIED 1.0 ----------------------------------------------==="
echo "===----------------------------------- Simplify Connect,Build,upload,Restart -----------------------------------------==="
echo "========================================================================================================================="
	echo " Usage   : crmbuild.sh -ip=<ipaddress> -b=<build> -m=<mode> -t=<test> -rf=<package> -T=<No Of Threads>"
	echo " Usage   : crmbuild.sh -ip=<ipaddress> -syncui=<syncui>"
	echo " Usage   : crmbuild.sh -ip=<ipaddress> (open ssh session)"
	echo " Usage   : crmbuild.sh -ip=<ipaddress> -s=<schematic name> (FTS with schematic)"
	echo " Usage   : crmbuild.sh -ipaddress=<ipaddress> -build=<build> -mode=<mode> -test=<test> -resumefrom=<package> -Threads=<No Of Threads>"
	echo " build   : yes/no"
	echo " mode    : online/offline"
	echo " test    : full/compile/skip"
	echo " package : package_name (optional) "
	echo " syncui  : yes/no"
	echo " schematic name  : synergy_2encl"
    exit 0

}

#command Examples
helpwithexamples() 
{
	echo " Usage    : crmbuild.sh -ip=<ipaddress> -b=<build> -m=<mode> -t=<test> -rf=<package> -T=<No Of Threads>"
	echo " Examples :"
	echo " crmbuild.sh -ip=<ipaddress> (ssh session)"
	echo " crmbuild.sh -ip=<ipaddress> -syncui=yes(sync UI)"
	echo " crmbuild.sh -ip=<ipaddress> -s=synergy_2encl(FTS with schematic)"
	echo " crmbuild.sh -ip=<ipaddress> -b=yes -m=online -t=include -rf=pkg (resume online from pk)"
	echo " crmbuild.sh -ip=<ipaddress> -b=yes -m=offline -t=skip (full offline build with skiptest, skip compilation)"
	echo " crmbuild.sh -ip=<ipaddress> -b=no (only copy war and restart RM)"
    exit 0
}

sshestablish()
{
if [ "$ipaddressflag" -eq 1 ]
then
	echo "-------------------------------------------------------------------------------------------------------------------------"
	echo "copying ssh key..."    	
	ssh-copy-id -i ~/.ssh/id_rsa.pub root@$ipaddress
	lastcommandstat=$?
	echo $lastcommandstat
	if [ "$lastcommandstat" -ne 0 ];
	then
		ssh-keygen -R $ipaddress
		ssh-copy-id -i ~/.ssh/id_rsa.pub root@$ipaddress
	fi
fi
}
#help input
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "" || "$1" == "-help" ]];
then
	usage
fi
echo "                                                                                                                         "
echo "                                                                                                                         "
echo "                                                                                                                         "
echo "========================================================================================================================="
echo "===----------------------------------------------- BUILD SIMPLIFIED 1.0 ----------------------------------------------==="
echo "===----------------------------------- Simplify Connect,Build,upload,Restart -----------------------------------------==="
echo "========================================================================================================================="
ipaddressflag=0
schematicflag=0
reimageflag=0
buildflag=0
modeflag=0
testflag=0
resumeflag=0
threadflag=0
lastcommandstatus=0
syncflag="no"
lastui=0
mode="online"

#pattern-matching
for i in "$@"
do
	case $i in
	    -ip=* | --ipaddress=* | --ip=* | -ipaddress=* )
		ipaddress="${i#*=}"
		ipaddressflag=1
		#echo $ipaddress
		;;
		-s=* | --schematic=* | --s=* | -schematic=* )
		schematic="${i#*=}"
		schematicflag=1
		#echo $schematic
		;;
 	    -b=* | --build=* | --b=* | -build=* )
		build="${i#*=}"
		buildflag=1
		#echo $build
		;;
	    -m=* | --mode=* | --m=* | -mode=* )
		mode="${i#*=}"
		modeflag=1
		#echo $mode
 		;;
	    -t=* | --test=* | --t=* | -test=* )
		skiptest="${i#*=}"
		testflag=1
		#echo $skiptest
		;;
        -rf=* | --resumefrom=* | --rf=* | -resumefrom=* )
		resumeflag=1
		resumefrom="${i#*=}"
		#echo $resumefrom
		;;
		-T=* | --Thread=* | -thread=* )
		threadflag=1
		threads="${i#*=}"
		#echo $resumefrom
		;;
		-syncui=* | --syncui=* | --ui=* | -ui=* )
		syncflag=1
		#echo $syncflag
		;;
		-reimage=* | --reimage=* )
		reimageflag=1
		#echo $syncflag
		;;
        --default ) 
		helpwithexamples
		;;
	*)
		echo "Please verify supported commands"
		helpwithexamples
		;;
esac
done

echo "                                                                                                                         "
echo "                                                                                                                         "
echo "                                                                                                                         "
echo "                                                                                                                         "
echo "Vm IPaddress : $ipaddress"
echo "																														   "


if [ "$schematicflag" -eq 1 ];
then
	sshestablish	
	command="dcs stop"
	ssh root@$ipaddress $command
	command="dcs start /dcs/schematic/"$schematic" cold"
	ssh root@$ipaddress $command
	command="dcs status"
	ssh root@$ipaddress $command
	fts="curl -ik https://${ipaddress}/perm/rest/tbird/atlas/fts"
	sleep 20
	echo $fts
	ssh root@$ipaddress $fts
	
elif [ "$reimageflag" -eq 1 ];
then
	java -jar "C:\opt\myscripts\ReimageOneview-v3.jar"
	
elif [[ "$syncflag" -eq 1 && "$ipaddressflag" -eq 1 ]];
then
	echo "-------------------------------------------------------------------------------------------------------------------------"
	echo "syncing UI"
	echo "-------------------------------------------------------------------------------------------------------------------------"
	cd ../ui-js
	./sync.sh root@$ipaddress
	#echo "syncing UI faile with status :"
	lastcommandstatus =  $?
	if [ "$lastcommandstatus" -ne 0 ];
	then
		mvn clean initialise
		./sync.sh root@$ipaddress
		exit 
	fi
	
elif [ "$buildflag" -eq 0 ];
then
	sshestablish
	ssh root@$ipaddress

else
	sshestablish
    if [ "$build" == "yes" ]
    then	
		if [ "$modeflag" -eq 1 ]
		then
			if [[ -z "$mode" || "$mode" == " " ]];
			then
				#echo -n 'Mode -> 1: offline   2:online'
				#read mode
				helpwithexamples
			fi
		fi

		if [ "$testflag" -eq 1 ]
		then
			if [[ -z "$skiptest" || "$skiptest" == " " ]];
			then
				#echo -n 'Test-> 1:include   2:compileonly   3:skip'
				#read skiptest
				helpwithexamples
			fi
		fi	

		command="mvn clean install "
		if [ "$mode" == "offline" ]; 
		then
			command=$command" -o"
		fi

		if [ "$skiptest" == "compile" ];
		then
			command=$command" -DskipTests"
		elif [ "$skiptest" == "skip" ];
		then
			command=$command" -Dmaven.test.skip=true"
		fi	

		#applicable only if -rf= is provided
		if [ "$resumeflag" -eq 1 ];
		then
			if [ -z "$resumefrom" ];
			then
				helpwithexamples
				exit 0
			else
				command=$command" -rf  :"$resumefrom
			fi
		fi
			
		#applicable only if -T= is provided
		if [ "$threadflag" -eq 1 ];
		then
			if [ -z "$threads" ];
			then
				helpwithexamples
				exit 0
			else
				command=$command" -T "$threads
			fi
		fi

		echo "-------------------------------------------------------------------------------------------------------------------------"
		echo $command
		echo "-------------------------------------------------------------------------------------------------------------------------"

		if [ -z "$build" ];
		then
			#echo "build -> yes :1  No:2"
			#read build
			helpwithexamples
		fi
			
		echo "-------------------------------------------------------------------------------------------------------------------------"
		echo "building workspace..."
		echo "wait...   After building it will deploy war on VM and restart RM"
		echo "-------------------------------------------------------------------------------------------------------------------------"
		$command
		lastcommandstatus=$?
	fi
	
	if [ "$lastcommandstatus" -eq 0 ];
	then
		if [ "$ipaddressflag" -eq 1 ];
		then
			echo "-------------------------------------------------------------------------------------------------------------------------"
			echo "copying ..."
			result=${PWD##*/}
			copyCommand="scp ./crm-core-ws/target/crm-core.war root@"$ipaddress":/ci/webapps"			
            if [ $result == "connectivity-services" ];
		    then
				copyCommand="scp ./crm-core-ws/target/crm-core.war root@"$ipaddress":/ci/webapps"							
			else
			    res=`find target/ -name *-SNAPSHOT.jar`	
				echo $res
				size=${#res} 
				currentJar=${res:7:$size-33} 
				
				jarname="$(cut -d'/' -f2 <<<"$res")"

				#echo "Final name for currentjar : " $jarname
				copyCommand="scp ./target/"
				copyCommand=$copyCommand""$jarname" root@"$ipaddress":/ci/webapps/crm-core/WEB-INF/lib/"$currentJar".jar"
			fi	
			$copyCommand
			echo "Execution of " $copyCommand " is " $?
			echo "restarting webapp"
			ssh root@$ipaddress '/ci/bin/restart-webapp crm-core'
			echo "-------------------------------------------------------------------------------------------------------------------------"
		else
			echo "please provide vm-<ip>"
		fi
	fi
fi


#end

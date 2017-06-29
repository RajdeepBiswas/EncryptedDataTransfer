#!/bin/bash
#./hdfs_data_move.sh export /tmp/zone_encr_test

if [[ ! "$#" =~ ^(2|3)$ ]]
then
	echo -e "\nError: Check arguments. Possible argument values are export keys OR import keys OR export \gencrypted\myFolder OR create \gencrypted\myFolder myKey\n"
	exit 1
elif [[ ! "$1" =~ ^(export|import|create)$ ]]
then
	echo -e "\nError: First argument needs to be export or import or create. Full argument set like export keys OR import keys OR export \gencrypted\myFolder OR import \gencrypted\myFolder\n"
	exit 1
fi

#############################################################################
####EXAMPLE sequence of commands
#In source cluster
###./hdfs_data_move.sh export keys
#In destination cluster
###./hdfs_data_move.sh import keys
#In destination cluster
###./hdfs_data_move.sh create /tmp/zone_encr_test testKey123
#In source cluster
###./hdfs_data_move.sh export /tmp/zone_encr_test
#############################################################################

function exportKey {
	#encryptedFlag=1
	cd /usr/hdp/current/ranger-kms/
	rm -f ProdCluster123.keystore
	./exportKeysToJCEKS.sh ProdCluster123.keystore
	chmod 777 ProdCluster123.keystore
	rm -f /tmp/ProdCluster123.keystore
	cp /usr/hdp/current/ranger-kms/ProdCluster123.keystore /tmp
	sudo -u hdfs hdfs dfs -rm -f /tmp/ProdCluster123.keystore
	hdfs dfs -copyFromLocal /tmp/ProdCluster123.keystore /tmp
	sudo -u hdfs hadoop distcp -update hdfs://cluster2:8020/tmp/ProdCluster123.keystore hdfs://cluster1:8020/tmp
	echo -e "\nPlease run import keys in destination cluster!!!\n"
}

function importKey {
	cd /usr/hdp/current/ranger-kms/
	rm -f /tmp/ProdCluster123.keystore
	sudo -u hdfs hdfs dfs -copyToLocal /tmp/ProdCluster123.keystore /tmp
	sudo -u hdfs chmod 777 /tmp/ProdCluster123.keystore
	./importJCEKSKeys.sh /tmp/ProdCluster123.keystore jceks
	echo -e "\nPlease run create encrypted directory!!!\n"
}

function createEncryptedDirectory {
	sudo -u hdfs hdfs dfs -mkdir $1
	sudo -u hdfs hdfs crypto -createZone -keyName $2 -path $1
	#sudo -u hdfs hdfs crypto -listZones
	sudo -u hdfs hdfs dfs -chown -R hive:hdfs $1
	sudo -u hive hdfs dfs -chmod -R 750 $1
	echo -e "\nPlease run export directory in source cluster1!!!\n"	
}

function exportDirectory {
	sudo -u hdfs hadoop distcp -update hdfs://cluster2:8020/.reserved/raw/${1} hdfs://cluster1:8020/.reserved/raw/${1}
	echo -e "\nExport Processing finished.\n"	
}

## Code Begins here

###############################################################
## STEPS:--
## --------
## 1. Export keys
## 2. Import keys
## 3. Create encrypted directories in destination cluster
## 4. Distcp encrypted directories in destination cluster
###############################################################
baseDir=/root/scripts/dataCopy
cd $baseDir
operation=$1
folderName=$2

zone=$(sudo -u hdfs hdfs crypto -listZones | grep $folderName)
keyName=""
if [ ! -z "$zone" ]
then
	encryptedFlag=1
	keyName=$(echo $zone | cut -d ' ' -f2)
else
	encryptedFlag=0
fi

#echo -e "$operation \n $folderName \n $keyName\n"
if [ $folderName == "keys" ]
then
	if [ $operation == "export" ]
	then
		exportKey
	else
		importKey
	fi
elif [ $operation == "create" ]
then
	createEncryptedDirectory $folderName $3
	
elif [ $operation == "export" ]
then
	exportDirectory $folderName
else
	echo "Nothing done"
	exit 1
fi

exit

## Code Ends  here

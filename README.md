# EncryptedDataTransfer
HDFS Encrypted zone inter-cluster copy automation

## Synopsis:
In addition to authentication and access control, data protection adds a robust layer of security, by making data unreadable in transit over the network or at rest on a disk. Encryption helps protect sensitive data, in case of an external breach or unauthorized access by privileged users.  
The automation of this task is expected to save close to 4-6 hours of manual intervention per occurrence.  
  
## Script (common code) location:
cluster1:  
Under root@cluster1 /root/scripts/dataCopy/hdfs_data_move.sh  
cluster2:  
Under root@cluster2 /root/scripts/dataCopy/hdfs_data_move.sh  

## Usage:
**Scenario1:  For copying encrypted hdfs folder from cluster2 to cluster1**
Example folder name: /tmp/zone_encr_test encrypted with key “testKey123”  
In cluster2:  
sudo su root  
cd /root/scripts/dataCopy/  
./hdfs_data_move.sh export keys  
After above execution finishes:  

In cluster1:  
sudo su root  
cd /root/scripts/dataCopy/  
./hdfs_data_move.sh import keys  
After above execution finishes:  

./hdfs_data_move.sh create /tmp/zone_encr_test testKey123  
After above execution finishes:  

In cluster2:  
sudo su root  
cd /root/scripts/dataCopy/  
./hdfs_data_move.sh export /tmp/zone_encr_test  




## Glossary: Quick set up of HDFS encryption zone
### How to set up an encryption zone:  
sudo su hdfs  
hdfs dfs -mkdir /tmp/zone_encr_test  
hdfs crypto -createZone -keyName testKey123 -path /tmp/zone_encr_test  
hdfs crypto -listZones  
hdfs dfs -chown -R hive:hdfs /tmp/zone_encr_test  
exit  
sudo su hive  
hdfs dfs -chmod -R 750 /tmp/zone_encr_test  
hdfs dfs -copyFromLocal /home/hive/encr_file.txt /tmp/zone_encr_test  
hdfs dfs -cat /tmp/zone_encr_test/encr_file.txt  
exit  
sudo su hdfs  
hdfs dfs -cat /tmp/zone_encr_test/encr_file.txt  
NOTE: The above command will fail although it ran as hdfs superuser  

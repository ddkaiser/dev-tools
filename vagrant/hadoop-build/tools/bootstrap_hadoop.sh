#!/usr/bin/env bash

#
# Variables
#
HADOOP_SRC_DIR=/src/hadoop
HADOOP_STG_DIR=/staging/hadoop
ANSIBLE_HADOOP_STG_DIR=/staging/ansible-hadoop

#
# Installing required build deps
#
echo "#### Installing openssl, cmake, and protbuf"
yum install openssl-devel cmake protobuf-devel rsync -y

#
# Building Hadoop
#
echo "#### Staging code to $HADOOP_STG_DIR"
if [ -d $HADOOP_STG_DIR ]; then
  rm -rf $HADOOP_STG_DIR
fi
mkdir -p $HADOOP_STG_DIR
rsync -avP $HADOOP_SRC_DIR/* $HADOOP_STG_DIR

echo "#### Running the hadoop build"
cd $HADOOP_STG_DIR && mvn clean install package -Pnative,dist -Dtar -Dcontainer-executor.conf.dir=../etc/hadoop -DskipTests -Dmaven.javadoc.skip=true

echo "#### Staging the hadoop archive"
rsync -avP $HADOOP_STG_DIR/hadoop-dist/target/hadoop-*.tar.gz /tmp/hadoop.tar.gz

#
# Installing and starting Hadoop
#
echo "#### Staging ansible-hadoop"
if [ -d $ANSIBLE_HADOOP_STG_DIR ]; then
  rm -rf $ANSIBLE_HADOOP_STG_DIR
fi
git clone https://github.com/ddkaiser/ansible-hadoop.git $ANSIBLE_HADOOP_STG_DIR

echo "#### Running the ansible hadoop provisioning playbook"
ansible-playbook --private-key /root/.ssh/ansible -i $ANSIBLE_HADOOP_STG_DIR/inventory $ANSIBLE_HADOOP_STG_DIR/hadoop.yml

exit 0

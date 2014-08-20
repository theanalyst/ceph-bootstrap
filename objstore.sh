#!/bin/sh
# A hack, create an object store service
set -x

keystone service-list |  grep -Fq swift
if [ $? ]
then
    service_id=$(keystone service-list | grep swift | cut -d "|" -f 2 | tr -d " ")
    for i in $service_id
        do
          keystone service-delete $i
        done
fi

keystone service-create --name swift --type object-store
service_id=$(keystone service-list | grep swift | cut -d "|" -f 2 | tr -d " ")
my_url="http://`(hostname -f)`/swift/v1"
keystone endpoint-create --region RegionOne --service-id $service_id --publicurl ${my_url} --internalurl $my_url --adminurl $my_url

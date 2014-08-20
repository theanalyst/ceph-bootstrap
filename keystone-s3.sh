#!/bin/sh
export S3_ACCESS_KEY_ID=$(keystone ec2-credentials-list | grep admin | cut -d "|" -f 3 | tr -d " ")
export S3_SECRET_ACCESS_KEY=$(keystone ec2-credentials-list | grep admin | cut -d "|" -f 4 | tr -d " ")
export S3_HOSTNAME=$(hostname -f)

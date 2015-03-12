#!/bin/bash
set -x
pool_src=$1
pool_dst=$2
l=$(sudo rados -p $pool_src ls)
mkdir /tmp/copy-$pool_src && cd $_
for x in $l;
do
        sudo rados -p $pool_src get $x $x
        sudo rados -p $pool_dst put $x $x
done

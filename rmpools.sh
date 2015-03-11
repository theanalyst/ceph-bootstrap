#!/bin/bash

# DONT EVER USE THIS IN PRODUCTION, THIS WILL REMOVE YOUR POOLS AND DATA
for i in $(sudo rados lspools | grep $1)
    do sudo rados rmpool $i $i --yes-i-really-really-mean-it
done

#!/usr/bin/env bash

set -x

# get the create_container function
. create-container.sh

create_container miner 412 withsk
create_container devel 415 withsk


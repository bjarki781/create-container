#!/usr/bin/env bash

set -x

# get the create_container function
. create-container.sh

create_container miner 412 true
create_container devel 404 true


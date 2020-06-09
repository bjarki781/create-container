#!/usr/bin/env bash

set -x

# get the create-container function
. create-container.sh

create-container grafari 412 true
create-container throun  404 true


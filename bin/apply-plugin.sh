#!/bin/bash

#
# Script for applying plugins to Moai
# Usage: Run from Moai SDK's root directory:
#
# apply-plugin.sh <plugin-name>
#
# Available plugins:
# * moai-android-facebook
#

set -e

# read command line
usage="usage: $0 <plugin-name>"

if [ ! $# -eq 1 ]; then
    echo >&2 \
        $usage
    exit 1;
fi

cd `dirname $0`
../util/moaiutil apply-plugin $1

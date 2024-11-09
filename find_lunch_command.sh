#!/bin/bash

BUILD_ID=""
DEVICE_NAME=$1

if [ -z $1 ] ; then
  echo "ERROR: Must define device name like"
  echo "find_lunch_command.sh zenfone7"
  exit 1
fi

# old build config file
#
VERSIONS_DEFAULTS_MK="./build/make/core/version_defaults.mk"

# new build config files
#
BUILD_RELEASE_DIR="build/release"

RELEASE_CONFIG_MAP_FILE="${BUILD_RELEASE_DIR}/release_config_map.mk"

# check if the current directory is the top level of a repository for Android
#
grep  "https://android.googlesource.com" .repo/manifests/default.xml 2>/dev/null >/dev/null
if [ $? -ne 0 ] ; then
  echo "ERROR: The directory \"${PWD}\" is not the top level of a repository for Android"
  THISRC=100
  exit 1
else
    if [ -r "${VERSIONS_DEFAULTS_MK}" ]  ;then
        THISRC=1
    elif [ -r "${RELEASE_CONFIG_MAP_FILE}" ] ; then
        BUILD_ID="$( grep declare-release-config "${RELEASE_CONFIG_MAP_FILE}"  | tr "," " " | awk '{ print $3}' )"
        if [ -z "$BUILD_ID" ]; then
           str=$(find vendor/*/release/release_configs -name "*.textproto") 
           BUILD_ID=$(basename $str .textproto)
        fi
        if [ -z "$BUILD_ID" ]; then
           str=$(find build/release_configs -name "*.textproto") 
           BUILD_ID=$(basename $str .textproto)
        fi
        THISRC=0
    fi
fi

# Extract the variable name from the target line in envsetup.sh
PreTarget_BUILD=$(grep -E "export [a-zA-Z]*_BUILD$" build/make/envsetup.sh)
if [ -n "$PreTarget_BUILD" ]; then
Target_BUILD=$(grep -E "export [a-zA-Z]*_BUILD$" build/make/envsetup.sh | awk '{print $2}' | sed 's/export //')

# Given sed command with an unknown pattern
LINEAGE_BUILD_COMMAND=$(grep -E $Target_BUILD= build/make/envsetup.sh |grep sed)

sed_command=$(echo "$LINEAGE_BUILD_COMMAND" | grep -o "sed -e 's/[^']*'")

# Extract the pattern inside the 's/^' and '//g' delimiters
pattern=$(echo "$sed_command" | sed -e 's/s\/\^//;s/\/.*//' | sed 's|sed -e ||g' | sed "s|'||g")
else
pattern=$(cat vendor/*/build/envsetup.sh | grep "lunch [a-z]*_" | sed 's/[ ]*lunch//g' | sed  's/^ //g' | sed 's/_$target-$aosp_target_release-$variant//g')_
fi

if [ ${THISRC} == 0 ]; then
    echo Found lunch comand is : lunch "$pattern""$DEVICE_NAME"-"$BUILD_ID"-user
else
    echo Found lunch comand is : lunch "$pattern""$DEVICE_NAME"-user
fi

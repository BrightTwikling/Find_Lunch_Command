#!/bin/bash

BUILD_ID=""
DEVICE_NAME=$1
########################################################################
##  Initial_check
########################################################################
if [ -z $1 ] ; then
  echo "ERROR: Must define device name like"
  echo "find_lunch_command.sh zenfone7"
  exit 1
fi

grep  "https://android.googlesource.com" .repo/manifests/default.xml 2>/dev/null >/dev/null
if [ $? -ne 0 ] ; then
  echo "ERROR: The directory \"${PWD}\" is not the top level of a repository for Android"
  exit 1
fi

########################################################################
# new build config files
########################################################################
RELEASE_CONFIG_MAP_FILES+=( $( find build device vendor -name "release_config_map.*" )  )

for each_map_file in "${RELEASE_CONFIG_MAP_FILES[@]}"; do
    BUILD_ID="$( grep declare-release-config "${each_map_file}"  | tr "," " " | awk '{ print $3}' )"
    if [[ "$BUILD_ID" == "\$(TARGET_RELEASE)" ]]; then
        BUILD_ID=$(cat $each_map_file | grep "TARGET_RELEASE :=" | sed "s/TARGET_RELEASE := //g" )
    fi
done
if [[ -z "$BUILD_ID" ]]; then
    BUILD_ID=$(find build device vendor -name "release_config_map.*" | xargs grep target -hrs | uniq |  grep -oP '(?<=target: ")[^"]+')
fi
if [[ -z "$BUILD_ID" ]]; then
    BUILD_ID=$(find build device vendor -name "release_config_map.*" | xargs grep name -hrs | uniq |  grep -oP '(?<=name: ")[^"]+')
fi
########################################################################
# Extract the variable name from the target line in config.mk and envsetup.sh
# Check if $Target_BUILD is exported
# If $Target_BUILD is not exported, sepolicy and BoardConfig＊.mk cannot be included correctly in config.mk
########################################################################
Target_BUILD_from_mk=$(find build/make/core -maxdepth 1 -name config.mk | xargs grep "ifneq (\$([a-zA-Z]*_BUILD)" -rhs | sed "s/ifneq (\$(//g" | sed "s/),)//g" | uniq)
Target_BUILD_from_sh=$(find build vendor -name "envsetup.sh" | xargs grep "export $Target_BUILD"$ -hs | uniq | sed "s/[ ]*export[ ]//g" )

Target_BUILD=($Target_BUILD_from_mk $Target_BUILD_from_sh )
Target_BUILD=$( echo $Target_BUILD | uniq )

# Given sed command with an unknown pattern
BUILD_COMMAND=$(grep -E $Target_BUILD= build/make/envsetup.sh |grep sed)

sed_command=$(echo "$BUILD_COMMAND" | grep -o "sed -e 's/[^']*'")

# Extract the pattern inside the 's/^' and '//g' delimiters
pattern=$(echo "$sed_command" | sed -e 's/s\/\^//;s/\/.*//' | sed 's|sed -e ||g' | sed "s|'||g")

if [[ -z "$pattern" ]]; then
envsetup_scripts=( build/envsetup.sh vendor/*/build/envsetup.sh )
    for envsetup_script in "${envsetup_scripts[@]}"; do
        BUILD_COMMAND=$(cat $envsetup_script | grep "[ ]*$Target_BUILD=\$(" )
        sed_command=$(echo "$BUILD_COMMAND" | grep -o "sed -e 's/[^']*'")
        # Extract the pattern inside the 's/^' and '//g' delimiters
        patterns=$(echo "$sed_command" | sed -e 's/s\/\^//;s/\/.*//' | sed 's|sed -e ||g' | sed "s|'||g")
    done
    pattern=$(echo $patterns | uniq)
fi

echo BUILD_ID=$BUILD_ID
echo pattern=$pattern
echo Target_BUILD=$Target_BUILD
########################################################################


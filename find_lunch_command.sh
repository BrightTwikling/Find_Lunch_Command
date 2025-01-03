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
########################################################################
# End of initial investigation
########################################################################

echo BUILD_ID=$BUILD_ID
echo pattern=$pattern
echo Target_BUILD=$Target_BUILD
########################################################################
# Select and run the command you found
########################################################################
item1="lunch "$pattern""$DEVICE_NAME"-"$BUILD_ID"-user"
item2="lunch "$pattern""$DEVICE_NAME"-user"

# List of items to display
items=("$item1" "$item2" "End")
total_items=${#items[@]}

if [[ "$BUILD_ID" == "" ]]; then
selected=1
else
selected=0
fi

# Function to display the menu with the current selection blinking
display_menu() {
  clear

  echo BUILD_ID=$BUILD_ID
  tput setaf 1
  caution_text="Note that the README in the manifest repository is more correct than this script."
  printf "\e[5m%s\e[0m\n" "${caution_text}"
  tput sgr0  # Reset attributes
  echo

  echo "This is list of commands existing in vendor/*/build/tasks"
  echo "==========="
  find vendor/*/build/tasks -name "*.mk" | xargs grep .PHONY -hs | sed "s/\.PHONY\: //g"
  echo "==========="
  if [[ "$BUILD_ID" == "" ]]; then
    text="BUILD_ID is blank so $item2 is probably better"
    highlight="$item2"
    # ANSI escape codes in red
    RED='\033[0;31m'
    NC='\033[0m' # Reset color
    # Only the elephant part is displayed in red
    echo -e "${text//$highlight/${RED}${highlight}${NC}}"
  fi
  echo "Use up and down keys to select"
  echo "After selection, build will start"
  echo "==========="
  for i in "${!items[@]}"; do
    if [ "$i" -eq "$selected" ]; then
      tput setaf 3  # Yellow color for blinking
      printf "\e[5m%s\e[0m\n" "${items[i]}"  # Blinking text
      tput sgr0  # Reset attributes
    else
      echo "${items[i]}"
    fi
  done
}

# Capture up and down arrow keys
while true; do
  display_menu
  read -sn 1 key
  case "$key" in
    $'\x1b')  # Escape sequence
      read -sn 2 key  # Read the rest of arrow key code
      case "$key" in
        '[A')  # Up arrow
          ((selected=(selected - 1 + total_items) % total_items))
          ;;
        '[B')  # Down arrow
          ((selected=(selected + 1) % total_items))
          ;;
      esac
      ;;
    "")  # Enter key
      echo "You selected: : ${items[selected]}"
      if [[ "${items[selected]}" != "End" ]]; then
          Start1=". build/envsetup.sh"
          Start2="${items[selected]}"
      fi
      break
      ;;
  esac
done
eval $Start1
eval $Start2

pre_export_name=$(echo $PreTarget_BUILD | sed "s/export //g")
echo pre_export_name=$pre_export_name
export_name=$(eval echo $pre_export_name)
if [[ -n "$export_name" ]]; then
echo $pre_export_name is correctly defined by $export_name
echo "Try to type : echo" $pre_export_name
else
echo $pre_export_name is not correctly defined by $DEVICE_NAME
echo "So this script conduct $ export " $Target_BUILD=$DEVICE_NAME
pre_export_name2="export PRODUCT_DEVICE="$DEVICE_NAME
eval $pre_export_name2
echo "Try to type : echo $"$Target_BUILD
fi


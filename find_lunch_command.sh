#!/bin/bash

BUILD_ID=""
DEVICE_NAME=$1

if [ -z $1 ] ; then
  echo "ERROR: Must define device name like"
  echo "find_lunch_command.sh zenfone7"
  exit 1
fi

# new build config files
#
RELEASE_CONFIG_MAP_FILES+=( $( find build device vendor -name release_config_map.mk) )

########################################################################
# check if the current directory is the top level of a repository for Android
########################################################################
grep  "https://android.googlesource.com" .repo/manifests/default.xml 2>/dev/null >/dev/null
if [ $? -ne 0 ] ; then
  echo "ERROR: The directory \"${PWD}\" is not the top level of a repository for Android"
  exit 1
else
    for each_map_file in "${RELEASE_CONFIG_MAP_FILES[@]}"; do
        BUILD_ID="$( grep declare-release-config "${each_map_file}"  | tr "," " " | awk '{ print $3}' )"
        if [[ "$BUILD_ID" == "\$(TARGET_RELEASE)" ]]; then
            BUILD_ID=$(cat $each_map_file | grep "TARGET_RELEASE :=" | sed "s/TARGET_RELEASE := //g" )
        fi
    done
fi

########################################################################
# Extract the variable name from the target line in config.mk and envsetup.sh
# Check if $Target_BUILD is exported
# If $Target_BUILD is not exported, sepolicy and BoardConfig＊.mk cannot be included correctly in config.mk
########################################################################
Target_BUILD=$(find build/make/core -maxdepth 1 -name config.mk | xargs grep "ifneq (\$([a-zA-Z]*_BUILD)" -rhs | sed "s/ifneq (\$(//g" | sed "s/),)//g" | uniq)

PreTarget_BUILD=$(grep -E "export $Target_BUILD" build/make/envsetup.sh)
if [ -n "$PreTarget_BUILD" ]; then

# Given sed command with an unknown pattern
LINEAGE_BUILD_COMMAND=$(grep -E $Target_BUILD= build/make/envsetup.sh |grep sed)

sed_command=$(echo "$LINEAGE_BUILD_COMMAND" | grep -o "sed -e 's/[^']*'")

# Extract the pattern inside the 's/^' and '//g' delimiters
pattern=$(echo "$sed_command" | sed -e 's/s\/\^//;s/\/.*//' | sed 's|sed -e ||g' | sed "s|'||g")

else

sed_command=$(grep 'echo "$TARGET_PRODUCT"' build/make/envsetup.sh)

# Delete the part before "sed"
sed_part="${sed_command#*sed}"

# Extract the part surrounded by "s/" and "_"
pattern=$(echo "$sed_part" | grep -oP '(?<=s/)[a-z\_]*(?=[^_]*_)')

item1="lunch "$pattern""$DEVICE_NAME"-"$BUILD_ID"-user"
echo found lunch command : "$item1"
exit
fi

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
  echo "====="
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
          echo ". build/envsetup.sh"
          eval ". build/envsetup.sh"
          echo "${items[selected]}"
          eval "${items[selected]}"
          history -s "${items[selected]}"
      fi
      break
      ;;
  esac
done

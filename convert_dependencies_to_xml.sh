#!/bin/bash

# Path of the .dependencies file
json_file=$1

# Get the number of objects in .dependencies
num_objects=$(jq '. | length' "$json_file")

# Parse and transform each object
for (( i=0; i<$num_objects; i++ )); do
    remote=$(jq -r ".[$i].remote" "$json_file")
    repository=$(jq -r ".[$i].repository" "$json_file")
    target_path=$(jq -r ".[$i].target_path" "$json_file")
    revision=$(jq -r ".[$i].revision" "$json_file")

    # Generate project name using target_path instead of repository
    project_name=$target_path

    # Convert the result to a single line
    echo "  <project path=\"$target_path\" name=\"$repository\" remote=\"$remote\" revision=\"$revision\" />"
done

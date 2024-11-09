#!/bin/bash

# JSONファイルのパス
json_file=$1

# JSONオブジェクトの数を取得
num_objects=$(jq '. | length' "$json_file")

# 各JSONオブジェクトをパースして変換
for (( i=0; i<$num_objects; i++ )); do
    remote=$(jq -r ".[$i].remote" "$json_file")
    repository=$(jq -r ".[$i].repository" "$json_file")
    target_path=$(jq -r ".[$i].target_path" "$json_file")
    revision=$(jq -r ".[$i].revision" "$json_file")

    # repositoryの代わりにtarget_pathを使用してプロジェクト名を生成
    project_name=$target_path

    # 結果を一行に変換
    echo "  <project path=\"$target_path\" name=\"$repository\" remote=\"$remote\" revision=\"$revision\" />"
done

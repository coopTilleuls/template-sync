#!/bin/sh

initial_commit=$(git rev-list "$(git rev-parse HEAD)" --max-parents==0)

echo $initial_commit 

current_dir=$(pwd)

temp_dir=$(mktemp -d)

git clone https://github.com/api-platform/api-platform "$temp_dir"

cd "$temp_dir" || return

api_shas=$(git log --pretty=format:"%H")

echo "$api_shas"

# for sha in $api_shas;
# do
#     diff=$(git diff "$initial_commit" "$sha")
#     if [ -z "$diff" ]; then
#     initial_api_commit=$sha
#     break
#     fi
# done
# 
# cd "$current_dir" || return
# pwd
# echo "$initial_api_commit"
 

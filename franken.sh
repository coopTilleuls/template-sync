#!/bin/sh

initial_commit=$(git rev-list "$(git rev-parse HEAD)" --max-parents==0)

echo initial project commit: "$initial_commit"

project_dir=$(pwd)

current_branch=$(git branch --show-current)

temp_dir=$(mktemp -d)

git clone https://github.com/api-platform/api-platform "$temp_dir"

cd "$temp_dir" || return

git remote add source "$project_dir"

git fetch source "$current_branch":test

api_shas=$(git log --pretty=format:"%H")

for sha in $api_shas;
do
    diff=$(git diff "$initial_commit" "$sha")
    if [ -z "$diff" ]; then
    initial_api_commit=$sha
    break
    fi
done

git show "$initial_api_commit"

cd "$current_dir" || return
pwd
 

#!/bin/sh

# initial_commit=$(git rev-list "$(git rev-parse HEAD)" --max-parents==0)

# echo initial project commit: "$initial_commit"

# //TODO CHECK IF git status are clean 

actual_commit=$(git rev-parse HEAD)

project_dir=$(pwd)

current_branch=$(git branch --show-current)

temp_dir=$(mktemp -d)

git clone https://github.com/api-platform/api-platform "$temp_dir"

cd "$temp_dir" || return

api_shas=$(git log --pretty=format:"%H")

git remote add source "$project_dir"

git fetch source "$current_branch":test

git switch test

for sha in $api_shas;
do
    diff=$(git diff --diff-filter=d --shortstat "$actual_commit" "$sha")
    insertions=$(echo "$diff" | awk '{print $4}')
    deletions=$(echo "$diff" | awk '{print $6}')
    sum=$insertions+$deletions
    echo "$sum"
done

# git show "$initial_api_commit"

# cd "$current_dir" || return
# pwd
 

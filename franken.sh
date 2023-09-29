#!/bin/sh

# initial_commit=$(git rev-list "$(git rev-parse HEAD)" --max-parents==0)

# echo initial project commit: "$initial_commit"

# //TODO CHECK IF git status are clean 

# actual_commit=$(git rev-parse HEAD)

project_dir=$(pwd)

# current_branch=$(git branch --show-current)

temp_dir=$(mktemp -d)
cd "$temp_dir" || return

mkdir template
mkdir project
mkdir template_modified
git clone https://github.com/api-platform/api-platform template/
git clone "$project_dir" project/

cd template/ || return
api_shas=$(git log --pretty=format:"%H")

# git remote add source "$project_dir"

# git fetch source "$current_branch":test

# git switch test

for sha in $api_shas;
do
    git checkout "$sha" > /dev/null 2>&1
    cp -r . ../template_modified
    find ../template_modified -type f -name "*.lock" -exec rm -f {} +
    find ../template_modified -type f -name "*-lock*" -exec rm -f {} +
    find ../template_modified -type d -name ".git" -exec rm -rf {} +
    find ../template_modified -type f -name "*.json" -exec rm -rf {} +
    find ../template_modified -type f -name "*README*" -exec rm -rf {} +
    total_template_modified_files=$(find ../template_modified -type f | wc -l )
    cd ..
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)

    (find template_modified/ -type f | sort | sed 's|template_modified/||') > "$tmpfile1"

    (find project/ -type f | sort | sed 's|project/||') > "$tmpfile2"

    common_files=$(comm -12 "$tmpfile1" "$tmpfile2" | wc -l)

    echo "Nombre de fichiers communs : $common_files"

    diff=$(git diff --shortstat --no-index --diff-filter=d -- project template_modified)
    insertions=$(echo "$diff" | awk '{print $4}')
    deletions=$(echo "$diff" | awk '{print $6}')
    sum=$((insertions + deletions))
    echo lignes modifiées: "$sum" nombre de fichiers: "$total_template_modified_files" sha: "$sha"
    cd template/ || return   
done

# git show "$initial_api_commit"

# cd "$current_dir" || return
# pwd
 

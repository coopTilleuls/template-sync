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

if [ -z "$1" ]; then 
echo Missing first argument: url of the template repository
exit 1
fi

git clone "$1" template/
git clone "$project_dir" project/

cd template/ || return
api_shas=$(git log --pretty=format:"%H")

# git remote add source "$project_dir"

# git fetch source "$current_branch":test

# git switch test

index=0

for sha in $api_shas;
do
    git checkout "$sha" > /dev/null 2>&1
    cp -r . ../template_modified
    find ../template_modified -type f -name "*.lock" -exec rm -f {} +
    find ../template_modified -type f -name "*-lock*" -exec rm -f {} +
    find ../template_modified -type d -name ".git" -exec rm -rf {} +
    find ../template_modified -type f -name "*.json" -exec rm -f {} +
    find ../template_modified -type f -name "*README*" -exec rm -f {} +
    total_template_modified_files=$(find ../template_modified -type f | wc -l )
    cd ..
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)

    (find template_modified/ -type f | sort | sed 's|template_modified/||') > "$tmpfile1"

    (find project/ -type f | sort | sed 's|project/||') > "$tmpfile2"

    common_files=$(comm -12 "$tmpfile1" "$tmpfile2" | wc -l)

#    echo "Nombre de fichiers communs : $common_files"

    diff=$(git diff --shortstat --no-index --diff-filter=d -- project template_modified)
    ratio=$(echo "scale=4; $common_files / $total_template_modified_files" | bc)
    ratio_percent=$(printf "%.0f" "$(echo "$ratio * 100" | bc)")
#    echo lignes modifiées: "$sum" nombre de fichiers totaux: "$total_template_modified_files" sha: "$sha"
#    echo Ratio: "$ratio_percent"%
    if [ "$index" -eq 0 ]; then
        ratioMax=$ratio_percent
        ratioMin=$ratio_percent
    fi
    if [ "$ratio_percent" -gt "$ratioMax" ]; then
        ratioMax=$ratio_percent
    elif [ "$ratio_percent" -lt "$ratioMin" ]; then
        ratioMin=$ratio_percent    
    fi       
    cd template/ || return
    index=$((index + 1))
done

ratioThreshold=$(echo "$ratioMax - ($ratioMax - $ratioMin) / 3" | bc)

index=0
for sha in $api_shas;
do
    git checkout "$sha" > /dev/null 2>&1
    cp -r . ../template_modified
    find ../template_modified -type f -name "*.lock" -exec rm -f {} +
    find ../template_modified -type f -name "*-lock*" -exec rm -f {} +
    find ../template_modified -type d -name ".git" -exec rm -rf {} +
    find ../template_modified -type f -name "*.json" -exec rm -f {} +
    find ../template_modified -type f -name "*README*" -exec rm -f {} +
    total_template_modified_files=$(find ../template_modified -type f | wc -l )
    cd ..
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)

    (find template_modified/ -type f | sort | sed 's|template_modified/||') > "$tmpfile1"

    (find project/ -type f | sort | sed 's|project/||') > "$tmpfile2"

    common_files=$(comm -12 "$tmpfile1" "$tmpfile2" | wc -l)

    ratio=$(echo "scale=4; $common_files / $total_template_modified_files" | bc)
    ratio_percent=$(printf "%.0f" "$(echo "$ratio * 100" | bc)")

    echo ratio percent: "$ratio_percent" \n ratio threshold: "$ratioThreshold"

    if [ "$ratio_percent" -gt "$ratioThreshold" ] || [ "$ratio_percent" -eq "$ratioThreshold" ]; then
        diff=$(git diff --shortstat --no-index --diff-filter=d -- project template_modified)
        insertions=$(echo "$diff" | awk '{print $4}')
        deletions=$(echo "$diff" | awk '{print $6}')
        sum=$((insertions + deletions))
        if [ $index -eq 0 ]; then
            minSum=$sum
            wantedSha=$sha
            echo "$wantedSha"
            index=$((index + 1))
        fi
        if [ $sum -lt "$minSum" ]; then
            minSum=$sum
            wantedSha=$sha
        fi    
    fi
#    echo lignes modifiées: "$sum" nombre de fichiers totaux: "$total_template_modified_files" sha: "$sha"
#    echo Ratio: "$ratio_percent"%     
    cd template/ || return
done

echo Le commit origine est "$wantedSha"

# git show "$initial_api_commit"

# cd "$current_dir" || return
# pwd
 

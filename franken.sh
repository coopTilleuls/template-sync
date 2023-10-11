#!/bin/sh

project_dir=$(pwd)

temp_dir=$(mktemp -d)
cd "$temp_dir" || return

mkdir template
mkdir project
mkdir template_modified

if [ -z "$1" ]; then
echo Missing first argument: url of the template repository
exit 1
fi

git clone "$1" template/ > /dev/null 2>&1
git clone "$project_dir" project/ > /dev/null 2>&1

cd template/ || return
api_shas=$(git log --pretty=format:"%H")

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
    rm "$tmpfile1" "$tmpfile2"

    ratio=$(echo "scale=4; $common_files / $total_template_modified_files" | bc)
    ratio_percent=$(printf "%.0f" "$(echo "$ratio * 100" | bc)")

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
rm -rf ../template_modified/*
echo "fin de première boucle"
index=0
for sha in $api_shas;
do
    git checkout "$sha" > /dev/null 2>&1
    cp -r . ../template_modified
    find ../template_modified -type f -name "*.lock" -exec rm -f {} +
    find ../template_modified -type f -name "*-lock*" -exec rm -f {} +
    find ../template_modified -type d -name ".git" -exec rm -rf {} +
#    find ../template_modified -type f -name "*.json" -exec rm -f {} +
    find ../template_modified -type f -name "*README*" -exec rm -f {} +
    total_template_modified_files=$(find ../template_modified -type f | wc -l )
    cd ..
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)

    (find template_modified/ -type f | sort | sed 's|template_modified/||') > "$tmpfile1"

    (find project/ -type f | sort | sed 's|project/||') > "$tmpfile2"

    common_files=$(comm -12 "$tmpfile1" "$tmpfile2" | wc -l)
    rm "$tmpfile1" "$tmpfile2"

    ratio=$(echo "scale=4; $common_files / $total_template_modified_files" | bc)
    ratio_percent=$(printf "%.0f" "$(echo "$ratio * 100" | bc)")

    if [ "$ratio_percent" -gt "$ratioThreshold" ] || [ "$ratio_percent" -eq "$ratioThreshold" ]; then
        diff=$(git diff --shortstat --no-index --diff-filter=d -- project template_modified)
        insertions=$(echo "$diff" | awk '{print $4}')
        deletions=$(echo "$diff" | awk '{print $6}')
        sum=$((insertions + deletions))
        if [ $index -eq 0 ]; then
            minSum=$sum
            wantedSha=$sha
            index=$((index + 1))
        fi
        if [ $sum -lt "$minSum" ] || [ $sum -eq "$minSum" ]; then
            minSum=$sum
            wantedSha=$sha
        fi
    fi

    cd template/ || return
done

echo Le commit origine est "$wantedSha"

# METHOD USING git apply 
# patch=$(mktemp)
# 
# git checkout main
# 
# git diff "$wantedSha" > "$patch"
# 
# git 
# 
# cd "$project_dir" || return
# git apply "$patch" --ignore-space-change --ignore-whitespace --whitespace=fix -C1 --reject
# git add --intent-to-add .
# git apply -3 "$patch"

# METHOD USING cherry-pick the squashed commit
git checkout main

git switch -c template-squash
echo "Enter the message for the commit which is gonna be cherry picked on your project"
read -r message

git reset --soft "$wantedSha" && git commit -m "$message"

squash_commit=$(git rev-parse HEAD)

cd "$project_dir" || return

git remote add template "$temp_dir"/template

git fetch template template-squash

git cherry-pick "$squash_commit"

git remote rm template

git branch -D template-squash

rm -rf "$temp_dir"

# testing with diff command
# git checkout "$wantedSha"

# diff -Nau . "$project_dir" > "$patch"

# cd "$project_dir" || return

# patch --merge -p1 < "$patch"
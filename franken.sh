#!/bin/sh

url=""
threshold=20
debug=false
debug_log=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --threshold=*)
      threshold="${1#*=}"
      ;;
    --debug)
      debug=true
      ;;
    *)
      if [ -z "$url" ]; then
        url="$1"
      else
        echo "Argument non reconnu : $1"
        exit 1
      fi
      ;;
  esac
  shift
done

if "$debug"; then
    exec 3>&1
else
    exec 3>/dev/null
fi

project_dir=$(pwd)

temp_dir=$(mktemp -d)
cd "$temp_dir" || return

mkdir template
mkdir project
mkdir template_modified

git clone "$url" template/ >&3 2>&3
exit 0
git clone "$url" template/ "$debug_log"

git clone "$project_dir" project/ "$debug_log"

cd template/ || return
api_shas=$(git log --pretty=format:"%H")

index=0
for sha in $api_shas;
do
    git checkout "$sha" "$debug_log"
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

index=0
for sha in $api_shas;
do
    git checkout "$sha" "$debug_log"
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

echo Found targeted commit: "$wantedSha"

git checkout main "$debug_log"

git switch -c template-squash "$debug_log"
# echo "Enter the message for the commit which is gonna be cherry picked on your project"
# read -r message

git reset --soft "$wantedSha" && git commit -m "squashed commit" "$debug_log"

squash_commit=$(git rev-parse HEAD)

cd "$project_dir" || return

git remote add template "$temp_dir"/template "$debug_log"

git fetch template template-squash "$debug_log"

git cherry-pick -Xrename-threshold="$threshold"% "$squash_commit"

git remote rm template "$debug_log"

git branch -D template-squash "$debug_log"

rm -rf "$temp_dir"

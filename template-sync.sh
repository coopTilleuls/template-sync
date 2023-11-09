#!/bin/sh

url=""
threshold=20
debug=false
commit=""
directory=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --threshold=*)
      threshold="${1#*=}"
      ;;
    --debug)
      debug=true
      ;;
    --commit=*)
      commit="${1#*=}"
      ;;
    --directory=*)
      directory="${1#*=}"
      ;;  
    *)
      if [ -z "$url" ]; then
        url="$1"
      else
        echo "Unknown argument : $1"
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

mkdir temp
mkdir template
mkdir project
mkdir template_modified
mkdir project_modified

git_template_sync() {
  if [ "$debug" = true ]; then
    git "$@"
  else
    git "$@" 1>&3 2>&3
  fi
}

removing_useless_files() {
  path="$1"
    if [ -d "$path" ]; then
        find "$path" -type f -name "*.lock" -exec rm -f {} +
        find "$path" -type f -name "*-lock*" -exec rm -f {} +
        find "$path" -type d -name ".git" -exec rm -rf {} +
#        find "$path" -type f -name "*.json" -exec rm -f {} +
        find "$path" -type f -name "*.md" -exec rm -f {} +
        find "$path" -type f -name "*README*" -exec rm -f {} +
    else
        echo "Error while sorting useless files"
        exit 1
    fi
}

estimate_similarity_index() {
  git_template_sync checkout "$sha"
  cp -r . ../template_modified

  removing_useless_files "../template_modified"
  total_template_modified_files=$(find "../template_modified" -type f | wc -l)
  
  cd ..
  tmpfile1=$(mktemp)
  tmpfile2=$(mktemp)

  (find template_modified/ -type f | sort | sed -e 's|template_modified/||' -e 's/\.yml/\.yaml/') > "$tmpfile1"

  (find project_modified/ -type f | sort | sed -e 's|project_modified/||' -e 's/\.yml/\.yaml/') > "$tmpfile2"

  common_files=$(comm -12 "$tmpfile1" "$tmpfile2" | wc -l) 

  ratio=$(echo "scale=4; $common_files / $total_template_modified_files" | bc)
  ratio_percent=$(printf "%.0f" "$(echo "$ratio * 100" | bc)")
  rm "$tmpfile1" "$tmpfile2"
}

git_template_sync clone "$project_dir" project/
cp -r project/* project_modified/
removing_useless_files "project_modified"



if [ -n "$directory" ]; then
  git_template_sync clone "$url" temp/
  cd temp/ || return
  git_template_sync subtree split -P "$directory" -b branch/template
  cd ../template/ || return
  git_template_sync init
  git_template_sync pull ../temp/ branch/template
else 
  git_template_sync clone "$url" template/
  cd template/ || return
fi

if [ -n "$commit" ]; then
  git_template_sync reset --hard "$commit"
fi

api_shas=$(git log --pretty=format:"%H")

index=0
for sha in $api_shas;
do
    estimate_similarity_index

    if [ "$index" -eq 0 ]; then
        ratioMax=$ratio_percent
        ratioMin=$ratio_percent
    fi
    if [ "$ratio_percent" -gt "$ratioMax" ]; then
        ratioMax=$ratio_percent
    elif [ "$ratio_percent" -lt "$ratioMin" ]; then
        ratioMin=$ratio_percent
    fi

    rm -rf template_modified/*
    cd template/ || return
    index=$((index + 1))
done

ratioThreshold=$(echo "$ratioMax - ($ratioMax - $ratioMin) / 3" | bc)

index=0
for sha in $api_shas;
do
    estimate_similarity_index

    if [ "$ratio_percent" -gt "$ratioThreshold" ] || [ "$ratio_percent" -eq "$ratioThreshold" ]; then
        diff=$(git diff --shortstat --no-index --diff-filter=d -- project template_modified)
        insertions=$(echo "$diff" | awk '{print $4}')
        deletions=$(echo "$diff" | awk '{print $6}')
        sum=$((insertions + deletions))
        if [ $index -eq 0 ]; then
            minSum=$sum
            wantedSha=$sha
        fi
        if [ -z "$minSum" ]; then
          echo "Error during the commits sorting process"
          exit 1
        fi
        if [ $sum -lt "$minSum" ] || [ $sum -eq "$minSum" ]; then
            minSum=$sum
            wantedSha=$sha
        fi
        index=$((index + 1))
    fi
    rm -rf template_modified/*
    cd template/ || return
done

echo "The targeted commit in the template is :"

git --no-pager show --no-patch "$wantedSha"


if [ -n "$directory" ]; then
  printf "\n\n"
  echo "As your template comes from the subdirectory of a monorepo,
  its SHA is different from the monorepo history. If you want to check it, use his name, tag or date to retrieve it." 
fi

printf "\n\n"

git_template_sync checkout main

git_template_sync switch -c template-squash
# echo "Enter the message for the commit which is gonna be cherry picked on your project"
# read -r message

git reset --soft "$wantedSha" && git_template_sync commit -m "squashed commit updating template"

squash_commit=$(git rev-parse HEAD)

cd "$project_dir" || return

git_template_sync remote add template "$temp_dir"/template

git_template_sync fetch template template-squash

git cherry-pick -Xrename-threshold="$threshold"% "$squash_commit"

git_template_sync remote rm template

rm -rf "$temp_dir"

#!/opt/homebrew/bin/bash

# Version 1.0
# $1 - highlight the directory level you want to look in 
# $2 - what pattern are you looking for? use *'s if you want to be exhuastive
# TODO: make a version that produces a file of pattern matches and allows the user to edit the file, removing hits they want to keep. Once the file is :wq, the script moves forward with removing all hits in the file

target_directory=$1
search_pattern=$2

find_target() {
  mapfile search_output < <(find "$1" -iname "${2}")
  if [[ ${#search_output[@]} -eq 0 ]]; then
    # >&2 redirects output to stderr
    echo "find failed" >&2
    exit 2
  fi
  echo -n "${search_output[@]}"
  clean_stars=$(sanitize_pattern $2)
  echo -n "${search_output[@]}" > "src/${clean_stars}_hits.txt"
}
sanitize_pattern() {
  local string=$1
if [ "${string:0:1}" == "*" ]; then
  string="${string:1}"
fi
if [ "${string:(-1)}" == "*" ]; then
  string="${string:0:${#string}-1}"
fi
echo $string
}
identify_duplicate() {
  local pattern=$(sanitize_pattern $1)
  local target=$2
  if [ $( grep -o "$pattern" <<< "$target" | wc -l ) -gt 1 ]; then
    return 3
  fi
}
remove_duplicate() {
  local pattern=$1
  declare -n array=$2
  for i in "${!array[@]}"; do
    if  identify_duplicate "$pattern" "${array[$i]}"; then
      :
    elif [ $? -eq 3 ]; then
      unset array[$i]
    fi
  done
}
rm_file_n_dir() {
  declare -n array=$1
  for i in "${!array[@]}"; do
    local trimmedItem="${array[i]// /}"
    local confirmRemove
    echo "Would you like to remove: "
    echo "$trimmedItem (y/n)"
    read confirmRemove
    confirmRemove="${confirmRemove,,}"
    # TODO: update inputs
    if [[ $confirmRemove == "y" || $confirmRemove == "yes" ]]; then
    rm -rf "$trimmedItem"
  elif [[ $confirmRemove == "n" || $confirmRemove == "no" ]]; then
    printf "skipping item\n"
  else 
    echo "aborting removal of this item"
    fi
  done
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # TODO: add user input checks to proceed with removal
  find_return=$(find_target $target_directory $search_pattern )
  mapfile -t temp_array <<< "$find_return"
  remove_duplicate "$search_pattern" temp_array
  rm_file_n_dir temp_array
fi

#!/opt/homebrew/bin/bash

target_directory=$1
search_pattern=$2

find_target() {
  mapfile search_output < <(find "$1" -iname "$2")
  if [[ ${#search_output[@]} -eq 0 ]]; then
    echo "find failed"
    exit 2
  fi
  echo "${search_output[@]}"
}
identify_duplicate() {
  local pattern=$1
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  find_target $target_directory $search_pattern 
fi

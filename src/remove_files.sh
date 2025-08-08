#!/opt/homebrew/bin/bash

# Version 1.0
# $1 - highlight the directory level you want to look in 
# $2 - what pattern are you looking for? use *'s if you want to be exhuastive
# TODO: make a version that produces a file of pattern matches and allows the user to edit the file, removing hits they want to keep. Once the file is :wq, the script moves forward with removing all hits in the file

target_directory=$1
search_pattern=$2
fail() {
    echo "Error: $1" >&2
    exit "${2:-1}" # Exit with specified code or 1 by default
}
find_target() {
  mapfile search_output < <(find "$1" -iname "${2}")
  if [[ ${#search_output[@]} -eq 0 ]]; then
    # >&2 redirects output to stderr
    echo "find failed" >&2
    exit 2
  fi
  local clean_stars=$(sanitize_pattern $2)
  clean_path="src/${clean_stars}_hits.txt"
  echo -n "${search_output[@]}" > $clean_path
  sort $clean_path
}
concat_template() {
  local template=$1
  local hit_file=$2
  cat $template $hit_file > src/concat_file.txt
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
remove_comments() {
local line_array; mapfile line_array < $1
for idx in "${!line_array[@]}"; do
  item="${line_array[${idx}]}" 
  if echo "$item" | grep -q "^#";then
    unset line_array[$idx]
  fi
done
line_array=("${line_array[@]}")
> $1
for line in "${line_array[@]}";do
  echo $line >> $1
done
}
remove_lines() {
remove_comments $1
if test $(cat $1 | wc -l) -eq 0; then
  fail "Operation aborted" 3
fi
while read -r line;do
  if test -d "$line"; then
    rm -rf "$line"
  else rm -f "$line"
  fi
done < <(cat $1)
}
cleanup() {
  if test -e $clean_path; then
    rm $clean_path
  fi
  if test -e src/concat_file.txt; then
    rm src/concat_file.txt
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  find_target $target_directory $search_pattern
  concat_template src/edit_template.txt $clean_path
  nvim src/concat_file.txt
  remove_lines src/concat_file.txt
  cleanup
fi

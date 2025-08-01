# Reserve setup_file() for:
# Static configuration
# Logging setup
# Downloading shared resources
#   remember to make them accessible by using export
setup_file() {
    export TEMPDIR=$(mktemp -d)
}
# Use setup() if your tests rely on short-lived or per-test setup, such as:
# Environment variables
# Temporary file systems
# Function sourcing
# Command path modifications
setup() {
  load 'test_helper/common-setup'
    _common_setup
    mkdir -p "$TEMPDIR"/target/file && touch "${TEMPDIR}/target.txt" "${TEMPDIR}/target/target.txt" "${TEMPDIR}/target/file/target.txt"
}
teardown() {
    if [ $("$TEMPDIR" ls | wc -l) -ne 0 ]; then
    rm -r "$TEMPDIR"/*
    fi
}
teardown_file() {
    rm -r "$TEMPDIR"
}

@test "FIND_TARGET: should find target with exact pattern match" {
    source remove_files.sh 

    run find_target "$TEMPDIR" "target.txt"
    [[ "$output" =~ "target" ]]
}
@test "FIND_TARGET: find target with wildcard at each end of pattern" {
    source remove_files.sh 

    run find_target "$TEMPDIR" "*target*"
    [[ "$output" =~ "target" ]]
}
@test "FIND_TARGET: return 'find failed' if no return" {
    source remove_files.sh

    run find_target "$TEMPDIR" "foo"
    [[ "$output" == "find failed" ]]
}
@test "SANITIZE_PATTERN: string with '*' at end removed" {
    source remove_files.sh
    local string="target*"

    run sanitize_pattern "$string"
    [[ "$output" == "target" ]]
}
@test "SANITIZE_PATTERN: string with '*' at front removed" {
    source remove_files.sh
    local string="*target"
    run sanitize_pattern "$string"

    [[ "$output" == "target" ]]
}
@test "IDENTIFY_DUPLICATE: number of grep hits is only one" {
    source remove_files.sh
    # utilizing here strings V, and localizing the array so no clean up necessary after test runs
    local temp_array; mapfile temp_array <<<"$TEMPDIR/target.txt"

    run identify_duplicate "target" "${temp_array[0]}"
    test "$status" -eq 0
    run identify_duplicate "*target*" "something/targethisd/something.txt"
    test "$status" -eq 0
    run identify_duplicate "*target*" "something/targethisd/somethingtarget.txt"
    test ! "$status" -eq 0
    run identify_duplicate "target" "something/targethisd/somethingtarget.txt"
    test ! "$status" -eq 0
    test "$status" -eq 3
}
@test "IDENTIFY_DUPLICATE: number of grep hits exceeds one" {
    source remove_files.sh
    local temp_array; mapfile temp_array <<<"$TEMPDIR/target/file/target.txt"

    run identify_duplicate "target" "sometarget/isnot/therighttarget/yes.txt"
    test "$status" -eq 3 
    run identify_duplicate "target" "${temp_array[0]}"
    test "$status" -eq 3
}
@test "REMOVE_DUPLICATE: remove target from array" {
  source remove_files.sh
  # utilizing here documents; no spaces or tabs before DELIMITER
    local temp_array; mapfile -t temp_array <<-"EOF"
    temp/targetyes/targetsomething/file.txt
    target.txt
    dir/target/file/target.txt
EOF

# you can make block comments, by using hereDocs just redirect them nowhere
<<'COMMENT'
In BATS the 'run' function
sets the variables below:
- $status <- exit code
- $output <- stdout
- $lines <- output split into lines
BUT IT DOES NOT EXPOSE VARIABLE CHNAGES unless they are printed
Therefore I don't use it in this test
COMMENT

    test "${#temp_array[@]}" -eq 3 
    remove_duplicate "target" temp_array
    test "${#temp_array[@]}" -eq 1 
    [[ "${temp_array[@]}" =~ "target.txt" ]]
}
@test "RM_FILE_N_DIR: skip items when input 'n' or 'no'" {
  source remove_files.sh
  arr=("$TEMPDIR/target.txt")

  [ -e "$TEMPDIR/target.txt" ]
  output_n=$(rm_file_n_dir arr <<< "n")
  [ -n $(echo "$output_n" | grep -iq "skipping item") ]
  output_no=$(rm_file_n_dir arr <<< "no")
  [ -n $(echo "$output_no" | grep -iq "skipping item") ]
}
@test "RM_FILE_N_DIR: ask to confirm deletion of item" {
  source remove_files.sh
  arr=("$TEMPDIR/target.txt")

  run rm_file_n_dir arr <<< 'y'
  [[ "$output" =~ "$TEMPDIR/target.txt" ]]
}
@test "RM_FILE_N_DIR: ensure user options (y/n) included" {
  source remove_files.sh
  arr=("$TEMPDIR/target.txt")

  run rm_file_n_dir arr <<< 'n'
  [[ "$output" =~ "(y/n)" ]]
}
@test "RM_FILE_N_DIR: removes file and dir" {
  source remove_files.sh

  [ -e "$TEMPDIR/target.txt" ]
  [ -d "$TEMPDIR/target" ]
  arr_file=("$TEMPDIR/target.txt")
  arr_dir=("$TEMPDIR/target")

  rm_file_n_dir arr_file <<< "y"
  test ! -e "$TEMPDIR/target.txt" 
  rm_file_n_dir arr_dir <<< "y"
  test ! -d "$TEMPDIR/target" 
}
@test "TRIM_STRING: test remove whitespace before and after string" {
  str_before=" testing"
  str_after="testing "
  str_after_n_before=" testing "
  trim_before="${str_before/ /}"
  trim_after="${str_after/ /}"
  trim_before_n_after="${str_after_n_before// /}"

  test "$trim_before" == "testing" 
  test "$trim_after" == "testing" 
  test "$trim_before_n_after" == "testing" 
}
@test "SCRIPT: find remaining files and remove them" {
  remove_files.sh "$TEMPDIR" "*target*" << EOD
y
y
EOD

  test $(find_target "$TEMPDIR" "*target*"| wc -l) -eq 0 
}

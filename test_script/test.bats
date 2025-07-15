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

# use assert_output if you want to check if the output is true
# use refute_output if you want to check if the output is false

@test "FIND_TARGET: should find target with exact pattern match" {
    source remove_files.sh 
    run find_target "$TEMPDIR" "target.txt"

    assert_output -p "target"
}
@test "FIND_TARGET: find target with wildcard at each end of pattern" {
    source remove_files.sh 
    run find_target "$TEMPDIR" "*target*"

    assert_output -p "target.txt"
}
@test "FIND_TARGET: return 'find failed' if no return" {
    source remove_files.sh
    run find_target "$TEMPDIR" "foo"

    assert_output "find failed"
}
@test "SANITIZE_PATTERN: string with '*' at end removed" {
    source remove_files.sh
    local string="target*"
    run sanitize_pattern "$string"

    assert_output "target"
}
@test "SANITIZE_PATTERN: string with '*' at front removed" {
    source remove_files.sh
    local string="*target"
    run sanitize_pattern "$string"

    assert_output "target"
}
@test "IDENTIFY_DUPLICATE: number of grep hits is only one" {
    source remove_files.sh
    # utilizing here strings V, and localizing the array so no clean up necessary after test runs
    local temp_array; mapfile temp_array <<<"$TEMPDIR/target.txt"
    run identify_duplicate "target" "${temp_array[0]}"

    assert_success
}
@test "IDENTIFY_DUPLICATE: number of grep hits exceeds one" {
    source remove_files.sh
    local temp_array; mapfile temp_array <<<"$TEMPDIR/target/file/target.txt"
    run identify_duplicate "target" "${temp_array[0]}"

    assert_failure 3
}
@test "REMOVE_DUPLICATE: remove target from array" {
  source remove_files.sh
  # utilizing here documents; no spaces or tabs before DELIMITER
    local temp_array; mapfile -t temp_array <<-'EOF'
    temp/target/target/file.txt
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

    remove_duplicate "target" temp_array
    assert [ "${#temp_array[@]}" -eq 1 ]
}
@test "RM_FILE_N_DIR: remove files and directories from array" {
  source remove_files.sh
  find_target "$TEMPDIR" "*target*" 
    local temp_array; mapfile -t temp_array <<- EOF
${TEMPDIR}/target.txt
${TEMPDIR}/target
EOF
  rm_file_n_dir temp_array
  assert [ $(find_target "$TEMPDIR" "*target*"| wc -l) -eq 0 ]
}
@test "SCRIPT: find remaining files and remove them" {
  remove_files.sh "$TEMPDIR" "*target*"
  assert [ $(find_target "$TEMPDIR" "*target*"| wc -l) -eq 0 ]
}

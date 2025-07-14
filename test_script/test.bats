# Reserve setup_file() for:
# Static configuration
# Logging setup
# Downloading shared resources
#   remember to make them accessible by using export
setup_file() {
    export TEMPDIR=$(mktemp -d)
    touch "${TEMPDIR}/target.txt"
}
# Use setup() if your tests rely on short-lived or per-test setup, such as:
# Environment variables
# Temporary file systems
# Function sourcing
# Command path modifications
setup() {
  load 'test_helper/common-setup'
    _common_setup
}
# setup() {
# }
# teardown() {
#   
# }
teardown_file() {
    rm -r $TEMPDIR
}

# use assert_output if you want to check if the output is true
# use refute_output if you want to check if the output is false

@test "SCRIPT: should find target with exact pattern match" {
    run remove_spotify.sh "$TEMPDIR" "target.txt"

    assert_output -p "target"
}
@test "SCRIPT: find target with wildcard at each end of pattern" {
    run remove_spotify.sh "$TEMPDIR" "*target*"

    assert_output -p "target.txt"
}
@test "SCRIPT: return 'exit 2' if no return" {
    run remove_spotify.sh "$TEMPDIR" "target"

    assert_failure 2
}
@test "IDENTIFY_DUPLICATE: number of grep hits is only one" {
    source remove_spotify.sh
    mapfile temp_array <<<"$TEMPDIR/target.txt"
    run identify_duplicate "target" "${temp_array[0]}"
    unset temp_array

    assert_success
}
@test "IDENTIFY_DUPLICATE: number of grep hits exceeds one" {
    source remove_spotify.sh
    mapfile temp_array <<<"$TEMPDIR/target/target/target.txt"
    run identify_duplicate "target" "${temp_array[0]}"
    unset temp_array

    assert_failure 3
}
@test "REMOVE_DUPLICATE: remove target from array" {
  source remove_spotify.sh
    mapfile -t temp_array <<-'EOF'
    temp/target/target/file.txt
    target.txt
    dir/target/file/target.txt
EOF

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
    unset temp_array
}

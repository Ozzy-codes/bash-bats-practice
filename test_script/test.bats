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

    target_temp_files=$(find . -iname *target*.txt && find . -iname *concat*.txt)
    if test -n "${target_temp_files[@]}";then
    for item in "${target_temp_files[@]}"; do
    rm -r $item
    done
    fi
}

@test "FIND_TARGET: should find target with exact pattern match" {
    source remove_files.sh 

    run find_target "$TEMPDIR" "target"
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
@test "FIND_TARGET: Output hits into a file" {
  source remove_files.sh

    find_target "$TEMPDIR" "*target*"
    test -e "src/target_hits.txt"
    cat "src/target_hits.txt" | grep target
}
@test "FIND_TARGET: generate only one target file" {
  source remove_files.sh

    find_target "$TEMPDIR" "*target*"
    test $(find . -iname *target* | wc -l) -eq 1
}
@test "CONCAT_TEMPLATE: function, and file exists" {
  source remove_files.sh

    declare -f concat_template
    test -e "src/edit_template.txt"
}
@test "CONCAT_TEMPLATE: produce file with template on top, and something from hits file below it" {
  source remove_files.sh

     concat_template "src/edit_template.txt" "src/target_hits.txt"
     test -e "src/concat_file.txt" 
     head -n 3 "src/concat_file.txt" | tail -n 1 | grep -i "do delete paths you wish to remove"
     test -n "$(head -n 4 "src/concat_file.txt" | tail -n 1)" 
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
@test "REMOVE_COMMENTS: function exists" {
  source remove_files.sh

    declare -f remove_comments
}
@test "REMOVE_COMMENTS: remove comments from concat file" {
  source remove_files.sh
  cat > src/test_file.txt << "EOF"
# temp/targetyes/targetsomething/file.txt
# target.txt
# dir/target/file/target.txt
something somthing
something somthing
something somthing
EOF
    remove_comments src/test_file.txt
    echo "number of lines in test_file: $(cat src/test_file.txt | wc -l)"
    test $(cat src/test_file.txt | wc -l) -eq 3
    test $(cat src/test_file.txt | grep "^#" | wc -l) -eq 0
    rm src/test_file.txt
}
@test "REMOVE_LINES: function, and file exists" {
  source remove_files.sh

    declare -f remove_lines
}
@test "REMOVE_LINES: find paths and remove them " {
  source remove_files.sh
    cat src/edit_template.txt > src/temp_concat.txt 
    find "$TEMPDIR"/* | cat >> src/temp_concat.txt 
    remove_lines src/temp_concat.txt
    test $(ls $TEMPDIR | wc -l) -eq 0
}
@test "REMOVE_LINES: abort operation if nothing under comments" {
  source remove_files.sh
    cat src/edit_template.txt > src/temp_concat.txt 
    run remove_lines src/temp_concat.txt
    test $status -eq 3
    [[ "${output,,}" =~ "operation aborted" ]]
}
@test "REMOVE_FILES.sh: provided a dir level and pattern, script removes dir and file hit" {
    remove_files.sh $TEMPDIR "*target*"
    test $(ls $TEMPDIR | wc -l) -eq 0
}

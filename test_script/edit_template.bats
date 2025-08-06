# Reserve setup_file() for:
# Static configuration
# Logging setup
# Downloading shared resources
#   remember to make them accessible by using export

# Use setup() if your tests rely on short-lived or per-test setup, such as:
# Environment variables
# Temporary file systems
# Function sourcing
# Command path modifications
setup() {
  load 'test_helper/common-setup'
    _common_setup
}

@test "EDIT_TEMPLATE: file exists" {
  test -e "src/edit_template.txt"
}
@test "EDIT_TEMPLATE: should have instructions on what to do" {
grep -i '# lines starting with # will be ignored' "$PROJECT_DIR/src/edit_template.txt"
grep -i 'do not delete paths you wish to remove' "$PROJECT_DIR/src/edit_template.txt"
}

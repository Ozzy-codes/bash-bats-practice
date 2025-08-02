## File Objective
Use src/remove_files.sh to search a directory level and remove files & directories of a provided file pattern. The provided pattern will be passed to the find command. e.g. "*target*", "target", "?arget", etc.

### Prerequisites to Use Out of The Box
- Bash - installed by Homebrew (shebang points to homebrew path)
- Bats - Downloaded locally via [Bats-Core Installation](https://bats-core.readthedocs.io/en/stable/installation.html#:~:text=save%2Ddev%20bats-,Any%20OS%3A%20Installing%20Bats%20from%20source,-%C2%B6); bats installed via homebrew isn't a bug free process

> Version 1.0:
>
> For each pattern hit, you can provide y/n input to confirm you would like to remove
> 
> Next version I expect that a file will be generated to examine all found hits and require the user to edit out the lines they wish not to remove. Upon saving the file the script would take that file and remove its contents without further prompts

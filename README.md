# isu

# GitHub Issue Creator


`isu` is a Bash script designed to simplify the process of creating new issues on GitHub directly from the command line. It automates the task of creating issues, allowing developers to focus on their work without the need to navigate through GitHub's web interface.

The script interacts with the GitHub API using the `gh` command-line tool, making it easy to create issues within the context of a Git repository.

## Features

- Create a new GitHub issue with a title, body, labels, and column placement.
- Automatically adds the new issue to the project connected to the repository.
- Can create a new branch for the issue (if the issue is not placed in a backlog or done column).
- Support for specifying story points for agile project management.

## Prerequisites

- [GitHub CLI (gh)](https://cli.github.com/)
- Bash shell version 4 or higher


## Installation

1. Clone or download the script to your local machine.
2. Source the script in your `.bashrc` or `.bash_profile` file:

```bash
source /path/to/isu.sh
```
3. Add completion to the script by adding the following line to your `.bashrc` or `.bash_profile` file:

```bash
complete -C isu isu
```
4. Make sure `gh` is installed and authenticated with your GitHub account.


## Usage

Run the script with the following command:

```bash
isu [title] [FLAGS]
```

### Flags

- Assumes everything up to the first flag is the title, so specifying the title flag is optional, no need to use quotes:
```bash
isu Title of the issue [FLAGS]
```
- `-b` or `--body`: Specify the body of the issue.
- `-l` or `--labels`: Specify the labels for the issue. Make sure the labels actually exist in the repository.
- `-c` or `--column`: Specify the column to place the issue in. If not specified, the issue will be placed into the default column, normally "To Do"/"to do". Make sure the column actually exists if you specify it.
- `-n` or `--no-branch`: Do not create a new branch for the issue. By default, the script will prompt to create a new branch if the issue is not placed in a backlog or done column.
- `-p` or `--no-storypoints`: Do not prompt for story points. By default, the script will prompt for story points.
- `-h` or `--help`: Show help message.


## Examples

```bash
# Show help
isu -h

# Create a new issue with a title and body
isu Title of the issue -b Body of the issue

# Create a new issue with a title, body, labels, and column placement
isu Title of the issue -b Body of the issue -l bug enhancement -c In Progress
```

## Limitations
- does not check if the user is on "main" or "dev" branch before creating a new branch.
- isu assumes labels to not have spaces in their names.
- newlines in the title are not supported.
- if the body is multi-line, it must be enclosed in quotes.
- labels and columns are case-sensitive - if specified, they must match the exact name in the repository, otherwise, the script will fail.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This script is licensed under the [MIT License](LICENSE).
```


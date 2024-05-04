#!/bin/bash

# This script creates a new issue on GitHub
isu() {
    if [[ -n $COMP_LINE ]]; then
        # if COMP_LINE is only isu  and space then show title
        if [[ "$COMP_LINE" == "isu " ]]; then
            echo '--title'
            exit
        fi
        if [[ ! "${COMP_LINE}" == *"--title"* ]]; then
            echo '--title'
        fi
        if [[ ! "${COMP_LINE}" == *"--body"* ]]; then
            echo '--body'
        fi
        if [[ ! "${COMP_LINE}" == *"--column"* ]]; then
            echo '--column'
        fi
        if [[ ! "${COMP_LINE}" == *"--labels"* ]]; then
            echo '--labels'
        fi
        if [[ ! "${COMP_LINE}" == *"--no-branch"* ]]; then
            echo '--no-branch'
        fi
        if [[ ! "${COMP_LINE}" == *"--no-storypoints"* ]]; then
            echo '--no-storypoints'
        fi
        exit
    fi
    show_help() {
        echo "isu"
        echo "Creates a new issue on github"
        echo "The new issue will be created in the current directory's git repo and added to the most recent project connected to the repo"
        echo ""
        echo "Flags"
        echo ""
        echo "-h, --help: Show help"
        echo ""
        echo "-t, --title: Title of the issue"
        echo ""
        echo "-b, --body: Body of the issue (optional)"
        echo ""
        echo "-l, --labels: Labels of the issue (optional)"
        echo ""
        echo "-c, --column: Column of the issue (optional)"
        echo ""
        echo "-n, --no-branch: Don't create a new branch for the issue"
        echo ""
        echo "-p, --no-storypoints: Don't prompt for story points"
        return 0
    }

    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        return 0
    fi
    rest_of_input="$@"
    mk_branch=true
    msg_title=""
    msg_body=""
    msg_label=""
    msg_column=""
    no_story_points=0
    # if args don't start with - then assume that everything is the title until the first - is found
    if [[ "$1" != -* ]]; then
        msg_title="$@"
        msg_title=${msg_title%% -[^ ]*}
    fi
    for arg in "$@"; do
        case $arg in
        -t | --title)
            if [[ "$@" == *"--title "* ]]; then
                msg_title=${rest_of_input#*--title }
                msg_title=${msg_title%% -[^ ]*}
            elif [[ "$@" == *"-t "* ]]; then
                msg_title=${rest_of_input#*-t }
                msg_title=${msg_title%% -[^ ]*}
            fi
            ;;
        -b | --body)
            if [[ "$@" == *" --body "* ]]; then
                msg_body=${rest_of_input#* --body }
                msg_body=${msg_body%% -[^ ]*}
            elif [[ "$@" == *" -b "* ]]; then
                msg_body=${rest_of_input#* -b }
                msg_body=${msg_body%% -[^ ]*}
            fi
            ;;
        -l | --labels)
            if [[ "$@" == *" --labels "* ]]; then
                msg_label=${rest_of_input#* --label }
                msg_label=${msg_label%% -[^ ]*}
            elif [[ "$@" == *" -l "* ]]; then
                msg_label=${rest_of_input#* -l }
                #regex for any character that is not whitespace
                msg_label=${msg_label%% -[^ ]*}
            fi
            ;;
        -c | --column)
            if [[ "$@" == *" --column "* ]]; then
                msg_column=${rest_of_input#* --column }
                msg_column=${msg_column%% -[^ ]*}
            elif [[ "$@" == *" -c "* ]]; then
                msg_column=${rest_of_input#* -c }
                msg_column=${msg_column%% -[^ ]*}
            fi
            ;;
        -n | --no-branch)
            if [[ "$@" == *" --no-branch"* ]]; then
                mk_branch=false
            elif [[ "$@" == *" -n"* ]]; then
                mk_branch=false
            fi
            ;;
        -p | --no-storypoints)
            if [[ "$@" == *"--no-storypoints"* ]]; then
                no_story_points=1
            elif [[ "$@" == *"-p"* ]]; then
                no_story_points=1
            fi
            ;;
        -h | --help)
            show_help
            ;;
        -[^\s]*)
            show_help
            ;;
        esac
    done
    # get the repo owner
    gh_name=$(git remote get-url origin | sed -e 's/.*github.com\///' -e 's/\/.*//')
    gh_name=${gh_name#*:}

    # get the repo name from path
    repo_name=$(basename $(git rev-parse --show-toplevel))

    #needed in order to not have to run interactive mode
    if [ -z "$msg_body" ]; then
        msg_body=" "
    fi
    if [ -z "$msg_title" ]; then
        echo "No title provided, exiting."
        show_help
        return 0
    else
        if [ $no_story_points == 0 ]; then
            # check if the title starts with story points
            check_sp=$(echo $msg_title | sed 's/^\[[0-9]\+\] //')
            # if they are identical then the title did not start with story points
            if [ "$msg_title" = "$check_sp" ]; then
                #prompt for story points, only allow numbers
                read -p "Story points: " story_points
                while [[ ! $story_points =~ ^[0-9]+$ ]]; do
                    #if empty then set to 1
                    if [ -z "$story_points" ]; then
                        story_points=1
                        break
                    fi
                    echo "Story points must be a number"
                    read -p "Story points: " story_points
                done
                msg_title="[$story_points] $msg_title"
            fi
        fi

        command_string="gh issue create -R "$gh_name/$repo_name" -t "\"$msg_title\"""
        if [ -n "$msg_body" ]; then
            # echo "body is not empty"
            command_string=$command_string" -b "\"$msg_body\"""
        fi
        # if message label is empty
        if [ -n "$msg_label" ]; then
            # echo "label is not empty"
            # if label contains a space
            if [[ "$msg_label" == *" "* ]]; then
                while [[ "$msg_label" == *" "* ]]; do
                    label=${msg_label%% *}
                    msg_label=${msg_label#* }
                    command_string=$command_string" -l "\"$label\"""
                done
            fi
            command_string=$command_string" -l "\"$msg_label\"""
        fi
    fi
    gh_response=$(eval $command_string)

    repo_id="$(gh api graphql -f ownerrepo="$gh_name" -f reponame="$repo_name" -f query='
    query($ownerrepo: String!, $reponame: String!) {
        repository(owner: $ownerrepo, name: $reponame) {
            id
            projectsV2(first: 1, orderBy: {field: CREATED_AT, direction: DESC}) {
                nodes {
                    id
                }
            }
        }
    }')"
    repo_id=${repo_id#*\"id\":\"}
    project_id=${repo_id#*\"id\":\"}
    repo_id=${repo_id%%\"*}
    project_id=${project_id%%\"*}

    issues="$(gh api graphql -f ownerrepo="$gh_name" -f reponame="$repo_name" -f query='
    query($ownerrepo: String!, $reponame: String!) {
        repository(owner: $ownerrepo, name: $reponame) {
            issues(first: 3, orderBy: {field: CREATED_AT, direction: DESC}) {
                nodes {
                    id
                    title
                    number
                }
            }
        }
    }')"
    declare -A issue_ids
    while [[ $issues == *"id"* ]]; do
        issue_id=${issues#*\"id\":\"}
        issue_id=${issue_id%%\"*}

        issues=${issues#*\"id\":\"$issue_id\"}

        issue_title=${issues#*\"title\":\"}
        issue_title=${issue_title%%\"*}

        issue_num=${issues#*\"number\":}
        issue_num=${issue_num%%'}'*}

        issues=${issues#*\"title\":\"$issue_title\"}

        issue_ids[$issue_title]="$issue_id"";""$issue_num"
    done
    issue_id=${issue_ids[$msg_title]}
    issue_num=${issue_id#*;}
    issue_id=${issue_id%%;*}
    if [ -z "$issue_id" ]; then
        echo "Newly created issue not found, guess it's browser-time ... exiting."
        return 0
    fi
    # check if status is not done or Done or backlog or Backlog
    if ! [ -z "$msg_column" ] && [ "$msg_column" != "Done" ] && [ "$msg_column" != "done" ] && [[ "$msg_column" != *"acklog"* ]]; then
        branch_name=$issue_num"-"$msg_title
        #substitute all spaces with dashes
        branch_name=${branch_name// /-}
        # remove all non-alphanumeric characters
        branch_name=${branch_name//[^a-zA-Z0-9-]/}

        # convert to lowercase
        branch_name=${branch_name,,}
        # check if branch exists
        if [ $mk_branch == true ]; then
            if [ -z "$(git branch --list | grep " $branch_name"$)" ]; then
                echo "mk_branch $mk_branch"
                if check_yes_no "It's dangerous to go alone! Take a branch with you? [Y/n]: "; then
                    git checkout -b $branch_name
                fi
            elif [ "$(git branch --show-current)" != "$branch_name" ]; then
                if check_yes_no "Switch to $branch_name? [Y/n]: "; then
                    git checkout $branch_name
                fi
            fi
        fi
    fi

    adding_issue_response="$(gh api graphql -f project="$project_id" -f item="$issue_id" -f query='
    mutation AddToProject($project: ID!, $item: ID!) {
        addProjectV2ItemById(input: { projectId: $project, contentId: $item }) {
            item {
                id
            }
        }
    }')"
    project_issue_id=${adding_issue_response#*\"id\":\"}
    project_issue_id=${project_issue_id%%\"*}
    project_field_id="$(gh api graphql -f project="$project_id" -f query='
    query($project: ID!) {
        node(id: $project) {
            ... on ProjectV2 {
                fields(first: 100) {
                        nodes {
                            ... on ProjectV2SingleSelectField {
                                id
                                name
                                options {
                                    id
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }')"

    status_field_id=${project_field_id#*\"id\":\"}
    status_field_id=${status_field_id%%\"*}

    status_options=${project_field_id#*\"options\":\[}
    status_options=${status_options%%\]*}
    # if message column is empty
    if [ -z "$msg_column" ]; then
        # get the id of the first option
        todo_option_id=${status_options#*\"id\":\"}
        todo_option_id=${todo_option_id%%\"*}
    else
        # todo_option_id=$(echo "$project_field_id" | grep -oP '(?<="id":")[^"]*(?=","name":"'"${msg_column}"'")')
        todo_option_id=$(echo "$project_field_id" | grep -oE '"id":"[^"]*","name":"'"${msg_column}"'"' | sed -E 's/"id":"([^"]*)","name":"'"${msg_column}"'"/\1/')
    fi
    if [ -z "$todo_option_id" ]; then
        echo "Status not found, exiting."
        return 0
    fi
    add_to_col="$(gh api graphql -f project="$project_id" -f issueid="$project_issue_id" -f field="$status_field_id" -f optionvalue="$todo_option_id" -f query='
            mutation ($project: ID!, $issueid: ID!, $field: ID!, $optionvalue: String!) {
              updateProjectV2ItemFieldValue(
                input: {
                      projectId: $project
                      itemId: $issueid
                      fieldId: $field
                      value: { 
                          singleSelectOptionId: $optionvalue
                      }
                }
                ) {
                projectV2Item {
                  id
                }
              }
            }')"
    echo -e "Issue \e[32m$issue_num\e[0m added to column \e[32m$msg_column\e[0m"
}

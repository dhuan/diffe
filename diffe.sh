_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE="DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE"

diffe () {
    if ! _git_verify_repo
    then
        echo "This command is supposed to be executed only inside git repositories."

        return
    fi

    local MODE="$1"

    if [[ "$MODE" != "log" ]] && [[ "$MODE" != "branch" ]]
    then
        echo "branch or log?"

        return
    fi

    if [[ -z "$DIFFE_PROGRAM" ]]
    then
        local DIFFE_PROGRAM="vim -d % %"
    fi


    local REVS=$(_git_diffe_get_rev "$MODE")

    if [[ "$REVS" == "$_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE" ]]
    then
        echo "Try again and use TAB to select multiple items."

        return
    fi

    REV_A=$(echo "$REVS" | cut -d "," -f 1)
    REV_B=$(echo "$REVS" | cut -d "," -f 2)

    local FILE_DIFF_A=$(mktemp)
    local FILE_DIFF_B=$(mktemp)

    while true;
    do
        local CHOSEN_FILE=$(_git_get_files_changed_from_two_revisions "$REV_A" "$REV_B" | fzf | sed -E 's/^.\s{1,}//g')

        if [ -z "$CHOSEN_FILE" ]
        then
            break
        fi

        git show "$REV_A":"$CHOSEN_FILE" > "$FILE_DIFF_A"
        git show "$REV_B":"$CHOSEN_FILE" > "$FILE_DIFF_B"

        local DIFFE_PROGRAM_MODIFIED="$DIFFE_PROGRAM"
        DIFFE_PROGRAM_MODIFIED=${DIFFE_PROGRAM_MODIFIED/\%/$FILE_DIFF_A}
        DIFFE_PROGRAM_MODIFIED=${DIFFE_PROGRAM_MODIFIED/\%/$FILE_DIFF_B}

        $DIFFE_PROGRAM_MODIFIED
    done
}

_git_branches_stripped() {
    git branch --all | sed 's/^\ \ //' | sed 's/^\*\ //'
}

_current_git_branch () {
    git branch | grep \* | cut -d ' ' -f2
}

_git_main_remote_branch () {
    git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

_git_verify_repo () {
    if [ -d ".git" ]
    then
        return 0
    fi

    return 1
}

_git_diffe_get_rev() {
    local ARG_MODE="$1"
    local REVS

    if [ "$ARG_MODE" = "branch" ]
    then
        local FZF_RESULT=$(_git_branches_stripped | fzf --multi=2)
        local BRANCH_CHOSEN=$(echo $FZF_RESULT | sed 's/\s/,/g')

        REVS="$BRANCH_CHOSEN"
    fi

    if [ "$ARG_MODE" = "log" ]
    then
        local FZF_RESULT=$(git log --format="%h %cs %aN %s" | fzf --multi=2 --layout=reverse | _git_diffe_get_commit_hash_from_formatted_log)
        local LOG_CHOSEN=$(echo $FZF_RESULT | sed 's/\s/,/g')

        REVS="$LOG_CHOSEN"
    fi

    if ! _has_comma "$REVS";
    then
        echo "$_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE"

        return
    fi

    echo "$REVS"
}

_git_diffe_get_commit_hash_from_formatted_log () {
    sed -E 's/\s.*$//g'
}

_git_get_files_changed_from_two_revisions() {
    ARG_REV_A="$1"
    ARG_REV_B="$2"

    git diff $ARG_REV_A...$ARG_REV_B --name-status
}

_has_comma() {
    grep -b -o "," <<< "$1" > /dev/null
}

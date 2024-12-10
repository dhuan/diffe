_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE="DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE"

diffe () {
    if ! _git_verify_repo
    then
        echo "This command is supposed to be executed only inside git repositories."

        return
    fi

    local MODE="$1"

    local DIFF_REVISION=""

    if _diffe_is_argument_valid_revision_tuple "$@"
    then
        DIFF_REVISION="$@"
    fi

    if _diffe_is_valid_revision "${@}"
    then
        DIFF_REVISION="$(printf "%s %s" "${@}^" "${@}")"
    fi

    if [[ "$MODE" != "log" ]] && [[ "$MODE" != "branch" ]] && [[ -z "$DIFF_REVISION" ]]
    then
        echo "Usage:"
        echo ""
        echo "$ diffe log"
        echo "Pick two revisions from the git log."
        echo ""
        echo "$ diffe branch"
        echo "Pick two branches."
        echo ""
        echo "$ diffe rev1 rev2"
        echo "Pass as parameters the two revisions you want to compare against."
        echo ""

        return
    fi

    if [[ -z "$DIFFE_PROGRAM" ]]
    then
        local DIFFE_PROGRAM="vim -d % %"
    fi

    if [[ ! -z "$DIFF_REVISION" ]]
    then
        local REV_A=$(echo "$DIFF_REVISION" | cut -d " " -f 1)
        local REV_B=$(echo "$DIFF_REVISION" | cut -d " " -f 2)

        _diffe_run "$REV_A" "$REV_B" "$DIFFE_PROGRAM"

        return
    fi


    local REVS=$(_git_diffe_get_rev "$MODE")

    if [[ "$REVS" == "$_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE" ]]
    then
        echo "Try again and use TAB to select multiple items."

        return
    fi

    local REV_A=$(echo "$REVS" | cut -d "," -f 1)
    local REV_B=$(echo "$REVS" | cut -d "," -f 2)

    _diffe_run "$REV_A" "$REV_B" "$DIFFE_PROGRAM"
}

_diffe_run () {
    local ARG_REV_A="$1"
    local ARG_REV_B="$2"
    local ARG_DIFFE_PROGRAM="$3"

    local FILE_DIFF_A=$(mktemp)
    local FILE_DIFF_B=$(mktemp)
    local INDEX=1

    while true;
    do
        local CHOSEN_FILE=$(_git_get_files_changed_from_two_revisions "$ARG_REV_A" "$ARG_REV_B" \
            | awk '{print $2}' \
            | fzf --preview 'git diff --color=always '"${ARG_REV_A}"'...'"${ARG_REV_B}"' -- {}' \
                --sync --bind "start:pos(${INDEX})"
        )

        if [ -z "$CHOSEN_FILE" ]
        then
            break
        fi

        INDEX=$(_git_get_files_changed_from_two_revisions "$ARG_REV_A" "$ARG_REV_B" \
            | awk '{print $2}' \
            | _find_line "${CHOSEN_FILE}")

        git show "$ARG_REV_A":"$CHOSEN_FILE" > "$FILE_DIFF_A"
        git show "$ARG_REV_B":"$CHOSEN_FILE" > "$FILE_DIFF_B"

        local DIFFE_PROGRAM_MODIFIED="$ARG_DIFFE_PROGRAM"
        DIFFE_PROGRAM_MODIFIED=${DIFFE_PROGRAM_MODIFIED/\%/$FILE_DIFF_A}
        DIFFE_PROGRAM_MODIFIED=${DIFFE_PROGRAM_MODIFIED/\%/$FILE_DIFF_B}

        $DIFFE_PROGRAM_MODIFIED
    done
}

_git_branches_stripped() {
    git branch --all | awk '{sub(/^\*/, " "); print}' | awk '{print $1}'
}

_current_git_branch () {
    git branch | grep \* | cut -d ' ' -f2
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
        local BRANCH_CHOSEN=$(echo $FZF_RESULT | awk '{sub(" ", ","); print}')

        REVS="$BRANCH_CHOSEN"
    fi

    if [ "$ARG_MODE" = "log" ]
    then
        local FZF_RESULT=$(git log --format="%h %cs %aN %s" | fzf --multi=2 --layout=reverse | _git_diffe_get_commit_hash_from_formatted_log)
        local LOG_CHOSEN=$(echo $FZF_RESULT | awk '{sub(" ", ","); print}')

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
    awk '{print $1}'
}

_git_get_files_changed_from_two_revisions() {
    ARG_REV_A="$1"
    ARG_REV_B="$2"

    git diff $ARG_REV_A...$ARG_REV_B --name-status
}

_has_comma() {
    grep -b -o "," <<< "$1" > /dev/null
}

_has_space() {
    grep -b -o " " <<< "$1" > /dev/null
}

_diffe_is_valid_revision () {
    local REV="${@}"

    git log "$REV" &> /dev/null
}

_diffe_is_argument_valid_revision_tuple () {
    local ARG_REVISION_TUPLE="$@"

    if ! _has_space "$ARG_REVISION_TUPLE"
    then
        return 1
    fi

    local REV_A=$(echo "$ARG_REVISION_TUPLE" | cut -d ' ' -f 1)
    local REV_B=$(echo "$ARG_REVISION_TUPLE" | cut -d ' ' -f 2)

    if ! _diffe_is_valid_revision "$REV_A"
    then
        return 1
    fi

    if ! _diffe_is_valid_revision "$REV_B"
    then
        return 1
    fi

    return 0
}

_find_line () {
    X="0"
    while read -r LINE
    do
        X=$((X+1))

        if [ "${LINE}" == "${1}" ]
        then
            printf "%s" "${X}"

            return
        fi
    done

    printf "%s" "0"
}

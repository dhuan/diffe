_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE="DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE"

diffe () {
    if ! _git_verify_repo
    then
        echo "This command is supposed to be executed only inside git repositories."

        return
    fi

    local MODE="$1"
    local DIFF_REVISION=""

    if [[ -z "$DIFFE_PROGRAM" ]]
    then
        local DIFFE_PROGRAM="vim -d % %"
    fi

    if [ -z "$(printf "%s" "${@}")" ]
    then
        WIP_MODE="true" _diffe_run "NONE" "NONE" "$DIFFE_PROGRAM"

        return
    fi

    if _diffe_is_argument_valid_revision_tuple "$@"
    then
        DIFF_REVISION="$@"
    fi

    if _diffe_is_valid_revision "${@}"
    then
        DIFF_REVISION="$(printf "%s %s" "${@}^" "${@}")"
    fi

    if [ -z "$DIFF_REVISION" ]
    then
        echo "Usage:"
        echo ""
        echo "$ diffe rev1 rev2"

        return
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
        local CHOSEN_FILE=""
        local FILES_LIST=""
        local PREVIEW_ARG=""

        if [ "${WIP_MODE}" = "true" ]
        then
            FILES_LIST="$(_git_get_files_changed_wip)"
            PREVIEW_ARG='git diff --color=always {}'
        else
            FILES_LIST="$(_git_get_files_changed_from_two_revisions "$ARG_REV_A" "$ARG_REV_B" | awk '{print $2}')"
            PREVIEW_ARG='git diff --color=always '"${ARG_REV_A}"'...'"${ARG_REV_B}"' -- {}'
        fi

        CHOSEN_FILE=$(printf "%s" "${FILES_LIST}" \
            | fzf --preview "${PREVIEW_ARG}"  \
                --sync --bind "start:pos(${INDEX})"
        )

        if [ -z "$CHOSEN_FILE" ]
        then
            break
        fi

        INDEX=$(printf "%s" "${FILES_LIST}" \
            | _find_line "${CHOSEN_FILE}")

        if [ "${WIP_MODE}" = "true" ]
        then
            git show "HEAD":"$CHOSEN_FILE" > "$FILE_DIFF_A"
            cat "$CHOSEN_FILE" > "$FILE_DIFF_B"
        else
            git show "$ARG_REV_A":"$CHOSEN_FILE" > "$FILE_DIFF_A"
            git show "$ARG_REV_B":"$CHOSEN_FILE" > "$FILE_DIFF_B"
        fi

        local DIFFE_PROGRAM_MODIFIED="$ARG_DIFFE_PROGRAM"
        DIFFE_PROGRAM_MODIFIED=${DIFFE_PROGRAM_MODIFIED/\%/$FILE_DIFF_A}
        DIFFE_PROGRAM_MODIFIED=${DIFFE_PROGRAM_MODIFIED/\%/$FILE_DIFF_B}

        $DIFFE_PROGRAM_MODIFIED
    done
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

    if ! printf "%s" "$REVS" | _contains ","
    then
        echo "$_DIFFE_GET_REV_ERROR_DID_NOT_CHOOSE_MULTIPLE"

        return
    fi

    echo "$REVS"
}

_git_get_files_changed_from_two_revisions() {
    ARG_REV_A="$1"
    ARG_REV_B="$2"

    git diff $ARG_REV_A...$ARG_REV_B --name-status
}

_git_get_files_changed_wip () {
    git status --short | awk '{print $2}'
}

_contains() {
    grep -oqF "${1}" 2> /dev/null
}

_diffe_is_valid_revision () {
    local REV="${@}"

    git log "$REV" &> /dev/null
}

_diffe_is_argument_valid_revision_tuple () {
    local ARG_REVISION_TUPLE="$@"

    if ! printf "%s" "$ARG_REVISION_TUPLE" | _contains ' '
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
    awk 'BEGIN {X=0} $0 == "'"${1}"'" {X=NR} END {print X}'
}

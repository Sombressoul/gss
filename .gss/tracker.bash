#!/bin/bash

# Defines
SELF=${0}

# Imports
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

EXEC_FNAME="$DIR/lib/functions.bash"
source $EXEC_FNAME
EXEC_FNAME="$DIR/lib/defines.bash"
source $EXEC_FNAME

# Begin script code
OPT=`echo $1 | tr '[:upper:]' '[:lower:]'`

if # Check subcommands
[ "$OPT" != "reveal" ] &&
[ "$OPT" != "hide" ] &&
[ "$OPT" != "list-hidden" ] &&
[ "$OPT" != "list-patterns" ] &&
[ "$OPT" != "pattern-test" ] &&
[ "$OPT" != "clear-stage" ]
then
    echo "ERROR: Subcommand unrecognized or missed."
    echo "Usage:"
    echo "tracker.bash hide|reveal|list-hidden|list-patterns|clear-stage|pattern-test <pattern>"
    exit 0
fi

# SUBCOMMAND START ==>
# list-hidden
if [ "$OPT" = "list-hidden" ]
then
    
    FIDX=0
    IFS=$'\n'
    
    for FNAME in $(git ls-files -v | grep '^h')
    do
        printf "idx:$GREEN%s$NOCOLOR\t>\t$GREEN%s$NOCOLOR\r\n" "$FIDX" "${FNAME//$'h '}"
        ((FIDX++))
    done
    
    unset IFS
    
    printf "Total hidden files: $GREEN%s$NOCOLOR\r\n" "$FIDX"
    
    exit 0
    
fi
# <== SUBCOMMAND END
# list-hidden

# SUBCOMMAND START ==>
# pattern-test
if [ "$OPT" = "pattern-test" ]
then
    
    if [ ! $2 ]
    then
        echo "ERROR: Pattern required."
        echo "Example:"
        echo "tracker.bash pattern-test /*.md"
        exit 0
    else
        PATTERN=$2
    fi
    
    echo "Testing pattern: $PATTERN"
    echo -e "Affecting files:"
    
    for FNAME in $(git ls-files | grep $PATTERN)
    do
        echo -e "> $GREEN$FNAME$NOCOLOR"
    done
    
    
    echo -e "Pattern testing completed. See the resuts above."
    exit 0
    
fi
# <== SUBCOMMAND END
# pattern-test

IFS=' ' read -r -a TRACKING_PATTERNS <<< `getTrackingPatterns`
if [ "$TRACKING_PATTERNS" = "__NOT__FOUND__" ]
then
    echo "Tracking list not found. Tracking list fname: $DIR/lists/tracking.list"
    exit 0
fi
unset IFS

# SUBCOMMAND START ==>
# clear-stage
if [ "$OPT" = "clear-stage" ]
then

    ENTRY_IDX=0
    IFS=$'\r\n'
    for STATUS_LINE in $(git status --porcelain=2)
    do

        IFS=', ' read -r -a STATUS_ARRAY <<< "$STATUS_LINE"
        if # If ordinary changed
        [ "${STATUS_ARRAY[0]}" = "1" ] &&
        [ "${STATUS_ARRAY[1]}" = "M." ]
        then

            ENTRY_FNAME=${STATUS_ARRAY[8]}

            # Iterate over existing patterns and compare
            for PATTERN in "${TRACKING_PATTERNS[@]}"
            do
                TEST=`echo $ENTRY_FNAME | grep $PATTERN`
                if [ "$TEST" != "" ]
                then
                    $(git restore --staged $ENTRY_FNAME &> /dev/null)
                    printf "Unstaged:\tidx:$GREEN%s$NOCOLOR\t>\t$GREEN%s$NOCOLOR\r\n" $ENTRY_IDX $ENTRY_FNAME
                    ((ENTRY_IDX++))
                    break
                fi
            done

        fi
        unset IFS

    done
    unset IFS

    if [ $ENTRY_IDX -eq 0 ]
    then
        echo "Nothing to unstage."
        exit 0
    else
        printf "Unstaged entries count: $GREEN%s$NOCOLOR\r\n" "$ENTRY_IDX"
    fi

    echo -e "$GREEN""Now executing \"$SELF hide\" command.""$NOCOLOR"
    $SELF "hide"

    exit 0

fi
# <== SUBCOMMAND END
# clear-stage

# SUBCOMMAND START ==>
# list-patterns
if [ "$OPT" = "list-patterns" ]
then

    PATTERN_IDX=0
    for MATCH in "${TRACKING_PATTERNS[@]}"
    do
        printf "idx:$GREEN%s$NOCOLOR\t>\t$GREEN%s$NOCOLOR\r\n" $PATTERN_IDX $MATCH
        ((PATTERN_IDX++))
    done

    if [ $PATTERN_IDX -eq 0 ]
    then
        echo "Active patterns not found."
    else
        printf "Total patterns count: $GREEN%s$NOCOLOR\r\n" "$PATTERN_IDX"
    fi

    exit 0

fi
# <== SUBCOMMAND END
# list-patterns

# SUBCOMMAND START ==>
# reveal
# hide
if [ "$OPT" = "reveal" ] || [ "$OPT" = "hide" ]
then

    echo -e "Executing."$RED
    PATTERNS_ITERATOR=0
    FILES_AFFECTED=0
    for PATTERN in "${TRACKING_PATTERNS[@]}"
    do
        ((PATTERNS_ITERATOR++))

        for FNAME in $(git ls-files | grep $PATTERN)
        do
            ((FILES_AFFECTED++))
            if [ "$OPT" = "reveal" ]
            then
                git update-index --no-assume-unchanged "$FNAME"
            elif [ "$OPT" = "hide" ]
            then
                git update-index --assume-unchanged "$FNAME"
            fi
        done

    done
    echo -e $NOCOLOR"Done."
    echo -e "> "$GREEN"Patterns processed: ${PATTERNS_ITERATOR}"$NOCOLOR
    echo -e "> "$GREEN"Total patterns matches: ${FILES_AFFECTED}"$NOCOLOR

    # Just final info.
    if [ "$OPT" = "reveal" ]
    then
        echo "Patterns from the tracking list now should be tracking by Git again."
    else
        echo "Git should now ignore changes to files that match the patterns from the tracking list."
    fi

    echo "REMEMBER: depending on your OS, tracking patterns can be case-sensitive!"
    echo "Use one of the following commands to check results:"
    echo "$ tracker.bash list-hidden"
    echo "$ git ls-files -v | grep '^h'"

    exit 0

fi
# <== SUBCOMMAND END
# reveal
# hide
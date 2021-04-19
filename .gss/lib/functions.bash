#!/bin/bash

getTrackingPatterns(){
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    TRACKING_LIST_FNAME="$DIR/../lists/tracking.list"
    
    if [ ! -f "$TRACKING_LIST_FNAME" ]
    then
        echo "__NOT__FOUND__"
        exit 0
    fi
    
    ITERATOR=0
    while IFS="" read -r LINE || [ -n "$LINE" ]
    do
        BUF=${LINE//[$'\t\r\n']}
        BUF=`echo "$BUF" | xargs | grep "^[^#]"`
        
        if [ "$BUF" != "" ]
        then
            TRACKING_PATTERNS_ARRAY[$ITERATOR]="$BUF"
            ((ITERATOR++))
        fi
    done < "$TRACKING_LIST_FNAME"
    unset IFS
    
    echo "${TRACKING_PATTERNS_ARRAY[@]}"
    return 0
}
#!/bin/bash

if [ -f $1 ]; then
        INPUT=$1
else
        echo "Input file not found!"
        echo "Usage: $0 <input_file>"
        exit 1;
fi
OUTPUT=$INPUT.short

LEN=$(cat $INPUT | wc -l)
LINE_NUM=0

while read line; do
        let LINE_NUM=LINE_NUM+1
        HITS=$(tail -n$(($LEN-$LINE_NUM)) $INPUT | grep "$line" | wc -l)
        if [ $HITS -eq 0 ]; then
                echo $line >> $OUTPUT
        fi
done <$INPUT

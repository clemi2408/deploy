#!/bin/bash

commons_deleteFolder(){

    local dir="$1"

    if [[ ! -e $dir ]]; then
        echo "WARN: Unable to delete directory $dir " 1>&2
    elif [[ -d $dir ]]; then
        echo "INFO: Deleting directory $dir" 1>&2
        rm -r $dir
    fi
}

commons_deleteFile(){

    local file="$1"

    if [[ ! -e $file ]]; then
        echo "WARN: Unable to delete file $file " 1>&2
    elif [[ -f $file ]]; then
        echo "INFO: Deleting file $file" 1>&2
        rm $file
    fi
}

commons_createFolder(){

    local dir="$1"

    if [[ ! -e $dir ]]; then
        echo "INFO: Creating $dir " 1>&2
        mkdir -p $dir
    elif [[ -d $dir ]]; then
        echo "WARN: $dir already exists" 1>&2
    fi
}

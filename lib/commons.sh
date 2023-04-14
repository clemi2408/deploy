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


commons_copyFile(){

    local source="$1"
    local target="$2"

    if [[ ! -e $source ]]; then
        echo "WARN: Source not found copying $source to $target" 1>&2
    elif [[ -f $source ]]; then
        echo "INFO: Copy $source to $target" 1>&2
        cp $source $target
    fi
}

commons_moveFile(){

    local source="$1"
    local target="$2"

    if [[ ! -e $source ]]; then
        echo "WARN: Source not found moving $source to $target" 1>&2
    elif [[ -f $source ]]; then
        echo "INFO: Moving $source to $target" 1>&2
        mv $source $target
    fi
}

commons_setOwnerRecursive(){

    local username="$1"
    local target="$2"

    if [[ -e $target ]]; then
        echo "INFO: Setting ownership for $target to $username" 1>&2
        chown -R $username:$username $target
    else
       echo "WARN: Can not set ownership for $target to $username" 1>&2
    fi

}

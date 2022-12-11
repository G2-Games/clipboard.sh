#!/bin/sh
ver=0.0.1
clipboarddir=/tmp/clipboardsh
clipboardfile=/tmp/clipboardsh/clipboard
op=$1
target=$2
number=0

# Colors:
empty="[\033[35m?\033[0m]"
success="[\033[32m✓\033[0m]"
fail="[\033[31m✗\033[0m]"


copy () {
    # Find the absolute path of the requested file or folder...
    path="$(cd "$(dirname -- "$target")" >/dev/null; pwd -P)/$(basename -- "$target")"

    if grep -sq "$path" $clipboardfile; then
        echo "$fail \033[32m$target\033[0m already in clipboard"
        exit 0
    fi

    # Create the clipboard directory if it doesn't already exist
    mkdir -p $clipboarddir
    # Create the clipboard file if it doesn't already exist, if it does, assign a number to the file
    if [ -f $clipboardfile ]; then
        number=$(tail -n 1 $clipboardfile | cut -d ':' -f2)
        number=$((number + 1))
    else
        touch $clipboardfile
        number=0
    fi
    # Store the file location in the clipboard with the operation
    cp $path "$clipboarddir/$number.tmp"
    echo "copy:$number:$path" >> $clipboardfile
    echo "Copied \033[33;1m$target\033[0m to clipboard"
}

ct () { # Cut
    echo cut
}

cl () { # Clear
    if [ -d "$clipboarddir" ]; then
        rm -r $clipboarddir
        echo "$success Clipboard cleared"
    else
        echo "$empty Clipboard already empty"
    fi
}

pt () {
    if [ -f $clipboardfile ]; then
        file=$(tail -n 1 $clipboardfile | cut -d ':' -f3)
        name=$(tail -n 1 $clipboardfile | rev | cut -d '/' -f1 | rev)
        operation=$(tail -n 1 $clipboardfile | cut -d ':' -f1)
        number=$(tail -n 1 $clipboardfile | cut -d ':' -f2)
        if [ -f $name ]; then
            tput sc
            echo -n "\033[33;1m$name\033[0m already exists in this folder, do you want to overwrite?"
            read -p " y/N " yn
            case $yn in
                [Yy]* ) echo cp -rf "$clipboarddir/$number.tmp" $name && tput rc;tput el; echo "$success Pasted \033[33;1m$name\033[0m";;
                [Nn]* ) exit;;
                * ) exit;;
            esac
        else
            cp "$clipboarddir/$number.tmp" $name
            echo "$success Pasted \033[33;1m$name\033[0m"
        fi
    else
        echo "$empty Nothing to paste"
        exit 0
    fi
}

show () {
    if [ -f $clipboardfile ]; then
        cat $clipboardfile | rev | cut -d '/' -f1 | rev
    else
        echo "$empty Clipboard empty"
    fi
}

if [ "$op" = "copy" ]; then
    copy
elif [ "$op" = "cut" ]; then
    ct
elif [ "$op" = "paste" ]; then
    pt
elif [ "$op" = "clear" ]; then
    cl
elif [ "$op" = "show" ]; then
    show
else
    show
fi

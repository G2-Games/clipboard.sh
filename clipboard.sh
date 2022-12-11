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
    tput sc
    echo "Copying $target to clipboard..."
    if [ -z $target ] || ! [ -f $target ]; then
        echo "$fail File not found"
        exit
    fi

    # Find the absolute path of the requested file or folder...
    path="$(cd "$(dirname -- "$target")" >/dev/null; pwd -P)/$(basename -- "$target")"

    if grep -sq "$path" $clipboardfile; then
        echo "$fail \033[33;1m$target\033[0m already in clipboard"
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
    cp -r "$path" "$clipboarddir/$number.tmp"
    echo "copy:$number:$path" >> $clipboardfile
    tput rc
    tput el
    echo "$success Copied \033[33;1m$target\033[0m to clipboard"
}

ct () { # Cut
    echo cut
}

cl () { # Clear
    if [ -d "$clipboarddir" ]; then
        rm -fr $clipboarddir
        echo "$success Clipboard cleared"
    else
        echo "$empty Clipboard already empty"
    fi
}

pt () {
    if [ -f $clipboardfile ]; then
        if [ -z $target ]; then
            file=$(tail -n 1 $clipboardfile | cut -d ':' -f3)
            name=$(tail -n 1 $clipboardfile | rev | cut -d '/' -f1 | rev)
            operation=$(tail -n 1 $clipboardfile | cut -d ':' -f1)
            number=$(tail -n 1 $clipboardfile | cut -d ':' -f2)
        elif [ $(cat "$clipboardfile" | wc -l) -ge $((target + 1)) ]; then
            target=$((target + 1))
            file=$(sed "${target}q;d" $clipboardfile | cut -d ':' -f3)
            name=$(sed "${target}q;d" $clipboardfile | rev | cut -d '/' -f1 | rev)
            operation=$(sed "${target}q;d" $clipboardfile | cut -d ':' -f1)
            number=$(sed "${target}q;d" $clipboardfile | cut -d ':' -f2)
        else
            echo "$fail Invalid history line"
            exit
        fi
        if [ -f $name ]; then
            tput sc
            echo -n "\033[33;1m$name\033[0m already exists in this folder, do you want to overwrite?"
            read -p " y/N " yn
            case $yn in
                [Yy]* ) overwrite=1;;
                [Nn]* ) tput rc;tput el;echo "$fail Canceled"; exit;;
                * ) tput rc;tput el;echo "$fail Canceled"; exit;;
            esac
            if [ $overwrite -eq 1 ]; then
                echo cp -rf "$clipboarddir/$number.tmp" $name
                tput rc
                tput el
                echo "$success Pasted \033[33;1m$name\033[0m"
            else
                exit
            fi
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
        echo "\033[35;1;4mClipboard History:\033[0m"
        printf '%s\n' "$(tac $clipboardfile)" | while IFS= read -r line; do
            filename=$(echo "$line" | rev | cut -d '/' -f1 | rev)
            number=$(echo $line | cut -d ':' -f2)
            echo "$number: $filename"
        done
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
elif [ -z "$op" ]; then
    show
else
    echo "$fail Invalid argument"
fi

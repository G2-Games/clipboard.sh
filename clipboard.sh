#!/bin/sh
version=0.0.1
clipboarddir=/tmp/clipboardsh
clipboardfile=/tmp/clipboardsh/clipboard
op=$1
target=$2
number=0

# Colors:
empty="[\033[35m?\033[0m]"
success="[\033[32m✓\033[0m]"
fail="[\033[31m✗\033[0m]"
wait="[\033[34m…\033[0m]"

setup () {
    # Test if the target exists
    if [ -z "$target" ] || ! [ -f "$target" ]; then
        tput rc el ed
        echo "$fail File not found"
        exit 1
    fi

    # Find the absolute path of the requested file or folder...
    path="$(cd "$(dirname -- "$target")" >/dev/null; pwd -P)/$(basename -- "$target")"

    name="$(echo $path | rev | cut -d '/' -f1 | rev)"

    # Make sure the file isn't already in the clipboard
    if grep -sqF "$name" "$clipboardfile"; then
        tput rc el ed
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
}

copy () {
    tput sc
    echo "$wait Copying $target to clipboard..."

    setup

    # Store the file location in the clipboard with the operation
    cp -r "$path" "$clipboarddir/$number.tmp"
    echo "copy:$number:$path" >> $clipboardfile
    tput rc el ed
    echo "$success Copied \033[33;1m$target\033[0m to clipboard"
}

ct () { # Cut
    tput sc
    echo "$wait Cutting $target to clipboard..."

    setup

    # Store the file location in the clipboard with the operation
    cp -r "$path" "$clipboarddir/$number.tmp"
    echo "cut:$number:$path" >> $clipboardfile
    tput rc el ed
    echo "$success Cut \033[33;1m$target\033[0m to clipboard"
}

cl () { # Clear
    if [ -d "$clipboarddir" ]; then
        rm -fr $clipboarddir
        echo "$success Clipboard cleared"
    else
        echo "$empty Clipboard already empty"
    fi
}

remove () {
    target=$(echo "$target" | sed 's/[^0-9]*//g')
    if [ -n "$target" ]; then
        lines="$(cat "$clipboardfile" | cut -d ':' -f2)"
        linenum=$(echo "$lines" | grep -n "$target" | cut -d ':' -f1)
        if [ -n "$linenum" ]; then
            sed -i "${linenum}d" $clipboardfile
            rm -f "$clipboarddir/$target.tmp"
            echo "$success Deleted clipboard item #$target"
        else
            echo "$fail Item #$target doesn't exist"
        fi
        exit
    else
        echo "$fail Please specify a clip number to remove"
    fi
}

pt () { # Paste
    target=$(echo "$target" | sed 's/[^0-9]*//g')
    if [ -f $clipboardfile ]; then
        lines="$(cat "$clipboardfile" | cut -d ':' -f2)"
        linenum=$(echo "$lines" | grep -n "$target" | cut -d ':' -f1)
        if [ -z "$target" ]; then
            file="$(tail -n 1 $clipboardfile | cut -d ':' -f3)"
            name="$(tail -n 1 $clipboardfile | rev | cut -d '/' -f1 | rev)"
            operation="$(tail -n 1 $clipboardfile | cut -d ':' -f1)"
            number="$(tail -n 1 $clipboardfile | cut -d ':' -f2)"
        elif [ $(cat "$clipboardfile" | wc -l) -ge $((target + 1)) ] && [ "$target" -eq "$target" ]; then
            target=$((target + 1))
            file="$(sed "${linenum}q;d" $clipboardfile | cut -d ':' -f3)"
            name="$(sed "${linenum}q;d" $clipboardfile | rev | cut -d '/' -f1 | rev)"
            operation="$(sed "${linenum}q;d" $clipboardfile | cut -d ':' -f1)"
            number="$(sed "${linenum}q;d" $clipboardfile | cut -d ':' -f2)"
        else
            echo "$fail Invalid history line"
            exit
        fi
        tput sc
        if [ -f "$name" ]; then
            echo -n "\033[33;1m$name\033[0m already exists in this folder, do you want to overwrite?"
            read -p " y/N " yn
            case $yn in
                [Yy]* ) ;;
                    * ) tput rc el ed;echo "$fail Canceled paste"; exit;;
            esac
        fi
        echo "$wait Pasting \033[33;1m$name\033[0m from clipboard..."
        cp -rf "$clipboarddir/$number.tmp" "$name"
        if [ "$operation" = "cut" ]; then
            rm $file
        fi
        tput rc el ed
        echo "$success Pasted \033[33;1m$name\033[0m"
    else
        echo "$empty Nothing to paste"
        exit 0
    fi
}

list () { # Show clipboard
    first=" \033[32;1m<= Current\033[0m"
    if [ -f $clipboardfile ]; then
        echo "\033[35;1;4mClipboard History:\033[0m"
        printf '%s\n' "$(tac $clipboardfile)" | while IFS= read -r line; do
            filename=$(echo "$line" | rev | cut -d '/' -f1 | rev)
            operation=$(echo "$line" | cut -d ':' -f1)
            number=$(echo $line | cut -d ':' -f2)
            echo "\033[34;1m$number:\033[33m $operation\033[0m $filename$first"
            first=""
        done
    else
        echo "$empty Clipboard empty"
    fi
}

help () {
    echo "\033[33mclipboard.sh:\033[0m command line clipboard utility
\033[35;1;4mUsage:\033[0m
\033[32mcb\033[0m \033[34m<copy|cut|paste|clear|show> \033[36m[file...]

\033[35;1;4mOperations:\033[0m
  copy  [file]    : Copy a file
  cut   [file]    : Cut a file
  paste [clip #]  : Paste a file
  clear           : Clear the clipboard
  remove [clip #] : Remove a certain clip from the clipboard
  list            : Show the copied files (default)
  help            : Displays the help
"
}

# Check for the requested operation
if [ "$op" = "copy" ] || [ "$op" = "cp" ]; then
    copy
elif [ "$op" = "cut" ] || [ "$op" = "ct" ]; then
    ct
elif [ "$op" = "paste" ]; then
    pt
elif [ "$op" = "clear" ]; then
    cl
elif [ "$op" = "remove" ] || [ "$op" = "rm" ]; then
    remove
elif [ "$op" = "list" ] || [ "$op" = "ls" ]; then
    list
elif [ "$op" = "help" ] || [ "$op" = "?" ]; then
    help
elif [ -z "$op" ]; then
    list
else
    echo "$fail Invalid argument"
    echo
    help
fi

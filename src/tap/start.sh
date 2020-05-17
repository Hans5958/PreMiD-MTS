export OFFLINE=false

usage() {
	echo -e $GREETING
	cat << EOF >&2
Usage: $0 service-name [-h] [--help]

path                Path to the presence folder OR the metadata.json file.
-o/--offline        Use offline mode.
EOF
    printf "\e[0m"
    exit 255
}

# https://stackoverflow.com/a/29754866

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    exit 255
fi
OPTIONS=hovrt
LONGOPTS=help,ofline,verbose,results,tap
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 255
fi
eval set -- "$PARSED"
while true; do
    case "$1" in
        -o|--offline)
            OFFLINE=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            exit 1
            ;;
    esac
done
if [[ $# -ne 1 ]]; then
    usage
fi

export RETURN1=true
export RETURN2=false
export SUPP=false

if [[ $1 == *metadata.json ]]; then
    export METADATA_DIR=$1
else
    export METADATA_DIR=$1/dist/metadata.json
fi
if [ -f "$METADATA_DIR" ]; then
    METADATA=$(cat "$METADATA_DIR")
else
    echo "Bail out! $METADATA_DIR does not exist."
    exit 255
fi

if [ $OFFLINE == false ]; then
    export LANG_LIST=$((($LOG_LEVEL > 1)) && curl https://api.premid.app/v2/langFile/list || curl https://api.premid.app/v2/langFile/list -s)
fi

test() {
    local MESSAGE="blank"
    test_ok() {
        local MESSAGE="ok $1"
        export RETURN1=true
    }
    test_fail() {
        local MESSAGE="not ok $1"
        export RETURN1=false
        export RETURN2=false
    }
    test_skip() {
        local MESSAGE="ok $1 # skip"
        export RETURN1=false
    }
    test_ongoing() {
        export RETURN1=true
        export RETURN2=true
    }
    send_message() {
		if [[ $MESSAGE != "blank" ]]; then
            echo -e "$MESSAGE"
		fi
    }

    if [[ $2 == true ]]; then
        test_ok "$1" "$2"
    elif [[ $2 == false ]]; then
        ("$3" == true) && test_skip "$1" "$2" || test_fail "$1" "$2"
    elif [[ $2 == "" ]]; then
        ("$3" == true) && test_skip "$1" "$2" || test_fail "$1" "$2"
    elif [[ $2 == "ongoing" ]]; then
        test_ongoing "$1"
    else
        test_ok "$1" "$2"
    fi

    send_message
}

test_message() {
    true
}

echo -e "1..30"
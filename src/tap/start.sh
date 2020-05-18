export TEST_MAIN_OK=0
export TEST_MAIN_FAIL=0
export TEST_MAIN_SKIP=0
export TEST_SUPP_OK=0
export TEST_SUPP_FAIL=0
export TEST_SUPP_SKIP=0

# https://stackoverflow.com/a/29754866

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    cecho "\"getopt --test\" failed in this environment."
    exit 255
fi
OPTIONS=ho
LONGOPTS=help,ofline
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 255
fi
eval set -- "$PARSED"
while true; do
    case "$1" in
		-h|--help)
            INIT_EXIT=true
            shift
            ;;
        -o|--offline)
            OFFLINE=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            cecho "Invalid argument."
            exit 255
            ;;
    esac
done

cecho() {
    printf "$*\n"
}

usage() {
    cecho "$(echo "$GREETING" | sed -r "s/\\\e\[([0-9;]+)m//g")"
    printf "\e[97m"
	cat << EOF >&2
Usage: $0 [-ho] [--help] [--offline] path

path                Path to the presence folder OR the metadata.json file.
-h/--help           Print this help text.
-o/--offline        Use offline mode.
EOF
    printf "\e[0m"
    exit 255
}

if [[ $# -ne 1 ]] || $INIT_EXIT ; then
    usage
fi

if [[ $1 == *metadata.json ]]; then
    export METADATA_DIR="$1"
else
    export METADATA_DIR="$1/dist/metadata.json"
fi

if [ -f "$METADATA_DIR" ]; then
    METADATA=$(cat "$METADATA_DIR")
else
    echo "Bail out! $METADATA_DIR does not exist."
    exit
fi

if (! $OFFLINE); then
    LANG_LIST="$(curl https://api.premid.app/v2/langFile/list -s)"
fi

test() {
    local message="blank"
    local test_name=$1
    local test_result=$2
    local optional=${3:-true}
    local supp=${4:-false}

    test_ok() {
        local MESSAGE="ok $test_name"
        export RETURN1=true
    }
    test_fail() {
        local MESSAGE="not ok $test_name"
        export RETURN1=false
        export RETURN2=false
    }
    test_skip() {
        local MESSAGE="ok $test_name # skip"
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

    if [[ $test_result == true ]]; then
        test_ok "$test_name"
    elif [[ $test_result == false ]]; then
		if $optional; then 
			test_skip "$test_name"
		else
			test_fail "$test_name"
		fi
    elif [[ $test_result == "" ]]; then
		if $optional; then 
			test_skip "$test_name"
		else
			test_fail "$test_name"
		fi
    elif [[ $test_result == "ongoing" ]]; then
        test_ongoing "$test_name"
    else
        test_ok "$test_name"
    fi

    send_message
}

test_message() {
    case "$1" in
		"required")
            cecho "# Required Values"
            ;;
        "optional")
            cecho "# Optional Values"
            ;;
		"finished")
            ;;
    esac
}

echo "1..30"
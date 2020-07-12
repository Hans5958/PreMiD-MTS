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
OPTIONS=hovrn
LONGOPTS=help,ofline,verbose,results,no-ansi
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
		-v|--verbose)
            LOG_LEVEL=2
            shift
            ;;
		-r|--results)
			LOG_LEVEL=0
            shift
            ;;
        -n|--no-ansi)
			NO_ANSI=true
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            cecho "Invalid argument."
            INIT_EXIT=true
            ;;
    esac
done

cecho() {
    if $NO_ANSI; then 
        printf "$(echo "$*" | sed -r "s/\\\e\[([0-9;]+)m//g")\n"
    else
        printf "$*\n"
    fi
}

cecho "$GREETING"

usage() {
    printf "\e[97m"
	cat << EOF >&2
Usage: $0 [-hovrn] [--help] [--offline] [--verbose] [--results] [--no-ansi] path

path                Path to the presence folder OR the metadata.json file.
-h/--help           Print this help text.
-o/--offline        Use offline mode.
-v/--verbose        Print the logs with more information.
-r/--results        Print only the results.
-n/--no-ansi        Print the logs without ANSI codes for viewing in text editors. Slower.
EOF
    printf "\e[0m"
    exit 255
}

if [[ $# -ne 1 ]] || $INIT_EXIT ; then
    usage
fi

if [[ $1 == *metadata.json ]]; then
    export METADATA_DIR=$1
else
    export METADATA_DIR=$1/dist/metadata.json
fi

if [ -f "$METADATA_DIR" ]; then
    [[ $LOG_LEVEL -gt 0 ]] && cecho "\e[97m$METADATA_DIR exists. Continuing...\e[90m"
    [[ $LOG_LEVEL -gt 1 ]] && cat "$METADATA_DIR"
    METADATA=$(cat "$METADATA_DIR")
else
    cecho "\e[97m$METADATA_DIR does not exist. Stopping."
    cecho "Run \"$0 -h\" for help."
    exit 255
fi

[[ $LOG_LEVEL -gt 0 ]] && cecho "\e[97mPreparing language list...\e[90m"
if (! $OFFLINE); then
    LANG_LIST="$(curl https://api.premid.app/v2/langFile/list $( [[ ! $LOG_LEVEL -gt 1 ]] && echo -s ) )"
fi
[[ $LOG_LEVEL -gt 1 ]] && cecho "$LANG_LIST"
[[ $LOG_LEVEL -gt 0 ]] && cecho "\e[97mDone. Start testing."

test() {
    local message="blank"
    local test_name=$1
    local test_result=${2//%/%%}
    local optional=${3:-false}
    local supp=${4:-false}

    test_ok() {
        message="\e[42;97m OK \e[0;97m \e[0;97m$test_name\e[0m \e[37m($test_result)"
        RETURN1=true
        if $supp; then
            ((TEST_SUPP_OK+=1))
        else
            ((TEST_MAIN_OK+=1))
        fi
    }
    test_fail() {
        message="\e[41;97mFAIL\e[0;97m \e[0;107m\e[30m$test_name\e[0m \e[37m($test_result)"
        RETURN1=false
        RETURN2=false
        if $supp; then
            ((TEST_SUPP_FAIL+=1))
        else
            ((TEST_MAIN_FAIL+=1))
        fi
    }
    test_skip() {
        message="\e[107;30mSKIP\e[0;97m \e[0;97m$test_name\e[0m \e[37m($test_result)"
        RETURN1=false
        if $supp; then
            ((TEST_SUPP_SKIP+=1))
        else
            ((TEST_MAIN_SKIP+=1))
        fi
    }
    test_ongoing() {
        message="\e[107;30mONGO\e[0;97m \e[0;97m$test_name"
        RETURN1=true
        RETURN2=true
    }
    send_message() {
		if [[ $message != "blank" && $LOG_LEVEL -gt 0 ]]; then
            (! $NO_ANSI) && tput cuu 1 && tput el
			if $supp; then
				cecho "     $message"
			else
				cecho "$message"
			fi
            (! $NO_ANSI) && cecho "\e[0;97mTesting... \e[0;37m($((TEST_MAIN_OK + TEST_SUPP_OK)) passed, $((TEST_MAIN_FAIL + TEST_SUPP_FAIL)) failed, $((TEST_MAIN_SKIP + TEST_SUPP_SKIP)) skipped, $(((TEST_MAIN_OK + TEST_MAIN_FAIL + TEST_MAIN_SKIP + TEST_SUPP_OK + TEST_SUPP_FAIL + TEST_SUPP_SKIP)*100/(MAIN_TESTS + TEST_SUPP_OK + TEST_SUPP_FAIL + TEST_SUPP_SKIP)))%%)"
		fi
    }

    if [[ $test_result == true ]]; then
        test_ok "$test_name" "$test_result"
    elif [[ $test_result == false ]]; then
		if $optional; then 
			test_skip "$test_name" "$test_result"
		else
			test_fail "$test_name" "$test_result"
		fi
    elif [[ $test_result == "" ]]; then
		if $optional; then 
			test_skip "$test_name" "$test_result"
		else
			test_fail "$test_name" "$test_result"
		fi
    elif [[ $test_result == "ongoing" ]]; then
        test_ongoing "$test_name"
    else
        test_ok "$test_name" "$test_result"
    fi

    send_message
}

test_message() {
    case "$1" in
		"required")
            [[ $LOG_LEVEL -gt 0 ]] && cecho "\n\e[97mTesting required values...\n\e[0m"
            (! $NO_ANSI) && cecho ""
            ;;
        "optional")
            (! $NO_ANSI) && tput cuu 1 && tput el
            [[ $LOG_LEVEL -gt 0 ]] && cecho "\n\e[97mTesting optional values...\n\e[0m"
            (! $NO_ANSI) && cecho ""
            ;;
		"finished")
            (! $NO_ANSI) && tput cuu 1 && tput el
            [[ $LOG_LEVEL -gt 0 ]] && cecho "\n\e[97mTest finished.\n\e[0m"
            ;;
    esac
}

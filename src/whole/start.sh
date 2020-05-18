export TEST_MAIN_OK=0
export TEST_MAIN_FAIL=0
export TEST_MAIN_SKIP=0
export TEST_SUPP_OK=0
export TEST_SUPP_FAIL=0
export TEST_SUPP_SKIP=0

export CSV=${1##*/}

cecho() {
    printf "$*\n"
}

cecho "$(echo $GREETING | sed -r "s/\\\e\[([0-9;]+)m//g")"
METADATA="$(cat "$1/dist/metadata.json")"

test() {
    local message="blank"
    local test_name=$1
    local test_result=$2
    local optional=${3:-true}
    local supp=${4:-false}

    test_ok() {
        message=" OK  $test_name ($test_result)"
        RETURN1=true
        if $supp; then
            ((TEST_SUPP_OK+=1))
        else
            ((TEST_MAIN_OK+=1))
            CSV="$CSV,OK"
        fi
    }
    test_fail() {
        message="FAIL $test_name ($test_result)"
        RETURN1=false
        RETURN2=false
        if $supp; then
            ((TEST_SUPP_FAIL+=1))
        else
            ((TEST_MAIN_FAIL+=1))
            CSV="$CSV,Fail"
        fi
    }
    test_skip() {
        message="SKIP $test_name ($test_result)"
        RETURN1=false
        if $supp; then
            ((TEST_SUPP_SKIP+=1))
        else
            ((TEST_MAIN_SKIP+=1))
            CSV="$CSV,Skip"
        fi
    }
    test_ongoing() {
        RETURN1=true
        RETURN2=true
    }
    send_message() {
		if [[ $message != "blank" && $LOG_LEVEL -gt 0 ]]; then
			if $supp; then
				cecho "     $message"
			else
				cecho "$message"
			fi
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
		"required") echo -e "Testing required values...\n";;
        "optional") echo -e "\nTesting optional values...\n";;
		"finished") echo -e "\nTest finished.\n";;
    esac
}
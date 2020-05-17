#!/bin/bash

export VERSION="1.0.0"
export REFERENCE="https://gist.github.com/Hans5958/88b83e20c24d2c60dacf9c2000363a82"

export GREETING="\n\e[97mPreMiD Presence Metadata Test Suite\nv$VERSION, by Hans5958\n\"probably the most accurate test suite\"\n"

export OFFLINE=false
export LOG_LEVEL=1
export TAP=false

usage() {
	echo -e $GREETING
	cat << EOF >&2
Usage: $0 service-name [-hovr] [--help] [--offline] [--verbose] [--results] path

path                Path to the presence folder OR the metadata.json file.
-h/--help           Prints this help text.
-o/--offline        Use offline mode.
-v/--verbose        Print more information.
-r/--results        Print only the results.

EOF
    printf "\e[0m"
    exit 255
}

# https://stackoverflow.com/a/29754866

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
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
		-h|--help)
            usage
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
            RESULTS=true
            shift
            ;;
		-t|--tap)
			LOG_LEVEL=-1
            TAP=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 1
            ;;
    esac
done
if [[ $# -ne 1 ]]; then
    usage
fi

(($LOG_LEVEL > -1)) && echo -e $GREETING

export RETURN1=true
export RETURN2=false
export SUPP=false

export TEST_MAIN_OK=0
export TEST_MAIN_FAIL=0
export TEST_MAIN_SKIP=0
export TEST_SUPP_OK=0
export TEST_SUPP_FAIL=0
export TEST_SUPP_SKIP=0

if [[ $1 == *metadata.json ]]; then
    export METADATA_DIR=$1
else
    export METADATA_DIR=$1/dist/metadata.json
fi
if [ -f "$METADATA_DIR" ]; then
    (($LOG_LEVEL > -1)) && echo -e "$METADATA_DIR exists. Continuing...\e[90m"
    METADATA=$(cat "$METADATA_DIR")
    (($LOG_LEVEL > 1)) && echo $METADATA
else
    echo -e "$METADATA_DIR does not exist. Stopping."
    echo "Run \"$0\" for help."
    exit 255
fi

(($LOG_LEVEL > 0)) && echo -e "\e[97mPreparing language list...\e[90m"
if [ $OFFLINE == false ]; then
    export LANG_LIST=$((($LOG_LEVEL > 1)) && curl https://api.premid.app/v2/langFile/list || curl https://api.premid.app/v2/langFile/list -s)
else
    export LANG_LIST='["ar_SA","cs_CZ","da_DK","de","en","es","he_IL","nl","ja_JP","pt_BR","sv_SE","ro","tr","it","pl","sk","zh_CN","fr","hu","no","ru","uk_UA","fi","ko_KR","pt","th","bs_BA","id","sl_SI","az","vi_VN","et_EE","bn_BD","lt","uz","zh_TW","ga_IE","bg","fa_IR"]'
fi
(($LOG_LEVEL > 1)) && echo $LANG_LIST
(($LOG_LEVEL > 0)) && echo -e "\e[97mDone. Start testing."
(($LOG_LEVEL > 0)) && echo ""

test() {
    local MESSAGE="blank"
    test_ok() {
        (! $TAP) && local MESSAGE="\e[42;97m OK \e[0;97m \e[0;97m$1\e[0m ($2)" || local MESSAGE="ok $1"
        export RETURN1=true
        (! $SUPP) && ((TEST_MAIN_OK+=1)) || ((TEST_SUPP_OK+=1))
    }
    test_fail() {
        (! $TAP) && local MESSAGE="\e[41;97mFAIL\e[0;97m \e[0;107m\e[30m$1\e[0m ($2)" || local MESSAGE="not ok $1"
        export RETURN1=false
        export RETURN2=false
        (! $SUPP) && ((TEST_MAIN_FAIL+=1)) || ((TEST_SUPP_FAIL+=1))
    }
    test_skip() {
        (! $TAP) && local MESSAGE="\e[107;30mSKIP\e[0;97m \e[0;97m$1\e[0m ($2)" || local MESSAGE="ok $1 # skip"
        export RETURN1=false
        (! $SUPP) && ((TEST_MAIN_SKIP+=1)) || ((TEST_SUPP_SKIP+=1))
    }
    test_ongoing() {
        (! $TAP) && local MESSAGE="\e[107;30mONGO\e[0;97m \e[0;97m$1s"
        export RETURN1=true
        export RETURN2=true
    }
    send_message() {
		if [[ $MESSAGE != "blank" && $LOG_LEVEL > 0 ]]; then
			if [[ $SUPP == true ]]; then
				(! $TAP) && echo -e "     $MESSAGE"
			else
				echo -e "$MESSAGE"
			fi
		fi
    }
    if [[ $4 == true ]]; then
        SUPP=true
    else
        SUPP=false
    fi

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

if $TAP; then
	LOG_LEVEL=1
	echo -e "1..30"
fi
((($LOG_LEVEL > 0)) && (! $TAP)) && echo -e "\e[97mTesting required values...\n\e[0m"

test "Author present" "$(echo $METADATA | jq -c 'has("author")')"
test "Author valid" "ongoing" true
test "Author name present" "$(echo $METADATA | jq -c '.author | if has("name") then .name else false end')" false true
test "Author name valid" "$(echo $METADATA | jq -c '.author.name | type == "string"')" false true
test "Author ID present" "$(echo $METADATA | jq -c '.author | if has("id") then .id else false end')" false true
test "Author ID valid" "$(echo $METADATA | jq -c '.author.id | test("^\\d+$")')" false true
if [[ $RETURN2 ]]; then
    test "Author valid" true
else
    test "Author valid" false
fi

test "Service present" "$(echo $METADATA | jq -c 'if has("service") then .service else false end')"
test "Service valid" $(echo $METADATA | jq -c '.service | type == "string"')

test "Description present" "$(echo $METADATA | jq -c 'has("description")')"
test "Description valid" "ongoing" true
test "Language en must exist" "$(echo $METADATA | jq -c '.description | has("en")')" false true
for lang in $(echo $METADATA | jq -r '.description | keys | .[]'); do
    LANG2="\"$lang\""
    test "Language $lang valid" "$(echo $LANG_LIST | jq "if index($LANG2) != null then true else false end")" false true
done
test "Description valid" "$RETURN2"

test "URL present" "$(echo $METADATA | jq -c 'if has("url") then .url else false end')"
if [[ $(echo $METADATA | jq -c '.url | type == "array"') == true ]]; then
    test "URL valid" "ongoing"
	test "URL array length > 1" $(echo $METADATA | jq -c '.url | length != 1') false true
    for item64 in $(echo $METADATA | jq --compact-output --raw-output '.url[] | @base64'); do
        item=$(echo $item64 | base64 -d)
        test "URL $item valid" "$((echo $item | grep -Eq "^([0-9A-Za-z_-]*\.*)*$") && echo "true" || echo "false")" false true
    done
	test "URL valid" "$RETURN2"
elif [[ $(echo $METADATA | jq -c '.url | type == "string"') == true ]]; then
    test "URL valid" "$(echo $METADATA | jq -c '.url | test("^([0-9A-Za-z_-]*\\.*)*$")')"
else 
    test "URL valid" false
fi

test "Version present" "$(echo $METADATA | jq -c 'if has("version") then .version else false end')"
test "Version valid" "$(echo $METADATA | jq -c '.version | test("^\\d+\\.\\d+\\.\\d+$")')"

test "Logo present" "$(echo $METADATA | jq -c 'if has("logo") then .logo else false end')"
test "Logo valid" "$(echo $METADATA | jq -c '.logo | test("\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))")')"

test "Thumbnail present" "$(echo $METADATA | jq -c 'if has("thumbnail") then .thumbnail else false end')"
test "Thumbnail valid" "$(echo $METADATA | jq -c '.thumbnail | test("\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))")')"

test "Color present" "$(echo $METADATA | jq -c 'if has("color") then .thumbnail else false end')"
test "Color valid" "$(echo $METADATA | jq -c '.color | test("^#[0-9a-fA-F]{3,6}$")')"

test "Tags present" "$(echo $METADATA | jq -c 'if has("tags") then true else false end')"
if [[ $(echo $METADATA | jq -c '.tags | type == "array"') == true ]]; then
    test "Tags valid" "ongoing"
    for item64 in $(echo $METADATA | jq --compact-output --raw-output '.tags[] | @base64'); do
        item=$(echo $item64 | base64 -d)
        test "Tag $item valid" "$((echo $item | grep -Pq "^[\p{Ll}\p{N}\p{Han}\p{Hangul}\p{Hiragana}\p{Katakana}\p{Han}-]+$") && echo "true" || echo "false")" false true
    done
	test "Tags valid" "$RETURN2"
else 
    test "Tags valid" false
fi

test "Category present" "$(echo $METADATA | jq -c 'if has("category") then .category else false end')"
test "Category valid" "$(echo $METADATA | jq -c '.category | test("(anime)|(games)|(music)|(socials)|(videos)|(other)")')"

((($LOG_LEVEL > 0)) && (! $TAP)) && echo -e "\n\e[97mTesting optional values...\n\e[0m"

test "Contributors present" "$(echo $METADATA | jq -c 'if has("contributors") then true else false end')" true
if [[ $RETURN1 == true ]]; then
    test "Contributors valid" "ongoing"
    for item64 in $(echo $METADATA | jq --compact-output --raw-output '.contributors[] | @base64'); do
        item=$(echo $item64 | base64 -d)
        test "Contributor name present" "$(echo $item | jq -c 'if has("name") then .name else false end')" false true
        test "Contributor name valid" "$(echo $item | jq -c '.name | type == "string"')" false true
        test "Contributor ID present" "$(echo $item | jq -c 'if has("id") then .id else false end')" false true
        test "Contributor ID valid" "$(echo $item | jq -c '.id | test("^\\d+$")')" false true
    done
    test "Contributors valid" $RETURN2
else
    test "Contributors valid" false true
fi
test "regExp present" "$(echo $METADATA | jq -c 'if has("regExp") then .regExp else false end')" true
if [[ $RETURN1 == true ]]; then
    test "regExp valid" "$(echo $METADATA | jq -c '.regExp | type == "string"')" true
else
    test "regExp valid" false true
fi

test "iFrameRegExp present" "$(echo $METADATA | jq -c 'if has("iFrameRegExp") then .iFrameRegExp else false end')" true
if [[ $RETURN1 == true ]]; then
    test "iFrameRegExp valid" "$(echo $METADATA | jq -c '.iFrameRegExp | type == "string"')" true
else
    test "iFrameRegExp valid" false true
fi

test "iframe present" "$(echo $METADATA | jq -c 'if has("iframe") then .iframe else false end')" true
if [[ $RETURN1 == true ]]; then
    test "iframe valid" "$(echo $METADATA | jq -c '.iframe | type == "boolean"')" true
else
    test "iframe valid" false true
fi

test "Settings present" "$(echo $METADATA | jq -c 'if has("settings") then true else false end')" true
if [[ $RETURN1 == true ]]; then
    test "Settings valid" "ongoing"
    for item64 in $(echo $METADATA | jq -cr '.settings[] | @base64'); do
        item=$(echo $item64 | base64 -d)
        test "Setting ID present" "$(echo $item | jq -c 'if has("id") then .id else false end')" false true
        if [[ $RETURN1 == true ]]; then
            test "Setting ID valid" "$(echo $item | jq -c '.id | type == "string"')" false true
        else
            test "Setting ID valid" false true true
        fi
        test "Setting title present" "$(echo $item | jq -c 'if has("title") then .title else false end')" false true
        if [[ $RETURN1 == true ]]; then
            test "Setting title valid" "$(echo $item | jq -c '.title | type == "string"')" false true
        else
            test "Setting title valid" false true true
        fi
        test "Setting icon present" "$(echo $item | jq -c 'if has("icon") then .icon else false end')" false true
        if [[ $RETURN1 == true ]]; then
            test "Setting icon valid" "$(echo $item | jq -c '.icon | test("^fa[bs] fa-[0-9A-Za-z-]+$")')" false true
        else
            test "Setting icon valid" false true true
        fi
        test "Setting value present" "$(echo $item | jq -c 'if has("value") then .value else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting value valid" "$(echo $item | jq -c '.value | type == "string" or type == "number" or type == "boolean"')" false true
        else
            test "Setting value valid" false true true
        fi
        test "Setting if present" "$(echo $item | jq -c 'if has("if") then .if else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting if valid" "$(echo $item | jq -c '.if | type == "object"')" false true
        else
            test "Setting if valid" false true true
        fi
        test "Setting placeholder present" "$(echo $item | jq -c 'if has("placeholder") then .placeholder else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting placeholder valid" "$(echo $item | jq -c '.placeholder | type == "string"')" false true
        else
            test "Setting placeholder valid" false true true
        fi
        test "Setting values present" "$(echo $item | jq -c 'if has("values") then .values else false end')" true true
        if [[ $RETURN1 == true ]]; then
            test "Setting values valid" "$(echo $item | jq -c '.values | type == "array"')" false true
        else
            test "Setting values valid" false true true
        fi
    done
    test "Settings valid" "$RETURN2"
else
    test "Settings valid" false true
fi

if $TAP; then
	LOG_LEVEL=-1
fi

(($LOG_LEVEL > -1)) && echo ""

# http://hackerpublicradio.org/eps/hpr1757_full_shownotes.html

pad () {
    local text=${1?Usage: pad text [length] [character] [L|R|C]}
    local length=${2:-80}
    local char=${3:-" "}
    local side=${4:-L}
    local line l2
    [ ${#text} -ge $length ] && { echo "$text"; return; }
    char=${char:0:1}
    side=${side^^}
    printf -v line "%*s" $(($length - ${#text})) ' '
    line=${line// /$char}
    if [[ $side == "R" ]]; then
        echo "${text}${line}"
    elif [[ $side == "L" ]]; then
        echo "${line}${text}"
    elif [[ $side == "C" ]]; then
        l2=$((${#line}/2))
        echo "${line:0:$l2}${text}${line:$l2}"
    fi
}  

(($LOG_LEVEL > 0)) && echo -e "\e[97mAll done! Result:"

(($LOG_LEVEL > -1)) && echo -e "\e[0;97m┌────────────┬────────────────────┬──────┐"
(($LOG_LEVEL > -1)) && echo -e "│ \e[1mTest Type\e[0;97m  │ \e[42;97m OK \e[0;97m   \e[41;97mFAIL\e[0;97m   \e[107;30mSKIP\e[0;97m │ \e[1mTtl. │"
(($LOG_LEVEL > -1)) && echo -e "├────────────┼────────────────────┼──────┤"
(($LOG_LEVEL > -1)) && echo -e "│ \e[1mMain\e[0;97m       │ $(pad $TEST_MAIN_OK 4)   $(pad $TEST_MAIN_FAIL 4)   $(pad $TEST_MAIN_SKIP 4) │ $(pad $(($TEST_MAIN_OK + $TEST_MAIN_FAIL + $TEST_MAIN_SKIP)) 4) │"
(($LOG_LEVEL > -1)) && echo -e "│ \e[1mSupplement\e[0;97m │ $(pad $TEST_SUPP_OK 4)   $(pad $TEST_SUPP_FAIL 4)   $(pad $TEST_SUPP_SKIP 4) │ $(pad $(($TEST_SUPP_OK + $TEST_SUPP_FAIL + $TEST_SUPP_SKIP)) 4) │"
(($LOG_LEVEL > -1)) && echo -e "├────────────┼────────────────────┼──────┤"
(($LOG_LEVEL > -1)) && echo -e "│ \e[1mTotal\e[0;97m      │ \e[42;97m$(pad $(($TEST_MAIN_OK + $TEST_SUPP_OK)) 4)\e[0;97m   \e[41;97m$(pad $(($TEST_MAIN_FAIL + $TEST_SUPP_FAIL)) 4)\e[0;97m   \e[107;30m$(pad $(($TEST_MAIN_SKIP + $TEST_SUPP_SKIP)) 4)\e[0;97m │ $(pad $(($TEST_MAIN_OK + $TEST_SUPP_OK + $TEST_MAIN_FAIL + $TEST_SUPP_FAIL + $TEST_MAIN_SKIP + $TEST_SUPP_SKIP)) 4) │"
(($LOG_LEVEL > -1)) && echo -e "└────────────┴────────────────────┴──────┘\e[0m"

(($LOG_LEVEL > -1)) && echo ""
if (($LOG_LEVEL > 0)); then
	if [[ $(($TEST_MAIN_FAIL + $TEST_SUPP_FAIL)) == 0 ]]; then 
		echo -e "\e[42;97mTest passed!\e[0;97m"
		echo -e ""
		echo -e "\e[1;97mThe presence's metadata has passed the test suite!\e[0;97m"
		echo -e "It is safe to use this presence and push it to the store."
		echo -e ""
		echo -e "Find more info related to the results on the link below."
		echo -e "\e[4m$REFERENCE\e[0m"
	else
		echo -e "\e[41;1mTest failed!\e[0;97m"
		echo -e ""
		echo -e "\e[1mErrors detected on the presence's metadata!\e[0;97m This may cause unwanted problems on usage."
		echo -e "Please fix the problems mentioned as soon as possible by referring to the results."
		echo -e ""
		echo -e "Find more info related to the results on the link below."
		echo -e "\e[4m$REFERENCE\e[0m"
	fi 
elif (($LOG_LEVEL == 0)); then
	if [[ $(($TEST_MAIN_FAIL + $TEST_SUPP_FAIL)) == 0 ]]; then 
		echo -e "\e[42;97mTest passed!\e[0m"
	else
		echo -e "\e[41;1mTest failed!\e[0m"
	fi
fi

# echo -e ""
# echo -e "Test concluded."
exit $(($TEST_MAIN_FAIL + $TEST_SUPP_FAIL))

# echo -e "┌────────────┬────────────────────┬──────┐"
# echo -e "│ Test Type  │  OK    FAIL   SKIP │ Ttl. │"
# echo -e "├────────────┼────────────────────┼──────┤"
# echo -e "│ Main       │ 0001   0002   0003 │ 0009 │"
# echo -e "│ Supplement │ 0004   0005   0006 │ 0010 │"
# echo -e "├────────────┼────────────────────┼──────┤"
# echo -e "│ Total      │ 0007   0008   0008 │ 0011 │"
# echo -e "└────────────┴────────────────────┴──────┘"
#
# 01: $(pad $TEST_MAIN_OK 4)
# 02: $(pad $TEST_MAIN_FAIL 4)
# 03: $(pad $TEST_MAIN_SKIP 4)
# 04: $(pad $TEST_SUPP_OK 4)
# 05: $(pad $TEST_SUPP_FAIL 4)
# 06: $(pad $TEST_SUPP_SKIP 4)
# 07: $(pad $(($TEST_MAIN_OK + $TEST_SUPP_OK)) 4)
# 08: $(pad $(($TEST_MAIN_FAIL + $TEST_SUPP_FAIL)) 4)
# 09: $(pad $(($TEST_MAIN_SKIP + $TEST_SUPP_SKIP)) 4)
# 10: $(pad $(($TEST_MAIN_OK + $TEST_MAIN_FAIL + $TEST_MAIN_SKIP)) 4)
# 11: $(pad $(($TEST_FAIL_OK + $TEST_FAIL_FAIL + $TEST_FAIL_SKIP)) 4)
# 12: $(pad $(($TEST_MAIN_OK + $TEST_SUPP_OK + $TEST_MAIN_FAIL + $TEST_SUPP_FAIL + $TEST_MAIN_SKIP + $TEST_SUPP_SKIP)) 4)
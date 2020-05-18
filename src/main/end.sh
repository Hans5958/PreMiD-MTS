# http://hackerpublicradio.org/eps/hpr1757_full_shownotes.html

pad() {
    local text=$1
    local length=${2:-80}
    local char=${3:-" "}
    local side=${4:-L}
    local line l2
    [[ ${#text} -ge length ]] && { echo "$text"; return; }
    char=${char:0:1}
    side=${side^^}
    printf -v line "%*s" $((length - ${#text})) ' '
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

[[ $LOG_LEVEL -gt 0 ]] && cecho "\e[97mResult:"

export TEST_MAIN_TOTAL=$((TEST_MAIN_OK + TEST_MAIN_FAIL + TEST_MAIN_SKIP))
export TEST_SUPP_TOTAL=$((TEST_SUPP_OK + TEST_SUPP_FAIL + TEST_SUPP_SKIP))
export TEST_TOTAL_OK=$((TEST_MAIN_OK + TEST_SUPP_OK))
export TEST_TOTAL_FAIL=$((TEST_MAIN_FAIL + TEST_SUPP_FAIL))
export TEST_TOTAL_SKIP=$((TEST_MAIN_SKIP + TEST_SUPP_SKIP))
export TEST_TOTAL_TOTAL=$((TEST_MAIN_TOTAL + TEST_SUPP_TOTAL))

cecho "\e[0;97m┌────────────┬────────────────────┬──────┐"
cecho "│ \e[1mTest Type\e[0;97m  │ \e[42;97m OK \e[0;97m   \e[41;97mFAIL\e[0;97m   \e[107;30mSKIP\e[0;97m │ \e[1mTtl. │"
cecho "├────────────┼────────────────────┼──────┤"
cecho "│ \e[1mMain\e[0;97m       │ $(pad "$TEST_MAIN_OK" 4)   $(pad "$TEST_MAIN_FAIL" 4)   $(pad "$TEST_MAIN_SKIP" 4) │ $(pad "$TEST_MAIN_TOTAL" 4) │"
cecho "│ \e[1mSupplement\e[0;97m │ $(pad "$TEST_SUPP_OK" 4)   $(pad "$TEST_SUPP_FAIL" 4)   $(pad "$TEST_SUPP_SKIP" 4) │ $(pad "$TEST_SUPP_TOTAL" 4) │"
cecho "├────────────┼────────────────────┼──────┤"
cecho "│ \e[1mTotal\e[0;97m      │ \e[42;97m$(pad "$TEST_TOTAL_OK" 4)\e[0;97m   \e[41;97m$(pad "$TEST_TOTAL_FAIL" 4)\e[0;97m   \e[107;30m$(pad "$TEST_TOTAL_SKIP" 4)\e[0;97m │ $(pad "$TEST_TOTAL_TOTAL" 4) │"
cecho "└────────────┴────────────────────┴──────┘\e[0m"

echo ""
if ((LOG_LEVEL > 0)); then
	if [[ $TEST_TOTAL_FAIL -eq 0 ]]; then 
		cecho "\e[42;97;1mTest passed!\e[0;97m"
		cecho ""
		cecho "\e[1;97mThe presence's metadata has passed the test suite!\e[0;97m"
		cecho "It is safe to use this presence and push it to the store."
		cecho ""
		cecho "\e[37mFind more info related to the results on the link below."
		cecho "\e[4m$REFERENCE\e[0m"
	else
		cecho "\e[41;1;1mTest failed!\e[0;97m"
		cecho ""
		cecho "\e[1mErrors detected on the presence's metadata!\e[0;97m This may cause unwanted problems on usage."
		cecho "Please fix the problems mentioned as soon as possible by referring to the results."
		cecho ""
		cecho "\e[37mFind more info related to the results on the link below."
		cecho "\e[4;37m$REFERENCE\e[0m"
	fi 
elif [[ $LOG_LEVEL -eq 0 ]]; then
	if [[ $TEST_TOTAL_FAIL -eq 0 ]]; then 
		cecho "\e[42;97mTest passed!\e[0m"
	else
		cecho "\e[41;1mTest failed!\e[0m"
	fi
fi

exit $TEST_TOTAL_FAIL
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

cecho "Result:"

export TEST_MAIN_TOTAL=$((TEST_MAIN_OK + TEST_MAIN_FAIL + TEST_MAIN_SKIP))
export TEST_SUPP_TOTAL=$((TEST_SUPP_OK + TEST_SUPP_FAIL + TEST_SUPP_SKIP))
export TEST_TOTAL_OK=$((TEST_MAIN_OK + TEST_SUPP_OK))
export TEST_TOTAL_FAIL=$((TEST_MAIN_FAIL + TEST_SUPP_FAIL))
export TEST_TOTAL_SKIP=$((TEST_MAIN_SKIP + TEST_SUPP_SKIP))
export TEST_TOTAL_TOTAL=$((TEST_MAIN_TOTAL + TEST_SUPP_TOTAL))

cecho "┌────────────┬────────────────────┬──────┐"
cecho "│ Test Type  │  OK    FAIL   SKIP │ Ttl. │"
cecho "├────────────┼────────────────────┼──────┤"
cecho "│ Main       │ $(pad "$TEST_MAIN_OK" 4)   $(pad "$TEST_MAIN_FAIL" 4)   $(pad "$TEST_MAIN_SKIP" 4) │ $(pad "$TEST_MAIN_TOTAL" 4) │"
cecho "│ Supplement │ $(pad "$TEST_SUPP_OK" 4)   $(pad "$TEST_SUPP_FAIL" 4)   $(pad "$TEST_SUPP_SKIP" 4) │ $(pad "$TEST_SUPP_TOTAL" 4) │"
cecho "├────────────┼────────────────────┼──────┤"
cecho "│ Total      │ $(pad "$TEST_TOTAL_OK" 4)   $(pad "$TEST_TOTAL_FAIL" 4)   $(pad "$TEST_TOTAL_SKIP" 4) │ $(pad "$TEST_TOTAL_TOTAL" 4) │"
cecho "└────────────┴────────────────────┴──────┘"

echo ""
if ((LOG_LEVEL > 0)); then
	if [[ $TEST_MAIN_FAIL -eq 0 ]]; then 
		cecho "Test passed!"
		cecho ""
		cecho "The presence's metadata has passed the test suite!"
		cecho "It is safe to use this presence and push it to the store."
		cecho ""
		cecho "Find more info related to the results on the link below."
		cecho "$REFERENCE"
	else
		cecho "Test failed!"
		cecho ""
		cecho "Errors detected on the presence's metadata! This may cause unwanted problems on usage."
		cecho "Please fix the problems mentioned as soon as possible by referring to the results."
		cecho ""
		cecho "Find more info related to the results on the link below."
		cecho "$REFERENCE"
	fi 
elif [[ $LOG_LEVEL -eq 0 ]]; then
	if [[ $TEST_MAIN_FAIL -eq 0 ]]; then 
		cecho "Test passed!"
	else
		cecho "Test failed!"
	fi
fi

CSV="$CSV,$TEST_MAIN_OK,$TEST_MAIN_FAIL,$TEST_MAIN_SKIP,$TEST_MAIN_TOTAL,$TEST_SUPP_OK,$TEST_SUPP_FAIL,$TEST_SUPP_SKIP,$TEST_SUPP_TOTAL,$TEST_TOTAL_OK,$TEST_TOTAL_FAIL,$TEST_TOTAL_SKIP,$TEST_TOTAL"
echo $CSV >> grand-result.csv

exit $TEST_TOTAL_FAIL

export passed=0
export failures=0

function assertEqual() {
    if [[ "$1" == "$2" ]]; then
        echo -e "\033[1m\033[32mok\033[0m - $1 == $2 ($3)"
        export passed=$((passed+1))
    else
        echo -e "\033[1m\033[31mnot ok\033[0m - $1 != $2 ($3)"
        export failures=$((failures+1))
    fi
}

function assertContains() {
    if [[ "$1" =~ "$2" ]]; then
        echo -e "\033[1m\033[32mok\033[0m - Found string $2 in output ($3)"
        export passed=$((passed+1))
    else
        echo -e "\033[1m\033[31mnot ok\033[0m - Did not find string '$2' in '$1' ($3)"
        export failures=$((failures+1))
    fi
}

function exit_tests() {
    if [[ ${failures} == 0 ]]; then
        echo -e "\033[1m\033[32m* Success: ${passed} tests succeeded\033[0m";
    else
        echo -e "\033[1m\033[31m* Error: ${failures} test(s) failed\033[0m";
    fi
    exit 1
}



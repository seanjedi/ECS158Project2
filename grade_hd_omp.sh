#!/bin/bash

set -o pipefail
#set -xv # debug

# Absolute path of this file
CWD=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

#
# Logging helpers
#
log() {
    echo -e "${*}"
}

info() {
    log "Info: ${*}"
}
warning() {
    log "Warning: ${*}"
}
error() {
    log "Error: ${*}"
}
die() {
    error "${*}"
    exit 1
}

#
# Scoring helpers
#
TOTAL=0
ANSWERS=()

add_answer() {
    log "Score: ${1}/1.0"
    ANSWERS+=("${1},")
}

inc_total() {
    let "TOTAL++"
}

# Returns a specific line in a multi-line string
select_line() {
    # 1: string
    # 2: line to select
    echo "$(echo "${1}" | sed "${2}q;d")"
}

fail() {
    # 1: got
    # 2: expected
    log "Fail: got '${1}' but expected '${2}'"
}

pass() {
    # got
    log "Pass: ${1}"
}

compare_output_lines() {
    # 1: output
    # 2: expected
    # 3: point step
    declare -a output_lines=("${!1}")
    declare -a expect_lines=("${!2}")
    local pts_step="${3}"

    for i in ${!output_lines[*]}; do
        if [[ ${output_lines[${i}]} =~ ${expect_lines[${i}]} ]]; then
            pass "${output_lines[${i}]}"
            sub=$(bc<<<"${sub}+${pts_step}")
        else
            fail "${output_lines[${i}]}" "${expect_lines[${i}]}" ]]
        fi
    done
}

#
# Generic function for running tests
#
EXEC="heat_distribution_omp"
run_test() {
    #1: cli arguments
    local args=("${@}")

    # These are global variables after the test has run so clear them out now
    unset STDOUT STDERR RET

    # Create temp files for getting stdout and stderr
    local outfile=$(mktemp)
    local errfile=$(mktemp)

    # Encapsulates commands with `timeout` in case the process hangs indefinitely
    timeout 10 bash -c "./${EXEC} ${args[*]}" \
        >${outfile} 2>${errfile}

    # Get the return status, stdout and stderr of the test case
    RET="${?}"
    STDOUT=$(cat "${outfile}")
    STDERR=$(cat "${errfile}")

    # Deal with the possible timeout errors
    [[ ${RET} -eq 127 ]] && die "Something is wrong (the executable might not exist)"
    [[ ${RET} -eq 124 ]] && warning "Command timed out..."

    # Clean up temp files
    rm -f "${outfile}"
    rm -f "${errfile}"
}

#
# Test cases
#
TEST_CASES=()

## Error management usage (no args)
TEST_CASES+=("err_no_arg")
err_no_arg() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Usage: ./heat_distribution_omp N fire_temp wall_temp epsilon")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Error management usage (one arg)
TEST_CASES+=("err_one_arg")
err_one_arg() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "500"

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Usage: ./heat_distribution_omp N fire_temp wall_temp epsilon")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Error management usage (three arg)
TEST_CASES+=("err_three_arg")
err_three_arg() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "500" "100" "0"

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Usage: ./heat_distribution_omp N fire_temp wall_temp epsilon")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}


## Error management usage (error code)
TEST_CASES+=("err_usage_err")
err_usage_err() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test "toto"

    local line_array=()
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Error management wrong map order ("-1")
TEST_CASES+=("err_map_order_1")
err_map_order_1() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test -1 100 0 0.01

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Error: wrong map order \(3 <= N <= 2000\)")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}


## Error management wrong fire temperature
TEST_CASES+=("err_fire_temp")
err_fire_temp() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 500 102 0 0.01

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Error: wrong fire temperature \(0.000000 <= N <= 100.000000\)")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Error management wrong wall temperature
TEST_CASES+=("err_wall_temp")
err_wall_temp() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 500 100 -0.2 0.01

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Error: wrong wall temperature \(0.000000 <= N <= 100.000000\)")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Error management wrong epsilon
TEST_CASES+=("err_epsilon")
err_epsilon() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 500 100 0 0

    local line_array=()
    line_array+=("$(select_line "${STDERR}" "1")")
    local corr_array=()
    corr_array+=("Error: wrong epsilon \(0.000001 <= N <= 100.000000\)")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}

## Error management wrong arg (error code)
TEST_CASES+=("err_order_err")
err_order_err() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 500 100 0 0

    local line_array=()
    line_array+=("Return code: '${RET}'")
    local corr_array=()
    corr_array+=("Return code: '1'")
    compare_output_lines line_array[@] corr_array[@] "1"
    add_answer "${sub}"
}


## 100 100 0 0.1
TEST_CASES+=("run_100_100_0_01")
run_100_100_0_01() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 100 100 0 0.1

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "3")")
    line_array+=("$(select_line "${STDOUT}" "12")")
    line_array+=("$(select_line "${STDOUT}" "14")")
    local corr_array=()
    corr_array+=("Running time: [0-9]+.[0-9]+ secs")
    corr_array+=("mean: 25.252525")
    corr_array+=("hmap: 3679461888")
    corr_array+=("181[[:space:]]*0.099724")
    corr_array+=("hmap: 3505202343")
    compare_output_lines line_array[@] corr_array[@] "0.2"
    add_answer "${sub}"
}

## 500 100 20 0.01
TEST_CASES+=("run_500_100_20_001")
run_500_100_20_001() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 500 100 20 0.01

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "3")")
    line_array+=("$(select_line "${STDOUT}" "15")")
    line_array+=("$(select_line "${STDOUT}" "17")")
    local corr_array=()
    corr_array+=("Running time: [0-9]+.[0-9]+ secs")
    corr_array+=("mean: 40.040080")
    corr_array+=("hmap: 3102498919")
    corr_array+=("1451[[:space:]]*0.010000")
    corr_array+=("hmap: 3364114085")
    compare_output_lines line_array[@] corr_array[@] "0.2"
    add_answer "${sub}"
}

## 1000 75 30 0.01
TEST_CASES+=("run_1000_75_30_001")
run_1000_75_30_001() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 1000 75 30 0.01

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "3")")
    line_array+=("$(select_line "${STDOUT}" "14")")
    line_array+=("$(select_line "${STDOUT}" "16")")
    local corr_array=()
    corr_array+=("Running time: [0-9]+.[0-9]+ secs")
    corr_array+=("mean: 41.261261")
    corr_array+=("hmap: 2690851001")
    corr_array+=("817[[:space:]]*0.009992")
    corr_array+=("hmap: 402802439")
    compare_output_lines line_array[@] corr_array[@] "0.2"
    add_answer "${sub}"
}

## 2000 82 16 0.0015
TEST_CASES+=("run_2000_82_16_0015")
run_2000_82_16_0015() {
    log "\n--- Running ${FUNCNAME} ---"
    inc_total
    sub=0

    run_test 2000 82 16 0.015

    local line_array=()
    line_array+=("$(select_line "${STDOUT}" "1")")
    line_array+=("$(select_line "${STDOUT}" "2")")
    line_array+=("$(select_line "${STDOUT}" "3")")
    line_array+=("$(select_line "${STDOUT}" "14")")
    line_array+=("$(select_line "${STDOUT}" "16")")
    local corr_array=()
    corr_array+=("Running time: [0-9]+.[0-9]+ secs")
    corr_array+=("mean: 32.508254")
    corr_array+=("hmap: 1809643248")
    corr_array+=("799[[:space:]]*0.014990")
    corr_array+=("hmap: 1875116920")
    compare_output_lines line_array[@] corr_array[@] "0.2"
    add_answer "${sub}"
}


#
# Main functions
#
TDIR=test_dir

clean_tdir() {
    cd ..
    rm -rf "${TDIR}"
}

make_exec() {
    # Make sure there no executable
    rm -f "${EXEC}"

    # Compile
    make > /dev/null 2>&1 ||
        die "Compilation failed"

    # Make sure that the shell executable was created
    if [[ ! -x "${EXEC}" ]]; then
        clean_tdir
        die "Can't find shell executable after compilation"
    fi
}

prep_tdir() {
    # Make a new testing directory
    rm -rf "${TDIR}"
    mkdir "${TDIR}" && cd "${TDIR}"

    cp "../${EXEC}" .
}

main_func() {
    # Run all the tests
    for t in "${TEST_CASES[@]}"; do
        ${t}
    done

    # Remove last comma from last answer entry
    ANSWERS[-1]=${ANSWERS[-1]%?}

    # Log the results
    log "\n\n--- Final results ---"
    log "${TOTAL} test cases were passed"
    log "${ANSWERS[*]}"
}

cd "${CWD}"
make_exec
prep_tdir
main_func
clean_tdir

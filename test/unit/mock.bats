#!/usr/bin/env bats

# https://opensource.com/article/19/2/testing-bash-bats

load '../libs/bats-support/load'
load '../libs/bats-assert/load'


@test "mock - mock stub ls" {
    source ./src/mock.bash

    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        set -e
        mock stub ls
        helper_print_out_mocks
        mock unstub ls
    }
    export -f helper_mock_stub

    run helper_mock_stub

    [ ${status} -eq 0 ]
    local expected
    local _result_output="$( mktemp /tmp/mock.XXXXXXXX )"
    local _expected_output="$( mktemp /tmp/mock.XXXXXXXX )"
    cat > "${_result_output}" <<EOF
${output}
EOF
    cat > "${_expected_output}" <<EOF
MOCKS[ls,visits]="0"
MOCKS[ls,errorlen]="0"
MOCKS[ls,len]="0"
EOF

    cmp "${_result_output}" "${_expected_output}"
    local result=$?
    rm -f "${__result_output}" "${_expected_output}"
    [ ${result} -ne 0 ] || return 0
    
    return $status
    [ "${status}" -eq 0 ]
}

@test "mock - mock stub ls; mock_ls 0 -la" {
    source ./src/mock.bash

    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        set -e
        mock stub ls
        mock_ls 0 ls -la
        helper_print_out_mocks
        mock unstub ls
    }
    export -f helper_mock_stub

    run helper_mock_stub

    [ ${status} -eq 0 ]
    local expected
    local _result_output="$( mktemp /tmp/mock.XXXXXXXX )"
    local _expected_output="$( mktemp /tmp/mock.XXXXXXXX )"
    cat > "${_result_output}" <<EOF
${output}
EOF
    cat > "${_expected_output}" <<EOF
MOCKS[ls,visits]="0"
MOCKS[ls,errorlen]="0"
MOCKS[ls,len]="1"
MOCKS[ls,status,1]="0"
MOCKS[ls,output,1]="/dev/null"
MOCKS[ls,args,1]="ls -la"
EOF

    cmp "${_result_output}" "${_expected_output}"
    local result=$?
    rm -f "${__result_output}" "${_expected_output}"
    [ ${result} -ne 0 ] || return 0
    
    return $status
    [ "${status}" -eq 0 ]
}

@test "mock - mock stub ls; mock_ls 0 -la; ls -la" {
    source ./src/mock.bash

    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        mock stub ls
        mock_ls 0 -1 "${MOCKS_FILENAME}"
        ls -1 "${MOCKS_FILENAME}"
        helper_print_out_mocks
        mock unstub ls
    }
    export -f helper_mock_stub

    run helper_mock_stub

    [ ${status} -eq 0 ]
    local expected
    local _result_output="$( mktemp /tmp/mock.XXXXXXXX )"
    local _expected_output="$( mktemp /tmp/mock.XXXXXXXX )"
    cat > "${_result_output}" <<EOF
${output}
EOF
    cat > "${_expected_output}" <<EOF
MOCKS[ls,visits]="1"
MOCKS[ls,errorlen]="0"
MOCKS[ls,len]="1"
MOCKS[ls,status,1]="0"
MOCKS[ls,output,1]="/dev/null"
MOCKS[ls,args,1]="-1 ${MOCKS_FILENAME}"
EOF

    cmp "${_result_output}" "${_expected_output}"
    local result=$?
    rm -f "${__result_output}" "${_expected_output}"
    [ ${result} -ne 0 ] || return 0
    
    return $status
    [ "${status}" -eq 0 ]
}

@test "mock - mock stub ls; mock_ls 0 -la; ls -l # error" {
    source ./src/mock.bash

    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        set -e
        mock stub ls
        mock_ls 0 -la
        ls -l
        helper_print_out_mocks
        mock unstub ls
    }
    export -f helper_mock_stub

    run helper_mock_stub

    [ ${status} -ne 0 ]
    local expected
    local _result_output="$( mktemp /tmp/mock.XXXXXXXX )"
    local _expected_output="$( mktemp /tmp/mock.XXXXXXXX )"
    cat > "${_result_output}" <<EOF
${output}
EOF
    cat > "${_expected_output}" <<< ""

    cmp "${_result_output}" "${_expected_output}"
    local result=$?
    rm -f "${__result_output}" "${_expected_output}"
    [ ${result} -ne 0 ] || return 0
    
    return $status
    [ "${status}" -eq 0 ]
}

@test "mock - mock stub ls; mock_ls 0 -la; ls -la; assert_mock ls" {
    source ./src/mock.bash

    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        mock stub ls
        mock_ls 0 -la
        ls -la
        helper_print_out_mocks
        assert_mock ls
        local _reto=$?
        mock unstub ls
        return $_reto
    }
    export -f helper_mock_stub

    run helper_mock_stub

    assert_success
    assert_output <<EOF
MOCKS[ls,visits]="1"
MOCKS[ls,errorlen]="0"
MOCKS[ls,len]="1"
MOCKS[ls,status,1]="0"
MOCKS[ls,output,1]="/dev/null"
MOCKS[ls,args,1]="-la"
EOF
}


@test "mock - mock stub ls; mock_ls 0 -la; ls -l; assert_mock ls" {
    source ./src/mock.bash

    # FIXME Clean-up helper_print_out_mocks
    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        local _ret
        mock stub ls
        mock_ls 0 -la
        ls -l
        assert_mock ls
        _ret=$?
        mock unstub ls
        return $_ret
    }
    export -f helper_mock_stub

    run helper_mock_stub
    assert_failure
    assert_output <<EOF
-- assert_mock --
   function: ls
   MOCKS_FILENAME: ${MOCKS_FILENAME}
   error: [1/1] Arguments does not match; expected=-la; received=-l
Some mock function in 'ls' failed
EOF
}


@test "mock - mock stub ls; mock_ls 0 -la; ls -la; assert_mock # error" {
    source ./src/mock.bash

    # FIXME Clean-up helper_print_out_mocks
    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        mock stub ls
        mock_ls 0 -la
        ls -la
        assert_mock
        local _reto=$?
        mock unstub ls
        return $_reto
    }
    export -f helper_mock_stub

    run helper_mock_stub
    assert_failure
    assert_output <<EOF
assert_mock requires at least one function name to check
EOF
}

@test "mock - mock stub ls; mock_ls 0 -la; ls -la; ls -la; assert_mock # error" {
    source ./src/mock.bash

    # FIXME Clean-up helper_print_out_mocks
    function helper_print_out_mocks
    {
        declare -A MOCKS
        source "${MOCKS_FILENAME}"

        for key in "${!MOCKS[@]}"; do
            echo "MOCKS[${key}]=\"${MOCKS[${key}]}\""
        done
    }
    export -f helper_print_out_mocks

    function helper_mock_stub 
    {
        mock stub ls
        mock_ls 0 -la
        ls -la
        ls -la
        assert_mock ls
        local _reto=$?
        mock unstub ls
        return $_reto
    }
    export -f helper_mock_stub

    run helper_mock_stub
    assert_failure
    assert_output <<EOF
-- assert_mock --
   visits: 2
   len: 1
   error: mocks was not visited the expected times
-- assert_mock --
   function: ls
   MOCKS_FILENAME: ${MOCKS_FILENAME}
   error: [1] Visited more than expected; visits=2; expected=1; current args=-la
Some mock function in 'ls' failed
EOF
}


@test "mock - mock_<func> output" {
    source ./src/mock.bash

    function helper_mock_stub
    {
        mock stub ls
        mock_ls 0 -1 "${MOCKS_FILENAME}"
        mock_ls output <<EOF
${MOCKS_FILENAME}
EOF
        ls -1 "${MOCKS_FILENAME}"
        assert_mock ls
        local _reto=$?
        mock unstub ls
        return $_reto
    }
    export -f helper_mock_stub

    run helper_mock_stub
    assert_success
    assert_output <<EOF
${MOCKS_FILENAME}
EOF
}

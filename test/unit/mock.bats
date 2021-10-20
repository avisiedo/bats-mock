#!/usr/bin/env bats

# https://opensource.com/article/19/2/testing-bash-bats

# load '../libs/bats-support/load'
# load '../libs/bats-assert/load'


@test "mock stub" {
    source ./src/mock.bash

    function helper_mock_stub 
    {
        mock stub ls
        mock::load_array
        # Check that it exists mock_ls function
        type -t mock_ls | grep -q ^function$ || return 1
        # Check that it exists
        [ -n ${MOCKS[ls,len]:+x} ] || return 2
        [ -n ${MOCKS[ls,visits]:+x} ] || return 3
        [ -n ${MOCKS[ls,errorlen]:+x} ] || return 4

        return 0
    }
    export -f helper_mock_stub

    run helper_mock_stub
    return $status
    [ "${status}" -eq 0 ]
}


@test "mock::load_array" {
    function helper_load_array
    {
        declare -A MOCKS
        echo 'MOCKS[ls,len]="1"' > "${MOCKS_FILENAME}"
        mock::load_array
        [ -n ${MOCKS[ls,len]:+x} ] || return 1
        return 0
    }
    export -f helper_load_array
    run helper_load_array
    return ${status}
    [ "${status}" -eq 0 ]
}



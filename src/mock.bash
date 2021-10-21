
# https://stackoverflow.com/questions/12944674/how-to-export-an-associative-array-hash-in-bash
declare -A MOCKS

MOCKS_FILENAME="$( mktemp /tmp/mock.XXXXXXXX )"
export MOCKS_FILENAME

function mock
{
    function mock::print_out_array
    {
        for item in "${!MOCKS[@]}"
        do
            if [[ "${item}" =~ .+,args,.+ ]]; then
                printf "eval \"%s=%q\"\n" "MOCKS[${item}]" "${MOCKS[${item}]}"
                continue
            fi
            printf "%s=\"%s\"\n" "MOCKS[\"${item}\"]" "${MOCKS[${item}]}"
        done
    }
    export -fn mock::print_out_array

    function mock::load_array
    {
        [ -e "${MOCKS_FILENAME}" ] || touch "${MOCKS_FILENAME}"
        source "${MOCKS_FILENAME}"
    }
    export -fn mock::load_array

    function mock::save_array
    {
        if [ ${#MOCKS[@]} -eq 0 ]; then
            /bin/rm -f "${MOCKS_FILENAME}"
        else
            printf "\n" > "${MOCKS_FILENAME}"
            mock::print_out_array >> "${MOCKS_FILENAME}"
        fi
    }
    export -fn mock::save_array

    function mock::stub_one_function
    {
        local __funcname="$1"
        shift 1
        local __mock_funcname="mock_${__funcname}"

        case "$__funcname" in
            "mock" \
            | "mock::stub_one_function" \
            | "mock::stub" \
            | "mock::unstub" )
                printf "ERROR:You can not use the '%s' reserved function name for mocking it\n" "${__funcname}" >&2
                return 1
                ;;
            "echo" | "sed" )
                printf "ERROR:You can not use the '%s' has it evokes situations with the test framework; wrap the code in a new function and mock that new function\n" "${__funcname}" >&2
                return 1
                ;;
            * )
                ;;
        esac

        declare -A MOCKS
        mock::load_array
        MOCKS["${__funcname},len"]=0
        MOCKS["${__funcname},visits"]=0
        MOCKS["${__funcname},errorlen"]=0

        # shellcheck disable=SC1091
        source /dev/stdin <<EOF
        function ${__mock_funcname}
        {
            declare -A MOCKS
            mock::load_array
            local __output="/dev/null"
            local _len=\${MOCKS["${__funcname},len"]}
            if [ "\$1" == "output" ]; then
                __output="\$( mktemp "/tmp/mock.output.XXXXXXXX" )"
                if [ "\$#" -gt 1 ]; then
                    fail "No more params than 'output' is allowed when it is used\n"
                    return \$?
                fi
                /bin/true > "\${__output}"
                while read -r line; do
                    printf "\${line}\n" >> "\${__output}"
                done 
                eval "MOCKS[\"${__funcname},output,\${_len}\"]=\"\${__output}\""
                mock::save_array
                return 0
            fi
            local __status=\$1
            shift 1
            local __args=("\$@")

            local _visits=\${MOCKS["${__funcname},visits"]}
            local _errorlen=\${MOCKS["${__funcname},errorlen"]}

            _len=\$(( _len + 1 ))


            MOCKS["${__funcname},len"]=\${_len}
            MOCKS["${__funcname},status,\${_len}"]=\${__status}
            MOCKS["${__funcname},args,\${_len}"]="\${__args[*]}"
            MOCKS["${__funcname},output,\${_len}"]="\${__output}"
            mock::save_array
        }
EOF
        export -fn "${__mock_funcname?}"

        # shellcheck disable=SC1091
        source /dev/stdin <<EOF
        function ${__funcname}
        {
            declare -A MOCKS
            mock::load_array
            local _len=\${MOCKS["${__funcname},len"]}
            local _visits=\${MOCKS["${__funcname},visits"]}
            local _errorlen=\${MOCKS["${__funcname},errorlen"]}

            local _current

            _current=\$(( _visits + 1 ))
            eval "MOCKS[\"${__funcname},visits\"]=\${_current}"

            if [ "\${_visits}" -ge \${_len} ]; then
                _errorlen=\$(( _errorlen + 1 ))
                eval "MOCKS[\"${__funcname},errorlen\"]=\${_errorlen}"
                eval "MOCKS[\"${__funcname},error,\${_errorlen}\"]=\"[\${_errorlen}] Visited more than expected; visit=\${_current}; expected=\${_len}; current args=\${*}\""
                mock::save_array
                return 127
            fi

            local _status
            local _args
            local _output

            _status=\${MOCKS[${__funcname},status,\${_current}]}
            _args="\${MOCKS[${__funcname},args,\${_current}]}"
            _output=\${MOCKS[${__funcname},output,\${_current}]}


            if [ "\$*" != "\${_args}" ]; then
                _errorlen=$(( _errorlen + 1 ))
                eval "MOCKS[\"${__funcname},errorlen\"]=\"\${_errorlen}\""
                eval "MOCKS[\"${__funcname},error,\${_errorlen}\"]=\"[\${_current}/\${_len}] Arguments does not match; expected=\${_args}; received=\$*\""
                mock::save_array
                return 127
            fi

            /bin/cat "\${_output}" >&1

            mock::save_array
            return \${_status}
        }
EOF
        export -fn "${__funcname?}"
        mock::save_array
    }

    function mock::stub
    {
        for mock_function in "$@"; do
            mock::stub_one_function "${mock_function}"
        done
    }

    function mock::unstub
    {
        declare -A MOCKS
        mock::load_array
        for mock_function in "$@"; do
            # Set functions for being not exported
            export -fn "mock_${mock_function?}"
            export -fn "${mock_function?}"

            # Remove information from the associative array
            for key in "${!MOCKS[@]}"; do
                if [ "${key#${mock_function},}" != "${key}" ]; then
                    if [[ "${key}" =~ .*,output ]] && [ "${MOCKS[${key}]}" != "/dev/null" ]; then
                        local output_path="${MOCKS[${key}]}"
                        rm -f "${output_path}"
                    fi
                    unset MOCKS["${key}"]
                    continue
                fi
            done
        done
        mock::save_array
    }

    function mock::output
    {
        local _funcname="$1"
        shift 1
        declare -A MOCKS
        mock::load_array
        local _len=${MOCKS["${_funcname},len"]}
        /bin/cat < /dev/stdin > "${MOCKS_FILENAME}.${_len}.output"
        MOCKS[${_funcname},output,${_len}]="${MOCKS_FILENAME}.${_len}.output"
        mock::save_array
    }

    local subcmd="$1"
    shift 1
    case "${subcmd}" in
        "stub" )
            mock::stub "$@"
            return $?
            ;;
        "unstub" )
            mock::unstub "$@"
            return $?
            ;;
        "output" )
            mock::output "$@"
            return $?
            ;;
        * )
            return 1
            ;;
    esac
}

function assert_mock
{
    function assert_mock::one_function
    {
        local _funcname="$1"

        declare -A MOCKS
        mock::load_array
        local _len=${MOCKS["${_funcname},len"]}
        local _visits=${MOCKS["${_funcname},visits"]}
        local _errorlen=${MOCKS["${_funcname},errorlen"]}
        local _errormsg

        [ ${_errorlen} -ne 0 ] || return 0
        for idx in $( seq 1 ${_errorlen} ); do
            _errormsg="${MOCKS[${_funcname},error,${idx}]}"
            fail <<EOF
-- assert_mock --
   function: ${_funcname}
   MOCKS_FILENAME: ${MOCKS_FILENAME}
   error: ${_errormsg}
EOF
            return $?
        done
    }
    export -fn assert_mock::one_function

    if [ "$#" -eq 0 ]; then
        fail "assert_mock requires at least one function name to check"
        return $?
    fi

    local _failed=0
    for item in "$@"; do
        assert_mock::one_function "$item" || _failed=1
    done
    if [ ${_failed} -ne 0 ]; then
        fail "Some mock function in '$*' failed"
        return $?
    fi
    return 0
}
export -f assert_mock


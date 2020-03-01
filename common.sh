#!/usr/bin/env bash

#当使用了未初始化的变量时，设置set -u 或 set -o nounset，可以让程序强制退出
set -u
# set -o errexit 或set -e 一旦有任何一个语句返回非0值，则退出bash 
set -e
#将每行执行的命令输出，set -o xtrace或set -x
set -x


readonly WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly THIS_FILE="${WORKSPACE_DIR}/$(basename "${BASH_SOURCE[0]}")"

# 使用了shift，使得所有命令行参数都可以通过$1读取
# 让脚本可以单独运行任意一个函数
# sh common.sh --eval start 
function main_eval_param()
{
    local eval_param=""
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --eval | -e)
                # eval使用其后的所有参数作为eval目标的参数
                eval_param="${@:2}"
                break
                ;;
            --file | -f)
                UPLOAD_FILE_NAME="$2" && shift
                ;;
            --module | -m)
                MODULE_NAME="$2" && shift
                ;;
            * | --help | -h)
                # _help()
                exit 1
                ;;    
        esac
        shift
    done
    if [[ "${eval_param}" != "" ]]; then
        eval "${eval_param}"
        exit $?
    fi
    return 0
}

function switchgo() {
	local version=$1
	if [ -z $version ]; then
		echo "Usage: switchgo [version]"
		return
	fi

	if ! command -v "go$version" > /dev/null 2>&1; then
		echo "Go ${version} doesn't exist, start downloading..."
		go get golang.org/dl/go${version}
		go${version} download
	fi

	ln -sf "$(command -v "go$version")" "$GOBIN/go"

	echo "Switched to Go ${version}"
}

function star()
{
    echo "start"
}

function check_job() 
{
    local ret=$?
    local msg="$1" && shift
    if [[ $ret -ne 0 ]]; then
        error "[${ret}]:${msg}"
        exit 1
    fi
}

#trap func EXIT允许在脚本结束时调用函数，用它注册清理函数。
trap hanlder_exit_code EXIT
function hanlder_exit_code()
{
    echo "hanlder exit code"
}

function main()
{
    main_eval_param "$@"
    echo ${UPLOAD_FILE_NAME}
    echo ${MODULE_NAME}
}

# sh common.sh --file a.txt --module module_a 
main "$@"
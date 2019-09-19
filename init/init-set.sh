#!/usr/bin/env bash

SCRIPT_HOME=$(dirname $0)
INIT_HOME=$(cd $SCRIPT_HOME; pwd)

# 输出函数
function log()
{
        local _level=$1
        shift
        local _msg=$*
        local _ts=$(date +"%F %T")
        case $_level in
                info) echo -e "$_ts [INFO] $_msg";;
                notice) echo -e "$_ts [NOTE] \033[92m$_msg\033[0m";;
                warn) echo -e "$_ts [WARN] \033[93m$_msg\033[0m";;
                error) echo -e "$_ts [ERROR] \033[91m$_msg\033[0m";;
        esac
}

# 输出函数执行结果
function func_result()
{
	if [ $1 -eq 0 ]; then log info "成功"; else log error "失败"; fi
}

function main() {
    sh $INIT_HOME/src/base/install.sh
      func_result $?
}

main $* | tee $0.log 2>&1

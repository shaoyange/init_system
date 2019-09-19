#!/usr/bin/env bash

SCRIPT_HOME=$(dirname $0)
INIT_HOME=$(cd $SCRIPT_HOME; pwd)

yum install deltarpm -y

# 日志函数
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

function init_selinux()
{
    log notice '修改selinux...'
    setenforce 0
    SELinux_conf=/etc/selinux/config
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" $SELinux_conf
    func_result $?
}

function add_tool() {
    #if [ ! -f /bin/mssh ];then
    #    log notice "添加mssh mscp ssh批量执行工具"
    #    cp -v $INIT_HOME/src/tool/mssh  /bin/
    #    cp -v $INIT_HOME/src/tool/mscp /bin/
    #    chmod +x /bin/mssh
    #    chmod +x /bin/mscp
    #fi
    if [ ! -f /etc/profile.d/myenv.sh ]; then
        cp -v $INIT_HOME/myenv.sh /etc/profile.d/
        cp -v $INIT_HOME/mybash.sh /etc/profile.d/
    fi
}

function ins_iptables()
{
    log notice "禁用firewall，并启用iptables..."
    systemctl stop firewalld
    systemctl disable firewalld
    yum install -y iptables-services iptables-devel
    iptables -P INPUT  ACCEPT
    systemctl enable iptables
    systemctl start iptables
    iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 12080 -j ACCEPT
    service iptables save
    func_result $?
}

function init_ssh() {
    sed -i 's/^#Port 22/Port 12080/g' /etc/ssh/sshd_config
    sed -i 's/^#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
    sed -i 's/^GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g'  /etc/ssh/sshd_config # 启用公钥登录
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config # 关闭密码验证登录，记得先添加了key，再执行
    systemctl restart sshd
}

function add_user() {
    id www  >> /dev/null
    if [ ! $? -eq 0 ];then
        log notice "创建用户和日志目录"
        mkdir -v /data
        groupadd app
        useradd www -g app -d /data/www
        useradd db -g app -d /data/db
        useradd dc -g app -d /data/dc
        mkdir -pv /data/logs/{www,db,dc}
    	mkdir -pv /data/{db,dc,www}/.ssh
    	mkdir -pv /root/.ssh
	    chmod 700 /data/{db,dc,www}/.ssh /root/.ssh
        chown -vR www:app /data/www /data/logs/www
        chown -vR db:app /data/db /data/logs/db
        chown -vR dc:app /data/dc /data/logs/dc
        chmod 755 /data/{www,db,dc}
	    cp -v $INSTALL_HOME/authorized_keys.root /root/.ssh/authorized_keys
	    chmod 600 /root/.ssh/authorized_keys
    else
        log notice "www db dc user maybe has create."
    fi
}


function format_disk() {
    if [ ! -d /data ];then
        log warn "格式化数据盘。注意只需运行一次！！默认不执行。若需要执行，请先确认环境。"
        mkdir /data
        mkfs.xfs /dev/vdb
        echo "/dev/vdb     /data        xfs     defaults       0 0"   >> /etc/fstab
        mount -a
    fi
}

function init() {
    # format_disk
    add_tool
    add_user
    ins_iptables
    init_selinux
    init_ssh
}

init

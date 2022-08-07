#!/bin/bash
[[ $(id -u) != 0 ]] && echo -e "请使用root权限运行安装脚本" && exit 1

cmd="apt-get"
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
    if [[ $(command -v yum) ]]; then
        cmd="yum"
    fi
else
    echo "此脚本不支持该系统" && exit 1
fi

install() {
    if [ -f "/usr/bin/minerproxy" ]; then
        echo -e "您已安装了该软件，如果确定没有安装，请使用此脚本的卸载功能后重新安装" && exit 1
    fi
    if pgrep minerproxy; then
        echo -e "检测到您已启动了 /usr/bin/minerproxy，请关闭后再安装！" && exit 1
    fi

    $cmd update -y
    $cmd install curl wget -y
    mkdir /etc/minerproxy


    wget https://github.com/OyeMiner/MinerProxy/releases/download/v1.0.4/minerproxy_v1.0.4 -O /usr/bin/minerproxy
    
    wget https://github.com/OyeMiner/MinerProxy/raw/main/minerproxy.service -O /etc/systemd/system/minerproxy.service
    chmod +x /usr/bin/minerproxy

    echo "正在启动..."
    systemctl disable --now firewalld
    systemctl daemon-reload
    systemctl enable --now minerproxy
    sleep 2s
    journalctl --unit=minerproxy --no-tail  --no-full --no-pager --no-hostname --lines=10
    echo "安装结束!"
    echo "后台管理地址(请以实际外网IP为准): http://$(curl --silent ifconfig.me):19888"
    echo
    cat /etc/minerproxy/config.yml
}

uninstall() {
    read -p "是否确认删除 minerproxy [yes/no]：" flag
    if [ -z $flag ]; then
        echo "输入错误" && exit 1
    else
        if [ "$flag" = "yes" -o "$flag" = "ye" -o "$flag" = "y" ]; then
            systemctl disable --now minerproxy
            rm -rf /etc/systemd/system/minerproxy.service
            rm -rf /usr/bin/minerproxy
            rm -rf /etc/minerproxy
            systemctl daemon-reload
            echo "卸载 minerproxy 成功"
        fi
    fi
}

start() {
    systemctl enable --now minerproxy
    sleep 2s
    journalctl --unit=minerproxy --no-tail  --no-full --no-pager --no-hostname --lines=10

    echo "minerproxy 已启动"
}

restart() {
    systemctl restart minerproxy
    sleep 2s
    journalctl --unit=minerproxy --no-tail  --no-full --no-pager --no-hostname --lines=10

    echo "minerproxy 重新启动成功"
}

stop() {
    systemctl stop minerproxy
    echo "minerproxy 已停止"
}

show_log(){
    echo -n "最近的 100 行日志: "
    journalctl --unit=minerproxy --no-tail  --no-full --no-pager --no-hostname --lines=100
}

check_limit(){
    echo -n "当前连接数限制：102400"
}

uninstall_tx_mon() {
    /usr/local/qcloud/YunJing/uninst.sh
    /usr/local/qcloud/stargate/admin/uninstall.sh
    /usr/local/qcloud/monitor/barad/admin/uninstall.sh
    systemctl stop tat_agent
    systemctl disable tat_agent
    rm -rf /etc/systemd/system/tat_agent.service
    rm -rf /etc/systemd/system/cloud-init.target.wants
    rm -rf /usr/local/qcloud/
    rm -rf /usr/local/yd.socket.server
    echo -n "腾讯云监控卸载成功！"
}

echo "============================ miner Proxy  ========================="
echo "  1、安装(安装到 程序:/usr/bin/minerproxy 配置文件:/etc/minerproxy)"
echo "  2、卸载(更新请先卸载，请注意: 配置文件不兼容 需要重新配置)"
echo "  3、启动"
echo "  4、重启"
echo "  5、停止"
echo "  6、查看最近的 100 行日志"
echo "  7、查看软件连接数限制"
echo "  8、卸载腾讯云监控"
echo "======================================================================"
read -p "$(echo -e "请选择[1-8]：")" choose
case $choose in
1)
    install
    ;;
2)
    uninstall
    ;;
3)
    start
    ;;
4)
    restart
    ;;
5)
    stop
    ;;
6)
    show_log
    ;;
7)
    check_limit
    ;;
8)
    uninstall_tx_mon
    ;;
*)
    echo "输入错误，请重新输入！"
    ;;
esac

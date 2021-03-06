#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================
#       System Required: CentOS/Debian/Ubuntu
#       Description: PipeSocks
#       Version: 1.0.1
#       Author: Toyo
#       Blog: https://doub.io/pipesocks-jc1/
#       Github: https://github.com/pipesocks/install
#=================================================
pipes_file="/usr/local/pipesocks"
pipes_ver="/usr/local/pipesocks/ver.txt"
pipes_log="/usr/local/pipesocks/pipesocks.log"
pipes_config_file="/etc/pipesocks"
pipes_config="/etc/pipesocks/pipesocks.conf"
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${pipes_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 没有安装，请检查 !" && exit 1
}
check_new_ver(){
	#pipes_new_ver=`curl -m 10 -s "https://pipesocks.github.io/js/index.js" | sed -n "15p" | awk -F ": " '{print $NF}' | sed 's/"//g;s/,//g'`
	pipes_new_ver=`wget -qO- https://github.com/pipesocks/pipesocks/releases/latest | grep "<title>" | perl -e 'while($_=<>){ /Release pipesocks (.*) · pipesocks/; print $1;}'`
	[[ -z ${pipes_new_ver} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 最新版本获取失败 !" && exit 1
}
check_ver_comparison(){
	pipes_now_ver=`cat ${pipes_ver}`
	if [[ ${pipes_now_ver} != "" ]]; then
		if [[ ${pipes_now_ver} != ${pipes_new_ver} ]]; then
			echo -e "${Info_font_prefix}[信息]${Font_suffix} 发现 PipeSocks 已有新版本 [v${pipes_new_ver}] !"
			stty erase '^H' && read -p "是否更新 ? [Y/n] :" yn
			[[ -z "${yn}" ]] && yn="y"
			if [[ $yn == [Yy] ]]; then
				PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"` && [[ ! -z $PID ]] && kill -9 ${PID}
				Download_pipes
				Read_config
				Start_pipes
			fi
		else
			echo -e "${Info_font_prefix}[信息]${Font_suffix} 当前 PipeSocks 已是最新版本 [v${pipes_new_ver}] !" && exit 1
		fi
	else
		echo "${pipes_new_ver}" > ${pipes_ver}
		echo -e "${Info_font_prefix}[信息]${Font_suffix} 当前 PipeSocks 已是最新版本 [v${pipes_new_ver}] !" && exit 1
	fi
}
Download_pipes(){
	cd "/usr/local"
	if [[ ${bit} == "x86_64" ]]; then
		#wget -O "pipesocks-linux.tar.xz" "https://coding.net/u/yvbbrjdr/p/pipesocks-release/git/raw/master/pipesocks-${pipes_new_ver}-linux.tar.xz"
		wget -O "pipesocks-linux.tar.xz" "https://github.com/pipesocks/pipesocks/releases/download/${pipes_new_ver}/pipesocks-${pipes_new_ver}-linux.tar.xz"
	else
		echo -e "${Error_font_prefix}[错误]${Font_suffix} 不支持 ${bit} !" && exit 1
	fi
	[[ ! -e "pipesocks-linux.tar.xz" ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 下载失败 !" && exit 1
	[[ -e ${pipes_file} ]] && rm -rf ${pipes_file}
	tar -xJf pipesocks-linux.tar.xz && rm -rf pipesocks-linux.tar.xz
	[[ ! -e ${pipes_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 解压失败或压缩文件不完整 !" && exit 1
	cd ${pipes_file} && chmod +x *.sh
	echo "${pipes_new_ver}" > ${pipes_ver}
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${pipes_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${pipes_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${pump_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${pump_port} -j ACCEPT
}
Write_config(){
	if [[ ! -e ${pipes_config} ]]; then
		[[ ! -e ${pipes_config_file} ]] && mkdir ${pipes_config_file}
	fi
	cat > ${pipes_config}<<-EOF
pump_port=${pipes_port}
pump_passwd=${pipes_passwd}
EOF
}
Read_config(){
	[[ ! -e ${pipes_config} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 配置文件不存在 !" && exit 1
	pump_port=`cat ${pipes_config}|grep "pump_port"|awk -F "=" '{print $NF}'`
	pump_passwd=`cat ${pipes_config}|grep "pump_passwd"|awk -F "=" '{print $NF}'`
}
Set_user_pipes(){
	while true
		do
		echo -e "请输入 PipeSocks 本地监听端口 [1-65535]"
		stty erase '^H' && read -p "(默认: 2333):" pipes_port
		[[ -z "$pipes_port" ]] && pipes_port="2333"
		expr ${pipes_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${pipes_port} -ge 1 ]] && [[ ${pipes_port} -le 65535 ]]; then
				echo && echo "————————————————————"
				echo -e "	端口 : ${Info_font_prefix} ${pipes_port}${Font_suffix}"
				echo "————————————————————" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
	echo "请输入 PipeSocks 密码"
	stty erase '^H' && read -p "(默认: doub.io):" pipes_passwd
	[[ -z "${pipes_passwd}" ]] && pipes_passwd="doub.io"
	echo && echo "————————————————————"
	echo -e "	密码 : ${Info_font_prefix}${pipes_passwd}${Font_suffix}"
	echo "————————————————————" && echo
}
Set_pipes(){
	check_installed_status 
	Set_user_pipes
	Read_config
	Del_iptables
	Add_iptables
	Write_config
	Restart_pipes
}
View_pipes(){
	check_installed_status
	Read_config
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	[[ -z ${ip} ]] && ip="VPS_IP"
	clear && echo "————————————————" && echo
	echo -e " 你的 PipeSocks 账号信息 :" && echo
	echo -e " I  P\t: ${Info_font_prefix}${ip}${Font_suffix}"
	echo -e " 端口\t: ${Info_font_prefix}${pump_port}${Font_suffix}"
	echo -e " 密码\t: ${Info_font_prefix}${pump_passwd}${Font_suffix}"
	echo && echo "————————————————"
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	if [[ ! -z $PID ]]; then
		echo -e " 当前状态: ${Info_font_prefix}正在运行${Font_suffix}"
	else
		echo -e " 当前状态: ${Error_font_prefix}没有运行${Font_suffix}"
	fi
	echo
}
Install_pipes(){
	[[ -e ${pipes_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} 检测到 PipeSocks 已安装，如需继续，请先卸载 !" && exit 1
	check_sys
	check_new_ver
	Set_user_pipes
	Download_pipes
	Write_config
	Add_iptables
	Start_pipes
}
Update_pipes(){
	check_installed_status
	check_sys
	check_new_ver
	check_ver_comparison
}
Start_pipes(){
	check_installed_status
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	[[ ! -z $PID ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 进程正在运行，请检查 !" && exit 1
	Read_config
	cd ${pipes_file} && nohup ./runpipesocks.sh pump -p ${pump_port} -k ${pump_passwd} &>pipesocks.log &
	sleep 2s && PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	if [[ -z $PID ]]; then
		echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 启动失败 !" && exit 1
	else
		View_pipes
	fi
}
Stop_pipes(){
	check_installed_status
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	[[ -z $PID ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} 没有发现 PipeSocks 进程运行，请检查 !" && exit 1
	kill -9 ${PID} && sleep 2s && PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	if [[ ! -z $PID ]]; then
		echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 停止失败 !" && exit 1
	else
		echo && echo "PipeSocks 已停止 !" && echo
	fi
}
Restart_pipes(){
	check_installed_status
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	if [[ ! -z $PID ]]; then
		Stop_pipes
	fi
	Start_pipes
}
Log_pipes(){
	check_installed_status
	[[ ! -e ${pipes_log} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} PipeSocks 日志文件不存在 !" && exit 1
	echo && echo -e "使用 ${Info_background_prefix} Ctrl+C ${Font_suffix} 键退出查看日志 !" && echo
	tail -f ${pipes_log}
}
Uninstall_pipes(){
	check_installed_status
	echo "确定要卸载 PipeSocks ? [y/N]" && echo
	stty erase '^H' && read -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		rm -rf ${pipes_file} && rm -rf  ${pipes_config_file}
		echo && echo "PipeSocks 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}
echo && echo "请输入一个数字来选择选项" && echo
echo -e " 1. 安装 PipeSocks"
echo -e " 2. 升级 PipeSocks"
echo -e " 3. 卸载 PipeSocks"
echo "————————————"
echo -e " 4. 启动 PipeSocks"
echo -e " 5. 停止 PipeSocks"
echo -e " 6. 重启 PipeSocks"
echo "————————————"
echo -e " 7. 设置 PipeSocks 账号"
echo -e " 8. 查看 PipeSocks 账号"
echo -e " 9. 查看 PipeSocks 日志"
echo "————————————" && echo
if [[ -e ${pipes_file} ]]; then
	PID=`ps -ef|grep "pipesocks"|grep -v "grep"|awk '{print $2}'|sed -n "2p"`
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Info_font_prefix}已安装${Font_suffix} 并 ${Info_font_prefix}已启动${Font_suffix}"
	else
		echo -e " 当前状态: ${Info_font_prefix}已安装${Font_suffix} 但 ${Error_font_prefix}未启动${Font_suffix}"
	fi
else
	echo -e " 当前状态: ${Error_font_prefix}未安装${Font_suffix}"
fi
echo
stty erase '^H' && read -p " 请输入数字 [1-9]:" num
case "$num" in
	1)
	Install_pipes
	;;
	2)
	Update_pipes
	;;
	3)
	Uninstall_pipes
	;;
	4)
	Start_pipes
	;;
	5)
	Stop_pipes
	;;
	6)
	Restart_pipes
	;;
	7)
	Set_pipes
	;;
	8)
	View_pipes
	;;
	9)
	Log_pipes
	;;
	*)
	echo "请输入正确数字 [1-9]"
	;;
esac
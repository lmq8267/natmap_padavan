#!/bin/sh

# 这个为解析IP:端口到域名 使用txt方式，nslookup -type=txt 域名 即可解析出地址
#命令行为 nslookup -type=txt 你的域名 ns1.dynv6.com | awk '/text/' | awk '{print $4}' | awk -F\" '{print $2}'

# 域名的token值 （也就是password='CcgLKLGw1HCQNt5ix_sdcJyoDF65Fjnb'）
token="CcgLKLGw1HCQNt5ix_sdcJyoDF65Fjnb"

#域名,上方token值的域名"
host="abc8267.v6.army"

#上面域名的前缀（例如 test.abc8267.v6.army）,并需要为此域名先创建一个txt记录 任意值即可 如 "120.66.66.66:52011"
host_name="test"

host_domian="${host_name}.${host}"
IP=$1 
PORT=$2
addr=${IP}:${PORT}
log () {
   logger -t "【Dynv6域名TXT解析】" "$1"
   echo -e "\n\033[36;1m$(date "+%G-%m-%d %H:%M:%S") ：\033[0m\033[35;1m$1 \033[0m"
}

log "开始解析${IP}:${PORT} 到 ${host_domian} "

log "开始获取 ${host}  的区域ID..."
zoon_id="$(curl -s -k -X GET \
       -H "Authorization: Bearer $token" \
       -H "Content-Type: application/json" \
       -H "Accept: application/json" \
       https://dynv6.com/api/v2/zones )"
zoonid=$(echo "$zoon_id" | grep -o "{[^}]*\"name\":\"$host\"[^}]*}" | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+')
if [ -z "$zoonid"] ; then
   log "无法获取 ${host} 的区域ID，请检查"
   exit 1
fi
log "${host} 的区域ID：$zoonid"

log "开始获取 ${host_domian} 的记录ID..."
record="$(curl -s -k -X GET \
       -H "Authorization: Bearer $token" \
       -H "Content-Type: application/json" \
       -H "Accept: application/json" \
       https://dynv6.com/api/v2/zones/$zoonid/records)"
#records=$(echo "$record" | grep -o "{[^}]*\"name\":\"$host_name\"[^}]*}")
recordid=$(echo "$record" | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+')
last_ip=$(echo "$record" | grep -oE '"data":"([^"]+)"' | cut -d '"' -f 4)
if [ -z "$recordid"] ; then
   log "无法获取 ${host_domian} 的记录ID，请检查"
   exit 1
fi
log " ${host_domian} 的记录ID：$recordid"
log "${host_domian}  记录的IP：$last_ip"

if [ "$addr" != "$last_ip" ] ; then
  status=$(curl -s -k -X PATCH \
       -H "Authorization: Bearer $token" \
       -H "Content-Type: application/json" \
       -H "Accept: application/json" \
       --data '{"name":"'$host_name'", "data":"'$addr'", "type":"TXT"}' \
       https://dynv6.com/api/v2/zones/$zoonid/records/$recordid)
 statu=$(echo "$status" | grep -oE '"data":"([^"]+)"' | cut -d '"' -f 4)
  if [ "$addr" = "$statu" ] ; then
     log "更新 ${IP}:${PORT} 到 ${host_domian} 成功！"
     exit 0
  else
     log "更新 ${IP}:${PORT} 到 ${host_domian} 失败，请检查"
     exit 1
  fi
else
  log "当前IP ${addr} 与上次IP ${last_ip} 相同，无需更新！ "
  exit 0
fi

#获取域名txt记录的curl方式
#curl -k -s 'https://ipw.cn/api/dns/你的域名/TXT/all'| grep -oE '"Type":"TXT","recordValue":[^,}]*' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | tail -n 1


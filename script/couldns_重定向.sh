#!/bin/sh
#这是将生成的ip：端口直接重定向到域名直接访问，注意这不是cloudflare
#帐号user和密码userpass，帐号里的 @ 用 %40 表示，例如 zhansan@163.com  就填zhansan%40163.com 
user="109505310%40qq.com"
userpass="wodemima"
#域名
host_domian="test.wode.cloudns.be"


IP=$1 
PORT=$2
addr=http://${IP}:${PORT}
log () {
   logger -t "【Cloudns域名解析】" "$1"
   echo -e "\033[36;1m$(date "+%G-%m-%d %H:%M:%S") ：\033[0m\033[35;1m$1 \033[0m"
}

## 携帐号密码登录获取session_id
login=0
if [ -f /tmp/session_id ] ; then
now_time=`date +%s`
last_time="$(cat /tmp/session_id_time)"
if [ ! -z "$now_time" ] && [ ! -z "last_time" ] ; then
time=`expr $now_time - $last_time`
fi
# 假设登录缓存超过半小时（1800秒）失效，才重新登录
[ ! -z "$time" ] && [ "$time" -lt "1800" ] && login=1
fi
if [ "$login" = "0" ] ; then
log "$user $userpass"
curl -c /tmp/session_id -s -k 'https://www.cloudns.net/ajaxActions.php?action=index' \
  -d 'type=login2FA&mail='"$user"'&password='"$userpass"'&token=&captcha=' 
  
session_id="$(cat /tmp/session_id | grep "session_id" | awk '{print $7}')"
if [ ! -z /tmp/session_id ] ; then
 echo `date +%s` >/tmp/session_id_time
fi
fi
if [ ! -f /tmp/session_id ] ; then
log "未获取到cloudns帐号的session_id，请检查"
exit 1
fi
session_id="$(cat /tmp/session_id | grep "session_id" | awk '{print $7}')"
if [ -z /tmp/session_id ] ; then
log "未获取到cloudns帐号的session_id${session_id}，请检查"
exit 1
else
log "当前cloudns帐号的session_id：$session_id"
fi

## 再携session_id获取域名的区域ID 
zoneID="$(curl -s -k 'https://www.cloudns.net/ajaxPages.php?action=main&nocache=1712445852064' \
  -H 'cookie: session_id='"$session_id"'; landing_page=%2F; static_revision=39632; _ga=GA1.1.1887499628.1712409883; referral=https%3A%2F%2Fwww.cloudns.net%2F; lang=chs; _ga_YTMCW6TB90=GS1.1.1712416242.2.1.1712416532.60.0.0' \
  -d '&show=zones')"
  Zone_ID=$(echo $zoneID| grep -o 'toggleZoneMenu[[:space:]]*([[:space:]]*[0-9][0-9]*' | grep -o '[0-9][0-9]*')
  if [ -z "$Zone_ID" ] ; then
    log "获取 ${host_domian} 的区域ID失败，请检查"
    exit 1
   else
    log "当前 ${host_domian} 的区域ID：$Zone_ID"
  fi

  ## 接着携区域ID获取域名记录的recordID
 recordID="$(curl -s -k 'https://www.cloudns.net/ajaxPages.php?action=records' \
  -H 'cookie: session_id='"$session_id"'; landing_page=%2F; static_revision=39632; _ga=GA1.1.1887499628.1712409883; referral=https%3A%2F%2Fwww.cloudns.net%2F; lang=chs; _ga_YTMCW6TB90=GS1.1.1712416242.2.1.1712416532.60.0.0' \
  -H 'referer: https://www.cloudns.net/records/domain/$Zone_ID/' \
  -d '&show=get&zone='"$Zone_ID"'&type=all&order-by=null&page=1')"
RecordID=$(echo $recordID|grep -oE "zone_deleteRecord\([0-9]+, ([0-9]+), '删除记录: ${host_domian} - WR - (http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+)'\)" | awk -F', ' '{if (!printed[$2]) {print $2, $3; printed[$2]=1}}' | awk '{ztid=$1; out2=$7; print ztid, out2}' | tr -d "')")
Record_ID=$(echo $RecordID | awk '{print $1}')
Record_IP=$(echo $RecordID | awk '{print $2}')
if [ -z "$Record_ID" ] ; then
  log "获取 ${host_domian} 的记录ID失败，请检查"
  exit 1
 else
  log "当前 ${host_domian} 的记录ID：$Record_ID 记录值为：$Record_IP"
fi

## 开始携获取的session_id 区域ID 记录ID 更新记录值
if [ "$addr" != "$Record_IP" ] ; then
log "原有记录 ${Record_IP} 不等于当前记录 ${addr} ，开始更新..."
curl -s -k 'https://www.cloudns.net/ajaxActions.php?action=records' \
  -H 'cookie: session_id='"$session_id"'; landing_page=%2F; static_revision=39632; _ga=GA1.1.1887499628.1712409883; referral=https%3A%2F%2Fwww.cloudns.net%2F; lang=chs; _ga_YTMCW6TB90=GS1.1.1712416242.2.0.1712416242.60.0.0' \
  -H 'referer: https://www.cloudns.net/records/domain/$Zone_ID/' \
  -d 'show=editRecord&zone='"$Zone_ID"'&record_id='"$Record_ID"'&settings%5Badditional_data%5D%5Bwrtype%5D=302&settings%5Bhost%5D=test&settings%5Brecord%5D=http%3A%2F%2F'"$IP"'%3A'"$PORT"'&settings%5Bttl%5D=3600' 

## 检查是否将新地址成功更新上去
status=$(curl -s -k 'https://www.cloudns.net/ajaxPages.php?action=records&show=edit&zone='"$Zone_ID"'&record='"$Record_ID"'&nocache=1712445600198' \
  -H 'cookie: session_id='"$session_id"'; landing_page=%2F; static_revision=39632; _ga=GA1.1.1887499628.1712409883; referral=https%3A%2F%2Fwww.cloudns.net%2F; lang=chs; _ga_YTMCW6TB90=GS1.1.1712416242.2.1.1712416532.60.0.0' \
  -H 'referer: https://www.cloudns.net/records/domain/$Zone_ID/' )
  now_IP=$(echo $status | awk -F 'id="editRecordRecord" value="' '{print $2}' | awk -F '"' '{print $1}')
  if [ "$now_IP" = "$addr" ] ; then
    log "更新成功，当前 ${host_domian} 已更新为 ${now_IP}"
  else
    log "更新失败，${now_IP}请检查"
    exit 1
  fi
else
  log "原有记录 ${Record_IP} 等于当前记录 ${addr} ，无需更新！"
  exit 0
fi

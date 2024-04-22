#!/bin/bash
#这是cloudflare的重定向规则 非origin-rules
##################################################################################################
#下方66666666666666666666填写你cloudflare的API令牌 要填在""双引号内
cloudflare_token="66666666666666666666"

#下方123456@qq.com填写你cloudflare的帐号邮箱 填在""双引号内
cloudflare_Email="123456@qq.com"

#下方88888888888888填写你cloudflare的API key 填在""双引号内 
cloudflare_Key="88888888888888"

#下方""内填写你的顶级域名 如"abc.com"，必须是绑定在cf的域名
cloudflare_domian="abc.com"

#下方""内填写你的子域名,如"123"只用顶级域名下方填"@"
cloudflare_host="123"

#下方""内填写你的顶级域名 如"abc.com"   
cloudflare_domian6=""

#下方""内填写你的子域名,如"123"只用顶级域名下方填"@"  
cloudflare_host6=""


#下方""内填你外网访问的域名，不能和上面的一致如"888.abc.com" 
host0=""

#################################################################################################
[ -z "$cloudflare_host" ] && cloudflare_host=@
[ -z "$cloudflare_host6" ] && cloudflare_host6=@
if [ ! -z "$cloudflare_token" ] ; then
account_key_1="Authorization: Bearer $cloudflare_token"
account_key_2="X-Auth-Email: $cloudflare_Email"
account_key_a1=" -H "
account_key_a2=" -H "
fi
if [ -z "$cloudflare_token" ] && [ ! -z "$cloudflare_Email" ] && [ ! -z "$cloudflare_Key" ] ; then
account_key_1="X-Auth-Email: $cloudflare_Email"
account_key_2="X-Auth-Key: $cloudflare_Key"
account_key_a1=" -H "
account_key_a2=" -H "
fi

IP4P="$3"
IP="$1"
IPport="$2"
IPadd="http://${1}:${2}"
echo "当前公网访问地址：$IPadd 当前IP4P地址：$3"
logger -t "【natmap】" "当前公网访问地址： $1:$2 当前IP4P地址：$3"
domain_type=""
hostIP=""
Zone_ID=""
RECORD_ID=""
DOMAIN=""
HOST=""
IPv6=0
[ -z $cloudflare_interval ] && cloudflare_interval=600 


get_Zone_ID() {
# 获得Zone_ID
Zone_ID=$(curl -L  -k  -s -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $cloudflare_token" \
     -H "X-Auth-Email: $cloudflare_Email"  )
Zone_ID=$(echo $Zone_ID | sed -e "s/ //g" |grep -o "id\":\"[0-9a-z]*\",\"name\":\"$DOMAIN\",\"status\""|grep -o "id\":\"[0-9a-z]*\""| awk -F : '{print $2}'|grep -o "[a-z0-9]*")
echo Zone_ID=$Zone_ID

}
arDdnsInfo() {
if [ "$IPv6" = "1" ]; then
	domain_type="AAAA"
else
	domain_type="A"
fi
case  $HOST  in
	  \*)
		host_domian="\\$HOST.$DOMAIN"
		;;
	  \@)
		host_domian="$DOMAIN"
		;;
	  *)
		host_domian="$HOST.$DOMAIN"
		;;
esac

# 获得Zone_ID
get_Zone_ID
# 获得最后更新IP
recordIP=$(curl -L  -k -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records?type=$domain_type&match=all" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     -H "X-Auth-Key: $cloudflare_Key" )
sleep 1
RECORD_ID=$(echo $recordIP | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o "\"id\":\"[0-9a-z]\{32,\}\",\"" | awk -F : '{print $2}'|grep -o "[a-z0-9]*")
recordIP=$(echo $recordIP | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o ",\"content\":\"[^\"]*\"" | awk -F 'content":"' '{print $2}' | tr -d '"' |head -n1)
# 检查是否有名称重复的子域名
echo recordIP =$recordIP
if [ "$(echo "$RECORD_ID" | grep -o "[0-9a-z]\{32,\}"| wc -l)" -gt "1" ] ; then
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 获得最后更新IP时发现重复的子域名！"
	for Delete_RECORD_ID in $RECORD_ID
	do
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 删除名称重复的子域名！ID: $Delete_RECORD_ID"
	RESULT=$(curl -L    -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$Delete_RECORD_ID" \
     -H "Content-Type: application/json"\
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2" )
	sleep 1
	done
	recordIP="0"
	lastIP=$recordIP
	echo $recordIP
	return 0
fi
	if [ "$IPv6" = "1" ]; then
	lastIP=$recordIP
	echo $recordIP
	return 0
	else
	case "$recordIP" in 
	[1-9]*)
	        lastIP=$recordIP
		echo $recordIP
		return 0
		;;
	*)
		echo "Get Record Info Failed!"
		#logger -t "【cloudflare动态域名】" "获取记录信息失败！"
		return 1
		;;
	esac
	fi

}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
I=3
RECORD_ID=""
if [ "$IPv6" = "1" ]; then
	domain_type="AAAA"
else
	domain_type="A"
fi
case  $HOST  in
	  \*)
		host_domian="\\$HOST.$DOMAIN"
		;;
	  \@)
		host_domian="$DOMAIN"
		;;
	  *)
		host_domian="$HOST.$DOMAIN"
		;;
esac

while [ -z "$RECORD_ID" ] ; do
	I=$(($I - 1))
	[ $I -lt 0 ] && break
# 获得Zone_ID
get_Zone_ID
# 获得记录ID
recordIP=$(curl -L -k -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records?type=$domain_type&match=all" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     -H "X-Auth-Key: $cloudflare_Key" )
sleep 1
RECORD_ID=$(echo $recordIP | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o "\"id\":\"[0-9a-z]\{32,\}\",\"" | awk -F : '{print $2}'|grep -o "[a-z0-9]*")
(echo $recordIP | sed -e "s/ //g" | sed -e "s/"'"ttl":'"/"' \n '"/g" | grep "type\":\"$domain_type\"" | grep ",\"name\":\"$host_domian\"" | grep -o ",\"content\":\"[^\"]*\"" | awk -F 'content":"' '{print $2}' | tr -d '"' |head -n1)
if [ "$(echo "$RECORD_ID" | grep -o "[0-9a-z]\{32,\}"| wc -l)" -gt "1" ] ; then
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 更新记录信息时发现重复的子域名！"
	for Delete_RECORD_ID in $RECORD_ID
	do
	logger -t "【cloudflare动态域名】" "$HOST.$DOMAIN 删除名称重复的子域名！ID: $Delete_RECORD_ID"
	RESULT=$(curl -L  -k -X DELETE "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$Delete_RECORD_ID" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2")
      echo RESULT=$RESULT
	sleep 1
	done
	RECORD_ID=""
fi
sleep 1
done

if [ -z "$RECORD_ID" ] ; then
	# 添加子域名记录IP
	RESULT=$(curl -L -k -s -X POST "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2" \
     --data '{"type":"'$domain_type'","name":"'$HOST'","content":"'$hostIP'","ttl":120,"proxied":false}')
     sleep 1
	RESULT=$(echo $RESULT | sed -e "s/ //g" | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
	echo "创建dns解析记录: $RESULT"
	logger -t "【cloudflare动态域名】" "创建$HOST.$DOMAIN 域名"
else
	# 更新记录IP
	RESULT=$(curl -L  -k -s -X PUT "https://api.cloudflare.com/client/v4/zones/$Zone_ID/dns_records/$RECORD_ID" \
     -H "Content-Type: application/json" \
     $account_key_a1 "$account_key_1" \
     $account_key_a2 "$account_key_2" \
     --data '{"type":"'$domain_type'","name":"'$HOST'","content":"'$hostIP'","ttl":120,"proxied":false}')
	sleep 1
	RESULT=$(echo $RESULT | sed -e "s/ //g" | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
	echo "更新dns解析记录: $RESULT"
fi

if [ "$(printf "%s" "$RESULT"|grep -c -o "true")" = 1 ];then
	echo "$(date) -- 更新成功"
	return 0
else
	echo "$(date) -- 更新失败"
	return 1
fi

}
portCheck() {

T=3
rulesID=""
originID=""
Zone_ID=""
while [ -z "$rulesID" ] ; do
	T=$(($T - 1))
	[ $T -lt 0 ] && break
#获取区域ID
get_Zone_ID
rulesID=$(curl -L -k -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/rulesets" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $cloudflare_token" \
     -H "X-Auth-Key: $cloudflare_Key" )
rulesID=$(echo $rulesID | sed -e "s/ //g" | sed -e "s/"'{'"/"' \n '"/g" | grep "phase\":\"http_request_dynamic_redirect\"" | grep -o "\"id\":\"[0-9a-z]\{32,\}\",\"" | awk -F : '{print $2}'|grep -o "[a-z0-9]*" )
[ -z "$rulesID" ] && echo "错误，获取rulesID=$rulesID 失败"
case  $HOST  in
	  \*)
		host_domian="\\$HOST.$DOMAIN"
		;;
	  \@)
		host_domian="$DOMAIN"
		;;
	  *)
		host_domian="$HOST.$DOMAIN"
		;;
esac
originID=$(curl -L -k -s -X GET "https://api.cloudflare.com/client/v4/zones/$Zone_ID/rulesets/$rulesID" \
     -H "Content-Type: application/json" \
     -H "X-Auth-Email: $cloudflare_Email" \
     -H "Authorization: Bearer $cloudflare_token" )
originID=$(echo $originID | sed -e "s/ //g" | sed -e "s/"'{'"/"' \n '"/g" | grep "$host0" | grep "http.host" | grep "natmap" | grep -o "\"id\":\"[0-9a-z]\{32,\}\",\"" | awk -F : '{print $2}'|grep -o "[a-z0-9]*" )
echo "重定向规则id有 $originID  "
done
if [ ! -z "$originID" ] ; then
if [ "$(echo "$originID" | grep -o "[0-9a-z]\{32,\}"| wc -l)" -gt "1" ] ; then
	logger -t "【cloudflare动态域名】" "$host0 更新记录信息时发现重复的重定向规则！"
	for Delete_originID in $originID
	do
	logger -t "【cloudflare动态域名】" "$host0 删除重复的重定向规则！ID:$Delete_originID"
	echo "删除重复的重定向规则！ID:$Delete_originID"
     RESULT=$(curl -L  -k  -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$Zone_ID/rulesets/$rulesID/rules/$Delete_originID" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $cloudflare_token" \
     -H "X-Auth-Key: $cloudflare_Key" \
     -H "X-Auth-Email: $cloudflare_Email" )
      echo RESULT=$RESULT
	sleep 1
	done
	originID=""
fi
fi
if [ -z "$originID" ] ; then
# 添加重定向规则
newrules=$(curl -L -k -s -X POST "https://api.cloudflare.com/client/v4/zones/$Zone_ID/rulesets/$rulesID/rules" \
     -H "Authorization: Bearer $cloudflare_token" \
     -H "Content-Type:application/json" \
     --data '{"description":"natmap","expression":"(http.host eq \"'$host0'\")","action":"redirect","action_parameters":{"from_value":{"status_code":302,"preserve_query_string":true,"target_url":{"expression":"concat(\"http://'$host_domian':'$IPport'\", http.request.uri.path)"}}},"enabled":true}' )
sleep 1
newrules=$(echo $newrules | sed -e "s/ //g" | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
logger -t "【cloudflare动态域名】" "添加$host0 重定向${host_domian}:${IPport} 规则"
else
# 更新重定向规则
newrules=$(curl -L -k -s "https://api.cloudflare.com/client/v4/zones/$Zone_ID/rulesets/$rulesID/rules/$originID" \
     -X 'PATCH' \
     -H "Authorization: Bearer $cloudflare_token" \
     -H "Content-Type:application/json" \
     --data '{"description":"natmap","expression":"(http.host eq \"'$host0'\")","action":"redirect","action_parameters":{"from_value":{"status_code":302,"preserve_query_string":true,"target_url":{"expression":"concat(\"http://'$host_domian':'$IPport'\", http.request.uri.path)"}}},"enabled":true}' )
sleep 1
newrules=$(echo $newrules | sed -e "s/ //g" | grep -o "success\":[a-z]*,"|awk -F : '{print $2}'|grep -o "[a-z]*")
fi
echo "更新重定向规则状态: $newrules"
if [ "$(printf "%s" "$newrules"|grep -c -o "true")" = 1 ];then
	logger -t "【cloudflare动态域名】" "更新$host0 域名重定向${host_domian}:${IPport} 成功"
	return 0
else
	logger -t "【cloudflare动态域名】" "错误！更新$host0 域名重定向${host_domian}:${IPport} 失败！"
	return 1
fi
}

# 动态检查更新
# 参数: 主域名 子域名
arDdnsCheck() {
	if [ "$IPv6" = "1" ]; then
	hostIP="$IP4P"
        else
	hostIP="$IP"
        fi
	if [ -z $hostIP ] ; then 
		logger -t "【cloudflare动态域名】" "错误！IP地址:$hostIP ,请检查natmap是否生成IP地址"
		return 1
	fi
	echo "开始更新域名: $HOST.$DOMAIN 指向 $hostIP"
	arDdnsInfo
	if [ $? -eq 1 ]; then
           echo "开始nslookup获取上次ip"
	   [ "$IPv6" = "1" ] && lastIP="$(nslookup "$HOST.$DOMAIN" | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" | sed -n '1p')"
	fi
	echo "目前 IP地址: $hostIP ，上次 IP地址: $lastIP"
	[ -z "$lastIP" ] && logger -t "【cloudflare动态域名】" "nslookup无法解析出${HOST}.${DOMAIN}上次IP"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【cloudflare动态域名】" "开始更新 "$HOST.$DOMAIN" 域名 IP 指向，目前 IP: $hostIP ，上次 IP: $lastIP"
		sleep 1
		postRS=$(arDdnsUpdate)
		if [ $? -eq 0 ]; then
			echo "更新动态DNS记录成功！"
			logger -t "【cloudflare动态域名】" "更新动态DNS记录成功！"
			lastIP=$hostIP
			return 0
		else
			echo 更新动态DNS记录失败！
			logger -t "【cloudflare动态域名】" "更新动态DNS记录失败！请看看是哪里的问题。"
			return 1
		fi
	fi
	echo "上次 IP: $lastIP 与 目前 IP: $hostIP 相同!"
	return 1
}

if [ ! -z  "$cloudflare_domian" ] && [ ! -z  "$cloudflare_host" ] ; then
	sleep 1
	IPv6=0
	DOMAIN="$cloudflare_domian"
	HOST="$cloudflare_host"
	RECORD_ID=""
	proxied="ture"
	portCheck
	arDdnsCheck
fi
if [ ! -z  "$cloudflare_domian6" ] && [ ! -z  "$cloudflare_host6" ] ; then
	sleep 1
	IPv6=1
	DOMAIN="$cloudflare_domian6"
	HOST="$cloudflare_host6"
	RECORD_ID=""
	proxied="false"
	arDdnsCheck
fi

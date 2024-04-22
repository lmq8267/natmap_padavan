#!/bin/sh

#下方的LTAFg555TFH258HGCC改为你阿里云的Access Key ID
aliddns_ak="LTAFg555ToH258HGCC"

#下方的8ufd852igfdcb148822gg1改为你阿里云的Access Key Secret
aliddns_sk="8ufd852igfdcb148822gg1"

#下方的abc改为你阿里云的子域名如www
aliddns_name6="abc"

#下方的baidu.com改为你阿里云的顶级域名
aliddns_domain6="baidu.com"

##########################################################################################

IP4P="$3"
echo "当前公网访问地址： $1:$2 当前IP4P地址：$3"
logger -t "【natmap】" "当前公网访问地址： $1:$2 当前IP4P地址：$3"
echo "$IP4P" > /tmp/natmapIP4Pnew.txt
[ -z "$aliddns_name6" ] && aliddns_name6="www" && logger -t "【AliDDNS动态域名】" "子域名为空，已自动设置为www.$aliddns_domain6"
domain="$aliddns_domain6"
name="$aliddns_name6"
aliddns_interval=600
aliddns_ttl=600
IPv6=1
domain_type="AAAA"
urlencode() {
	# urlencode <string>
	out=""
	while read -n1 c
	do
		case $c in
			[a-zA-Z0-9._-]) out="$out$c" ;;
			*) out="$out`printf '%%%02X' "'$c"`" ;;
		esac
	done
	echo -n $out
}

enc() {
	echo -n "$1" | urlencode
}

send_request() {
	args="AccessKeyId=$aliddns_ak&Action=$1&Format=json&$2&Version=2015-01-09"
	hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddns_sk&" -binary | openssl base64)
	curl -L    -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
	sleep 1
}

get_recordid() {
	grep -Eo '"RecordId":"[0-9]+"' | cut -d':' -f2 | tr -d '"' |head -n1
}

get_recordIP() {
	sed -e "s/"'"TTL":'"/"' \n '"/g" | grep '"Type":"'$domain_type'"' | grep -Eo '"Value":"[^"]*"' | awk -F 'Value":"' '{print $2}' | tr -d '"' |head -n1
}

query_recordInfo() {
	send_request "DescribeDomainRecordInfo" "RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&Timestamp=$timestamp"
}

query_recordid() {
	send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$name1.$domain&Timestamp=$timestamp&Type=$domain_type"
}

update_record() {
	hostIP_tmp=$(enc "$hostIP")
	send_request "UpdateDomainRecord" "RR=$name1&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=$domain_type&Value=$hostIP_tmp"
}

add_record() {
	hostIP_tmp=$(enc "$hostIP")
	send_request "AddDomainRecord&DomainName=$domain" "RR=$name1&SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&TTL=$aliddns_ttl&Timestamp=$timestamp&Type=$domain_type&Value=$hostIP_tmp"
}

arDdnsInfo() {
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	# 获得域名ID
	aliddns_record_id=""
	aliddns_record_id=`query_recordid | get_recordid`
	sleep 1
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	# 获得最后更新IP
	recordIP=`query_recordInfo $aliddns_record_id | get_recordIP`
	echo $recordIP
	return 0
	
}
arDdnsUpdate() {	
I=3
case  $name  in
	  \*)
		name1=%2A
		;;
	  \@)
		name1=%40
		;;
	  *)
		name1=$name
		;;
esac

	# 获得记录ID
	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
	aliddns_record_id=""
	aliddns_record_id=`query_recordid | get_recordid`
	echo "记录ID= $aliddns_record_id"
	sleep 1

	timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
if [ "$aliddns_record_id" = "" ] ; then
	aliddns_record_id=`add_record | get_recordid`
	echo "添加的记录 ： $aliddns_record_id"
	logger -t "【AliDDNS动态域名】" "添加的记录 ： $aliddns_record_id"
else
	update_record $aliddns_record_id
	echo "更新的记录 : $aliddns_record_id"
	logger -t "【AliDDNS动态域名】" "更新的记录 ： $aliddns_record_id"
fi
if [ "$aliddns_record_id" = "" ] ; then
	logger -t "【AliDDNS动态域名】" "更新失败"
	return 1
else
	logger -t "【AliDDNS动态域名】" "成功更新IP4P： $hostIP"
	return 0
fi

}
arDdnsCheck() {
	mkdir -p /tmp/arNslookup
        I=5
        rm -f /tmp/arNslookup/natmapip.txt
        while [ ! -s /tmp/arNslookup/natmapip.txt ] ; do
	echo "开始解析${aliddns_name6}.${aliddns_domain6}的上次 IP4P"
	echo "$(nslookup ${aliddns_name6}.${aliddns_domain6} | tail -n +3 | grep "Address" | awk '{print $3}'| grep ":" | sed -n '1p')" > /tmp/arNslookup/natmapip.txt 
	I=$(($I - 1))
	[ $I -lt 0 ] && break
	sleep 1
	done
	killall nslookup
if [ -s /tmp/arNslookup/natmapip.txt ] ; then
	lastIP="$(cat /tmp/arNslookup/natmapip.txt | sort -u | grep -v '^$')"
	rm -f /tmp/arNslookup/natmapip.txt
fi
hostIP="$(cat /tmp/natmapIP4Pnew.txt)"
[ -z "$lastIP" ] && logger -t "【AliDDNS动态域名】" "nslookup无法解析出$alidd的上次IP4P" && lastIP=""
	echo "上次 IP4P: ${lastIP} 目前 IP4P: ${hostIP}"
	if [ "$lastIP" != "$hostIP" ] ; then
		logger -t "【AliDDNS动态域名】" "开始更新域名${aliddns_name6}.${aliddns_domain6}指向,目前 IP4P: ${hostIP}"
		logger -t "【AliDDNS动态域名】" "上次 IP4P: ${lastIP}"
		sleep 1
		postRS=$(arDdnsUpdate $aliddns_domain6 $aliddns_name6)
		if [ $? -eq 0 ]; then
			echo "postRS: ${postRS}"
			logger -t "【AliDDNS动态域名】" "更新动态DNS记录成功！"
			rm -rf /tmp/natmapIP4Pnew.txt
			lastIP=$hostIP
			return 0
		else
			echo ${postRS}
			logger -t "【AliDDNS动态域名】" "更新动态DNS记录失败！"
			return 1
		fi
        fi
	echo "上次 IP4P: ${lastIP} 与 目前 IP4P: ${hostIP} 相同!"
	
}
arDdnsCheck

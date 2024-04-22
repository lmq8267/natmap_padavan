#!/bin/sh

#下方abc.v6.army改为你的dynv6域名
name="abc.v6.army"
#下方opNB5yzZDF7HCPJGCTAm6s_xehRu9ab改为你的token
token="opNB5yzZDF7HCPJGCTAm6s_xehRu9ab"

###############################################################

echo "当前公网访问地址： $1:$2 当前IP4P地址：$3"
logger -t "【natmap】" "当前公网访问地址： $1:$2 当前IP4P地址：$3"
curltest=`which curl`
IP4P="$3"
while true; do
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
    wget --no-check-certificate -q "https://dynv6.com/api/update?hostname=$name&token=$token&ipv6=$IP4P"
else
   echo curl "http://dynv6.com/api/update?hostname=$name&token=$token&ipv6=$IP4P"
fi
    if [ $? -eq 0 ]; then
        echo "$IP4P更新成功"
        logger -t "【dynv6动态域名】" "更新域名$name指向 $IP4P 成功！"
        break
    fi
done

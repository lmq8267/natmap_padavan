#!/bin/sh

eval $(nslookup 域名 223.5.5.5 | awk '/2001/' |cut -d ':' -f 2-6 | awk -F: '{print "port="$3" ipa="$4" ipb="$5 }')

port=$((0x$port))
ip1=$((0x${ipa:0:2}))
ip2=$((0x${ipa:2:2}))
ip3=$((0x${ipb:0:2}))
ip4=$((0x${ipb:2:2}))
ipv4="${ip1}.${ip2}.${ip3}.${ip4}:${port}"
if [ -n "$ipv4" ] ; then
echo -e "\033[35;1m 当前服务器地址为：$ipv4 \033[0m"
fi

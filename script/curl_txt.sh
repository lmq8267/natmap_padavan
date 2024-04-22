#!/bin/sh
#部分通过curl获取域名txt记录值的api方法

curl -k -s 'https://lzltool.com/nslookup/' --data-raw 'url=你的域名' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'http://www.jsons.cn/nslookup/' --data-raw 'txt_url=你的域名'  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'https://api.uutool.cn/dns/nslookup/?domain=你的域名' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'https://helohub.com/api/txt/你的域名' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'https://api.33tool.com/api/client/nslookup' -H 'content-type: application/json;charset=UTF-8' --data-raw '{"url":"你的域名"}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'https://ipw.cn/api/dns/你的域名/TXT/all' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | tail -n 1

curl -k -s 'https://myssl.com/api/v1/tools/dns_query?qtype=16&host=你的域名&qmode=-1' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | tail -n 1

curl -k -s 'https://www.nslookup.io/api/v1/other-records' --data-raw '{"domain":"你的域名","dnsServer":"authoritative","recordType":"txt"}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | tail -n 1

curl -k -s 'https://coding.tools/cn/nslookup' --data-raw 'queryStr=你的域名&querytype=TXT&dnsserver=8.8.8.8' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'https://www.lddgo.net/api/Dns' --data-raw '{"recordType":"txt","inputUrl":"你的域名"}' -H 'content-type: application/json;charset=UTF-8' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

curl -k -s 'https://face.racent.com/tool/query_my_dns?name=你的域名&dns_type=TXT&node=CN-Shanghai' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+'

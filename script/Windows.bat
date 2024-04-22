@echo off
for /f "tokens=1 delims=""" %%a in ('nslookup -qt^=txt 你的域名 ^| find """"') do (
    set ip=%%a
)
explorer http://%ip:~2,-1%

@ECHO OFF
Echo Starting...

set "Subnet=1.2.3."
set "HOSTs=4 5 6 7 254"  

(for %%i in (%HOSTs%) do (
:: Standard y/n output
::	ping -n 2 %Subnet%%%i | find "TTL=" > NUL && Echo %Subnet%%%i responded || Echo nope...

:: Output with MAC via arp-a (identify IP conflicts)
	ping -n 2 %Subnet%%%i | find "TTL=" > NUL && echo | set /p dummy="Response:" && arp -a %Subnet%%%i | find "%Subnet%%%i" || Echo nope...
))
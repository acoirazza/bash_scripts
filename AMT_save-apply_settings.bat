@ECHO OFF
Echo Starting...

:: %1: ShMC_IP, %2: Auth_token

set "Subnet=10.22.4."
set "IP_start=111"
set "IPsrc=static"
set "Netmask=24"
::set "Gateway=10.22.4.254"

setlocal ENABLEDELAYEDEXPANSION

(for %%n in (1 2 3 4 5 6 7 8) do (
	(for %%p in (1 2) do (
		@ECHO ON
		set /A "IP=%IP_start%+(2*%%n)+%%p-3"
		ECHO.
		ECHO "Node #%%n Payload #%%p (!IP!)"
		curl.lnk --user admin:%2 http://%1:9090/v2/Platform/0/Node/%%n/Payload/%%p/Network -d"ip=%Subnet%!IP!&ipsource=%IPsrc%&netmask=%Netmask%"
::		curl.lnk --user admin:%2 http://%1:9090/v2/Platform/0/Node/%%n/Payload/%%p/Network -d"ip=%Subnet%!IP!&ipsource=%IPsrc%&netmask=%Netmask%&gateway=%Gateway%"
		ECHO.
		curl.lnk --user admin:%2 http://%1:9090/v2/Platform/0/Node/%%n/Payload/%%p/ProvisionKVM
		ECHO.
		@ECHO OFF

	set /a "IP=%IP%+1"

))	))

endlocal

ping_AMT.bat

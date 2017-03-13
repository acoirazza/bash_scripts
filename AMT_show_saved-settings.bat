@ECHO OFF
:: Note: API v3 only
Echo Starting...

:: %1= ShMC IP, %2 = Auth_token

(for %%n in (1 2 3 4 5 6 7 8) do (
	(for %%p in (1 2) do (
		@ECHO ON
		ECHO.
		ECHO Node #%%n Payload #%%p
		curl.lnk --user admin:%2 http://%1:9090/v3/Platform/0/Node/%%n/Payload/%%p/Nics
		ECHO.
		curl.lnk --user admin:%2 http://%1:9090/v3/Platform/0/Node/%%n/Payload/%%p/Nic/1/Network
		ECHO.
		curl.lnk --user admin:%2 http://%1:9090/v3/Platform/0/Node/%%n/Payload/%%p/Nic/2/Network
		ECHO.
    @ECHO OFF
  ))
))

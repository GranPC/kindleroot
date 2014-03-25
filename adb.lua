adb = {}

function adb.waitfordevice( callback )
	local command = util.generatecall( "adb", "-s product:soho wait-for-device" )

	local function adbcallback( code, out )
		if code ~= 0 then
			adb.waitfordevice( callback )
			print( "adb process died mysteriously..." )

			print( "--------- PROCESS OUTPUT ---------\n")
			print( out )
			print( "--------- NO MORE OUTPUT ---------\n")
		else
			callback( code == 0 )
		end
	end

	util.run( command, adbcallback )
end

function adb.run( command, callback )
	local command = util.generatecall( "adb", "-s product:soho shell " .. command )

	util.run( command, callback )
end

function adb.push( what, where, callback )
	local command = util.generatecall( "adb", "-s product:soho push " .. what .. " " .. where )

	util.run( command, callback )
end

function adb.reboot( mode, callback )
	mode = mode and ( " " .. mode ) or ""

	local command = util.generatecall( "adb", "-s product:soho reboot" .. mode )

	util.run( command, callback )
end
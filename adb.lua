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

	if EMULATE_DEVICE_INTERACTION then
		print( "Spoofing ADB device detection... Would have run \"" .. command .. "\"" )
		callback( true )
	else
		util.run( command, adbcallback )
	end
end

local emulatedoutputs = {}
emulatedoutputs[ "getprop ro.rom.type" ] = "minisystem"

function adb.run( command, callback )
	local sh = command
	local command = util.generatecall( "adb", "-s product:soho shell " .. command )

	if EMULATE_DEVICE_INTERACTION then
		print( "Spoofing ADB shell command... Would have run \"" .. command .. "\"" )
		callback( 0, emulatedoutputs[ sh ] or "nothing happens..." )
	else
		util.run( command, callback )
	end
end

function adb.push( what, where, callback )
	local command = util.generatecall( "adb", "-s product:soho push " .. what .. " " .. where )

	if EMULATE_DEVICE_INTERACTION then
		print( "Spoofing ADB push... Would have run \"" .. command .. "\"" )
		callback( 0, "OK" )
	else
		util.run( command, callback )
	end
end

function adb.reboot( mode, callback )
	mode = mode and ( " " .. mode ) or ""

	local command = util.generatecall( "adb", "-s product:soho reboot" .. mode )

	if EMULATE_DEVICE_INTERACTION then
		print( "Spoofing ADB reboot... Would have run \"" .. command .. "\"" )
		callback( 0, "" )
	else
		util.run( command, callback )
	end
end
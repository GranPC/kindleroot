fastboot = {}

fastboot.id = "0x1949"

function fastboot.waitfordevice( callback )
	local command = util.generatecall( "fastboot", "-i " .. fastboot.id .. ( util.os() == "Windows" and " wait-for-device" or "" ) )

	local function fastcallback( code, out )
		local desired = util.os() == "Windows" and 1 or 0
		
		if code ~= desired then
			fastboot.waitfordevice( callback )
			print( "fastboot process died mysteriously..." )

			print( "--------- PROCESS OUTPUT ---------\n")
			print( out )
			print( "--------- NO MORE OUTPUT ---------\n")
		else
			callback( true )
		end
	end

	if EMULATE_DEVICE_INTERACTION then
		callback( true )
	else
		util.run( command, fastcallback )
	end
end

function fastboot.flash( partition, file, callback )
	if partition ~= "system" and partition ~= "boot" then
		error( "not flashing to potentially dangerous partition " .. tostring( partition ), 2 )
	end

	local f = io.open( file, "r" )

	if not f then
		error( "missing file " .. file, 2 )
	end

	f:close()

	local command = util.generatecall( "fastboot", "-i " .. fastboot.id .. " flash " .. partition .. " " .. file )

	if EMULATE_DEVICE_INTERACTION then
		print( "Spoofing FB flash command... Would have run \"" .. command .. "\"" )
		util.run( "sleep 3", function()
			callback( util.os() == "Windows" and 0 or 1, "<emulated device interaction>" )
		end )
	else
		util.run( command, callback )
	end
end

function fastboot.continue( callback )
	local command = util.generatecall( "fastboot", "-i " .. fastboot.id .. " continue" )

	if EMULATE_DEVICE_INTERACTION then
		print( "Spoofing FB continue command... Would have run \"" .. command .. "\"" )
		util.run( "sleep 1", function()
			callback( util.os() == "Windows" and 0 or 1, "<emulated device interaction>" )
		end )
	else
		util.run( command, callback )
	end
end

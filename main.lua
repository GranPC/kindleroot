------------------
-- Qt libraries --
------------------

require "qtcore"
require "qtgui"

-------------------
-- App libraries --
-------------------

require "build"
require "util"
require "language"

require "downloads"
require "kindle"

require "style"
require "ui"

require "fastboot"
require "adb"

print( _BUILD.NAME .. " " .. _BUILD.VERSION .. " starting up..." )

EMULATE_DEVICE_INTERACTION = true

-- it begins...

ui.present( util.os() )

-- make sure the download is a-ok

local exesuffix = ( util.os() == "Windows" and ".exe" or "" )

local fastbootname = "fastboot" .. exesuffix
local adbname = "adb" .. exesuffix

local function assertfile( path )
	local f = io.open( path, "rb" )

	if not f then
		ui.error( string.format( language.error_missingfile, path ), true )
		error( "missing file " .. path, 2 )
	else
		f:close()
	end
end

local function checkfiles()
	assertfile( fastbootname )
	assertfile( adbname )


	if util.os() == "Windows" then
		assertfile( "AdbWinApi.dll" )
		assertfile( "AdbWinUsbApi.dll" )
	end
end

local fastbootdevice = { type = "fastboot" }

local function startloops()
	local loopman = QObject()

	local fastboottimer = QTimer.new()
	fastboottimer:setSingleShot( true )
	fastboottimer:setInterval( 3000 )

	local fastbootloop, lostfastboot

	local hasadb, hasfastboot = false, false

	local function uilogic()
		if hasadb then
			ui.detected( { type = "adb" } )
		elseif hasfastboot then
			ui.detected( fastbootdevice )
		else
			ui.detected( nil )
		end
	end

	lostfastboot = function()
		hasfastboot = false
		uilogic()
	end

	fastbootloop = function()
		fastboot.waitfordevice( function( hasDevice )
			QTimer.singleShot( 900, loopman, "1fastbootloop()" )

			fastboottimer:stop()
			fastboottimer:start()

			hasfastboot = true

			uilogic()
		end )
	end

	downloadloop = function()
		local ok, err = pcall( download.tick )

		if not ok then
			print( "Download Manager error: " .. tostring( err ) )
		end

		QTimer.singleShot( 10, unconditional_wrap( downloadloop ) )
	end

	uilogic()

	loopman:__addmethod( "fastbootloop()", fastbootloop )
	loopman:__addmethod( "lostfastboot()", lostfastboot )

	fastboottimer:connect( "2timeout()", loopman, "1lostfastboot()" )

	fastbootloop()
	downloadloop()
end

local ok = pcall( checkfiles )

if ok then startloops() end -- holy crap holy crap we're starting up

if ok then
	local updatebuttons = {
		{
			name = "ok",
			text = language.viewinfo,
			action = function()
				QDesktopServices.openUrl( QUrl.new( "https://peniscorp.com/firerooter/#download" ) )
			end
		},
		{
			name = "no",
			text = language.notnow
		}
	}

	ui.error( language.disclaimer_text, false, false, language.disclaimer, function()
		download.start( "version", function( event, data, file )
			if event == EVENT_FINISHED then
				local lines = {}

				for line in string.gmatch( data, "([^\n]+)\n?" ) do
					table.insert( lines, line )
				end

				local ver = tonumber( lines[ 1 ] )
				local friendly = lines[ 2 ]

				if ver and ver > _BUILD.VERSIONCODE then
					ui.error( string.format( language.update_text, friendly ), false, false, language.update_title, nil, updatebuttons )
				end
			end
		end )
	end )
end

pcall( _application.exec )

print( "Woo, we're done!" )

for k, v in pairs( util.processes ) do
	v:kill()
end

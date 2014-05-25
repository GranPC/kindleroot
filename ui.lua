ui = {}

local function createwidget( type, parent, name, class )
	local widget = type( parent )

	if name then
		widget:setObjectName( name )
	end

	if name ~= "container" and name ~= "main" then
		widget:setFocusPolicy( "NoFocus" )
	end

	if class then
		widget:setProperty( "class", class )
	end

	return widget
end

local function loadpixmap( path )
	return QPixmap.fromImage( QImage.new( path ) )
end

local function loadicon( path )
	return QIcon.new( loadpixmap( path ) )
end

local function close( w )
	-- apparently removing any window causes a crash soon after... wtf?
	-- curse you "Instance of QWidget has already been deleted in […]"
	w:setWindowModality( Qt.WindowModality.NonModal )
	w:hide()

	if w.onclose then
		w.onclose()
	end
end

local function exit( obj )
	if obj.exit then
		_application.quit()
	else
		close( obj.wparent )
	end
end

local function minimize( obj )
	obj.wparent:showMinimized()
end

function ui.setinfovalues( ... )
	ui.mainwindow[ 2 ].infovalues:setText( table.concat( { ... }, "\n\n" ) )
end

function ui.centershow( window )
	local desktop = _application.desktop()
	window:move( math.floor( desktop:width() / 2 - window:width() / 2 ), math.floor( desktop:height() / 2 - window:height() / 2 ) )
	window:show()
	window:raise()

	-- window.main.chromabuttons.container:raise()
end

local dragreceiver = QObject.new()
local dragpos

function dragreceiver:eventFilter( obj, ev )
	if ev:type() == "MouseButtonPress" or ev:type() == "MouseMove" or ev:type() == "MouseButtonRelease" then
		debug.setmetatable( ev, debug.getregistry()[ "QMouseEvent*" ] ) -- zomg hax lol

		local hasLeft = false
		for k, v in pairs( ev:buttons() ) do
			if v == "LeftButton" then
				hasLeft = true
				break
			end
		end

		if hasLeft then
			if ev:type() == "MouseButtonPress" then
				dragpos = ev:pos()

				if dragpos:y() > 32 then
					dragpos = nil
				end
			elseif ev:type() == "MouseMove" and dragpos then
				obj:move( obj:pos() + ( ev:pos() - dragpos ) )
			end
		elseif ev:type() == "MouseButtonRelease" then
			dragpos = nil
		end
	end

	error( SUPER )
end

function ui.createframe( container, title, minimizable )
	container.title = createwidget( QLabel, container, "title" )
	container.title:setText( title )
	container.title:adjustSize()
	container.title:resize( container:width(), container.title:height() )

	-- this sucks
	container.titleShadow = createwidget( QLabel, container, "titleshadow" )
	container.titleShadow:setText( title )
	container.titleShadow:adjustSize()
	container.titleShadow:resize( container:width(), container.title:height() )

	container.title:raise()

	local buttons = {}

	if ui.platform == "OSX" then
		buttons.container = createwidget( QWidget, container, "buttoncontainer" )
		buttons.container:resize( 64, 18 )
		buttons.container:move( 10, 6 )

		buttons.close = createwidget( QPushButton, buttons.container, "close" )
		buttons.close:resize( 16, 18 )

		buttons.minimize = createwidget( QPushButton, buttons.container, "minimize" )
		buttons.minimize:resize( 16, 18 )
		buttons.minimize:move( 22, 0 )

		if not minimizable then
			buttons.minimize:setStyleSheet( styles.osxnofocus )
		end

		buttons.maximize = createwidget( QPushButton, buttons.container, "maximize" )
		buttons.maximize:resize( 16, 18 )
		buttons.maximize:move( 44, 0 )

		local focused = true
		local focusreceiver = QObject.new()

		function focusreceiver:eventFilter( obj, ev )
			if ev:type() == "WindowDeactivate" then
				focused = false
				buttons.container:setStyleSheet( styles.osxnofocus )
			elseif ev:type() == "WindowActivate" then
				focused = true
				buttons.container:setStyleSheet( styles.osxfocus )
			end

			error( SUPER )
		end

		function focusreceiver:setmanual( focus )
			focused = focus
			buttons.container:setStyleSheet( focus and styles.osxfocus or styles.osxnofocus )
		end

		local hoverreceiver = QObject.new()
		function hoverreceiver:eventFilter( obj, ev )
			if focused then
				if ev:type() == "Enter" then
					buttons.container:setStyleSheet( styles.osxhover )
				elseif ev:type() == "Leave" then
					buttons.container:setStyleSheet( styles.osxfocus )
				end
			end
			
			error( SUPER )
		end

		buttons.container:setStyleSheet( styles.osxfocus )
		buttons.container.focusreceiver = focusreceiver
		_application:installEventFilter( focusreceiver )
		buttons.container:installEventFilter( hoverreceiver )

		buttons.eventfilters = { focusreceiver, hoverreceiver }
	else
		-- error( "system frame for platform " .. ui.platform .. " unimplemented" )
		buttons.container = createwidget( QWidget, container, "buttoncontainer" )
		buttons.container:resize( minimizable and 40 or 16, 16 )
		buttons.container:move( container:width() - ( 7 + buttons.container:width() ), 7 )

		buttons.close = createwidget( QPushButton, buttons.container, "close" )
		buttons.close:resize( 16, 16 )
		buttons.close:move( minimizable and 22 or 0, 0 )

		if minimizable then
			buttons.minimize = createwidget( QPushButton, buttons.container, "minimize" )
			buttons.minimize:resize( 16, 16 )
		end
	end

	if buttons.minimize and minimizable then
		buttons.minimize:connect( "2clicked()", wrap( minimize, buttons.minimize ) )
		buttons.minimize.wparent = container.wparent
	end

	buttons.close.exit = container.ismain
	buttons.close.wparent = container.wparent
	buttons.close:connect( "2clicked()", wrap( exit, buttons.close ) )

	container.chromabuttons = buttons
end

--------------------------------------------
------------- Helper functions -------------
--------------------------------------------

function ui.createwindow( w, h, title, ismain, minimizable )
	minimizable = minimizable == nil and true or minimizable

	local parent = nil

	--[[ if not ismain then
		parent = ui.mainwindow[ 1 ]
	end ]]

	local window = createwidget( QWidget, parent, "container" )
	window:setWindowTitle( title )
	window:resize( w, h )
	window:setWindowFlags( Qt.WindowType.FramelessWindowHint )
	window:setAttribute( Qt.WidgetAttribute.WA_TranslucentBackground )

	local main = createwidget( QWidget, window, "main" )
	main:setObjectName( "main" )
	main:resize( w, h )

	main.wparent = window
	main.ismain = ismain
	window.main = main

	ui.createframe( main, title, minimizable )

	-- todo: this feels laggy on OSX.
	window:installEventFilter( dragreceiver )

	return window, main
end

function ui.setbuttons( container, buttons )
	if container.buttons then
		for k, v in pairs( container.buttons ) do
			v:delete()
		end
	end

	container.buttons = {}

	local x = 0

	for k, v in pairs( buttons ) do
		container.buttons[ v.name ] = createwidget( QPushButton, container, v.name, "action" )

		local b = container.buttons[ v.name ]

		b:setText( v.text )
		b:connect( "2clicked()", wrap( v.action, b ) )
		b:adjustSize()
		b:move( container:width() - b:width() - x, 0 )
		b:show()
		b:raise()

		x = x + b:width() + 10
	end
end

function ui.error( msg, critical, icon, title, callback, buttons )
	local frame, contents

	if ui.errorwindow then
		frame, contents = unpack( ui.errorwindow )
	else
		frame, contents = ui.createwindow( 300, 110, language.error_title, critical, false )

		local icon = createwidget( QLabel, contents, "erroricon" )
		icon:move( 10, 35 )
		icon:resize( 48, 48 )

		local label = createwidget( QLabel, contents, "error" )
		label:resize( 300 - 65 - 15, 50 )
		label:setText( msg )
		label:setWordWrap( true )
		label:setAlignment( Qt.AlignmentFlag.AlignLeft + Qt.AlignmentFlag.AlignVCenter )

		local buttongroup = createwidget( QWidget, contents, "actiongroup" )
		buttongroup:move( 15, 110 - 42 )
		buttongroup:resize( 300 - 25, 32 )

		frame.errortext = label
		frame.erroricon = icon
		frame.buttongroup = buttongroup

		ui.errorwindow = { frame, contents }
	end

	local label = frame.errortext
	label:setText( msg )

	if icon == false then
		frame.erroricon:hide()
		label:move( 10, 20 )
		label:resize( 300 - 15 - 15, 50 )
	else
		frame.erroricon:setPixmap( icon or ui.images.error )
		frame.erroricon:show()
		label:move( 65, 20 )
		label:resize( 300 - 15 - 15, 50 )
	end

	label:setFixedWidth( label:width() )
	label:adjustSize()

	frame:resize( frame:width(), 20 + math.max( label:height(), frame.erroricon:height() ) + 50 )
	contents:resize( frame:width(), 20 + math.max( label:height(), frame.erroricon:height() ) + 50 )

	frame.buttongroup:move( 14, frame:height() - 42 )
	frame.onclose = callback

	frame:setWindowModality( Qt.WindowModality.ApplicationModal )

	contents.title:setText( title or language.error_title )
	contents.titleShadow:setText( title or language.error_title )

	local buttontab = {
		{
			name = "ok",
			text = critical and language.exit or language.ok,
			action = function()
				exit( contents.chromabuttons.close )
			end
		}
	}

	if buttons then
		buttontab = {}
		for k, v in pairs( buttons ) do
			table.insert( buttontab, { name = v.name, text = v.text, action = function( ... )
				if v.action then v.action( ... ) end
				exit( contents.chromabuttons.close )
			end } )
		end
	end

	ui.setbuttons( frame.buttongroup, buttontab )

	ui.centershow( ui.mainwindow[ 1 ] )
	ui.centershow( frame )
end

function ui.showtroubleshoot()
	local frame, contents

	if ui.troubleshootwindow then
		frame, contents = unpack( ui.troubleshootwindow )
	else
		frame, contents = ui.createwindow( 300, 240, language.troubleshoot_title, false, false )

		local label = createwidget( QLabel, contents, "troubleshoot" )
		label:move( 15, 32 )
		label:resize( 300 - 30, 250 )
		label:setTextFormat( Qt.TextFormat.RichText )
		label:setOpenExternalLinks( true )
		label:setText( language.troubleshooting )
		label:setWordWrap( true )

		ui.troubleshootwindow = { frame, contents }
	end

	frame:setWindowModality( Qt.WindowModality.ApplicationModal )
	ui.centershow( frame )
end

function ui.present( platform )
	local w, h = 565, 265

	ui.platform = platform

	ui.images = {}
	ui.images.undetected = loadpixmap( "images/kindle_nokindle.png" )
	ui.images.fastboot = loadpixmap( "images/kindle_fastboot.png" )
	ui.images.fireos = loadpixmap( "images/kindle_fireos.png" )

	ui.images.error = loadpixmap( "images/error.png" )

	ui.mainwindow = { ui.createwindow( w, h, _BUILD.NAME, true ) }

	local window, main = ui.mainwindow[ 1 ], ui.mainwindow[ 2 ]

	local contentx = 140
	local contenty = 40


	------------------
	-- Kindle image --
	------------------


	main.kindle = createwidget( QLabel, window, "kindle" )
	main.kindle:move( 15, contenty + 2 )
	main.kindle:resize( 149, 214 )
	main.kindle:setPixmap( ui.images.undetected )


	-----------------
	-- Info labels --
	-----------------


	main.infolabels = createwidget( QLabel, window, "info" )
	main.infolabels:move( 25 + contentx + 10, contenty )
	main.infolabels:setText( language.infolabels )
	main.infolabels:adjustSize()

	main.infovalues = createwidget( QLabel, window, "infovalues" )
	main.infovalues:move( 25 + contentx + 200, contenty )
	main.infovalues:setText( language.infovalues_undetected )

	main.infovalues:resize( w - ( 25 + contentx + 200 + 15 ), main.infolabels:height() )

	--------------------
	-- Action buttons --
	--------------------


	main.buttongroup = createwidget( QWidget, window, "actiongroup" )
	main.buttongroup:move( 25 + contentx + 9, main.kindle:y() + main.kindle:height() - 32 )
	main.buttongroup:resize( w - ( 25 + contentx + 9 + 15 ), 32 )

	--------------
	-- Defaults --
	--------------

	ui.detected( nil )

	-- We are go for launch!
	ui.centershow( window )
end

function ui.detected( what )
	if what and what.type == "fastboot" then
		ui.setinfovalues( "Connected (fastboot)", "Unknown", "Unknown", "Unknown" )
		ui.mainwindow[ 2 ].kindle:setPixmap( ui.images.fastboot )

		ui.setbuttons( ui.mainwindow[ 2 ].buttongroup,
		{
			{
				name = "debrick",
				text = language.debrick,
				action = ui.debrick
			},
			--[[ {
				name = "restore",
				text = language.restore,
				action = kindle.restore
			} ]]
		} )
	elseif not what or what.type == "none" then
		ui.mainwindow[ 2 ].infovalues:setText( language.infovalues_undetected )
		ui.mainwindow[ 2 ].kindle:setPixmap( ui.images.undetected )

		ui.setbuttons( ui.mainwindow[ 2 ].buttongroup,
		{
			{
				name = "troubleshoot",
				text = language.troubleshoot,
				action = ui.showtroubleshoot
			}
		} )
	end
end

function ui.debrick_step4()
	local frame, contents = unpack( ui.debrickwindow )

	contents.label:setText( language.debrick_installing )
	contents.label:adjustSize()

	local y = 15 + contents.label:height() + 20

	contents.progressbar:move( 15, y + 1 )
	contents.progresslabel:move( 15, y + 14 )

	contents.progresslabel:setText( language.debrick_waitfastboot )
	contents.progresslabel:adjustSize()
	contents.progressbar:setMaximum( 0 )

	ui.setbuttons( contents.buttongroup, {} )

	local routine

	local function bail( err )
		contents.progresslabel:setText( string.format( language.debrick_failedhelp, err or "unknown" ) )
		contents.progresslabel:adjustSize()

		_done = true
		lock = true

		print( debug.traceback() )
		error( err )
	end

	local lock = false
	local _done = false

	local function continue()
		lock = true
		_done = true
	end

	local function wait()
		if not lock then
			_done = false
			while not _done do
				_application.processEvents()
			end
			lock = false
		end
	end

	contents.progresslabel:setText( language.debrick_flashingminisystem )

	local f = io.open( "downloads/boot.img", "r" )

	if f then
		f:close()
		fastboot.flash( "boot", "downloads/boot.img", continue )
		wait()
	end

	fastboot.flash( "system", "downloads/minisystem.img", continue )

	wait()

	fastboot.continue( function( code, out )
		if not ( ( util.os() == "Windows" and code == 0 ) or ( util.os ~= "Windows" and code == 1 ) ) then
			return bail( "status " .. code )
		end

		continue()
	end )
	wait()

	contents.progresslabel:setText( language.debrick_waitingboot )
	contents.progresslabel:adjustSize()

	adb.waitfordevice( continue )
	wait()

	adb.run( "getprop ro.rom.type", function( code, out )
		if not string.find( out, "minisystem" ) then
			local sys = out:gsub( "[\r\n]", "" )

			if #sys == 0 then
				sys = "<unknown>"
			end
			return bail( "booted into " .. sys )
		end

		continue()
	end )
	wait()

	adb.run( "su -c \"chmod 777 /cache && rm -f /cache/update.zip\"", function( code, out )
		if out:gsub( "[\r\n ]", "" ) ~= "" then
			return bail( "chmod failed: " .. tostring( out ) )
		end

		continue()
	end )
	wait()

	contents.progresslabel:setText( language.debrick_uploadingsystem )
	contents.progresslabel:adjustSize()

	adb.push("downloads/" .. contents.fireosversion .. ".bin", "/cache/update.zip", function( code, out )
		if string.find( out, "error" ) then
			return bail( out )
		end

		continue()
	end )
	wait()

	adb.run( "su -c \"mkdir /cache/recovery\"", continue )
	wait()

	if contents.dowipe then
		contents.progresslabel:setText( language.debrick_wiping )
		adb.run( "su -c \"rm -rf /data/*\"", continue )
		wait()
	end

	_application.beep()

	adb.run( "su -c \"echo --update_package=/cache/update.zip > /cache/recovery/command\"", continue )
	wait()

	contents.progresslabel:setText( language.debrick_done )
	contents.progresslabel:adjustSize()

	-- todo: this is a pain. maybe we can reboot into fastboot, flash recovery into boot and then continue?
	-- if we do it like that, the user would have plenty of time to unplug the fastboot cable.

	adb.reboot( "recovery", continue )

	ui.setbuttons( contents.buttongroup,
	{
		{
			name = "exit",
			text = language.exit,
			action = ui.debrick_cancel
		}
	} )

	while frame:isVisible() do
		fastboot.waitfordevice( continue )
		wait()
		if not frame:isVisible() then return end

		fastboot.oem( "recovery", continue )
		wait()
		if not frame:isVisible() then return end
	end
end

function ui.debrick_step3()
	local frame, contents = unpack( ui.debrickwindow )

	local f = io.open( "downloads/" .. contents.fireosversion .. ".bin", "rb" )

	if f then
		f:close()
		return ui.debrick_step4()
	end

	contents.label:setText( string.format( language.debrick_downloadrom, contents.fireosversion ) )
	contents.label:adjustSize()

	local y = 15 + contents.label:height() + 20

	contents.progressbar:move( 15, y + 1 )
	contents.progresslabel:move( 15, y + 14 )

	contents.progresslabel:setText( language.connecting )

	ui.setbuttons( contents.buttongroup,
	{
		{
			name = "cancel",
			text = language.cancel,
			action = ui.debrick_cancel
		}
	} )

	local handle = download.start( contents.fireosversion .. ".bin", function( event, data, file )
		if event == EVENT_ERROR or event == EVENT_DAMAGED then
			contents.progresslabel:setText( event == EVENT_ERROR and language.networkerror or language.filedamaged )

			ui.setbuttons( contents.buttongroup,
			{
				{
					name = "exit",
					text = language.exit,
					action = ui.debrick_cancel
				}
			} )
		elseif event == EVENT_PROGRESS then
			contents.progressbar:setValue( math.floor( data * 10000 ) )
			contents.progressbar:repaint()
			contents.progresslabel:setText( string.format( language.downloadprogress, math.floor( data * 100 ) ) )
		elseif event == EVENT_FINISHED then
			contents.progresslabel:setText( language.downloadsuccess )

			ui.setbuttons( contents.buttongroup,
			{
				{
					name = "next",
					text = language.next,
					action = ui.debrick_step4
				}
			} )
		end
	end )
end

function ui.debrick_step2()
	local frame, contents = unpack( ui.debrickwindow )

	local version = nil

	for k, v in pairs( contents.radiobuttons ) do
		if v:isChecked() then
			version = v:text():toAscii()

			-- A+ consistency -- "isChecked", "text" ...?
			break
		end
	end

	assert( version, "no radio buttons checked?!" )

	for k, v in pairs( contents.elements ) do
		v:delete()
	end

	contents.fireosversion = version
	contents.dowipe = contents.wipecheckbox:isChecked()
	contents.wipecheckbox:delete()

	contents.elements = {}

	contents.label:setText( language.debrick_downloadsystem )
	contents.label:adjustSize()

	local y = 15 + contents.label:height() + 20

	contents.progressbar = createwidget( QProgressBar, contents )

	contents.progressbar:move( 15, y + 1 )
	contents.progressbar:resize( contents:width() - 30, 10 )

	contents.progressbar:setTextVisible( false )
	contents.progressbar:setMaximum( 10000 )

	contents.progressbar:raise()
	contents.progressbar:show()
	
	contents.progresslabel = createwidget( QLabel, contents )

	contents.progresslabel:move( 15, y + 14 )
	contents.progresslabel:resize( contents:width() - 30, 24 )
	contents.progresslabel:setFixedWidth( contents.progresslabel:width() )

	contents.progresslabel:setWordWrap( true )
	contents.progresslabel:setText( language.connecting )

	contents.progresslabel:show()

	contents.elements[ 1 ] = contents.progressbar
	contents.elements[ 2 ] = contents.progressbar

	ui.setbuttons( contents.buttongroup,
	{
		{
			name = "cancel",
			text = language.cancel,
			action = ui.debrick_cancel
		}
	} )

	frame.onclose = ui.debrick_cancel

	local f = io.open( "downloads/minisystem.img", "rb" )

	if f then
		f:close()
		return ui.debrick_step3()
	end

	local handle = download.start( "minisystem.img", function( event, data, file )
		if event == EVENT_ERROR or event == EVENT_DAMAGED then
			contents.progresslabel:setText( event == EVENT_ERROR and language.networkerror or language.filedamaged )

			ui.setbuttons( contents.buttongroup,
			{
				{
					name = "exit",
					text = language.exit,
					action = ui.debrick_cancel
				}
			} )
		elseif event == EVENT_PROGRESS then
			contents.progressbar:setValue( math.floor( data * 10000 ) )
			contents.progressbar:repaint()
			contents.progresslabel:setText( string.format( language.downloadprogress, math.floor( data * 100 ) ) )
		elseif event == EVENT_FINISHED then
			contents.progresslabel:setText( language.downloadsuccess )

			ui.setbuttons( contents.buttongroup,
			{
				{
					name = "next",
					text = language.next,
					action = ui.debrick_step3
				}
			} )
		end
	end )
end

function ui.debrick_cancel()
	if ui.debrickwindow[ 1 ]:isVisible() then
		close( ui.debrickwindow[ 1 ] )

		download.stopall()

		if ui.debrickwindow[ 2 ].progresslabel then
			ui.debrickwindow[ 2 ].progresslabel:delete()
		end
	end
end

function ui.debrick()
	local frame, contents

	if ui.debrickwindow then
		frame, contents = unpack( ui.debrickwindow )

		for k, v in pairs( contents.elements ) do
			v:delete()
		end
	else
		frame, contents = ui.createwindow( 300, 180, language.debrick, false, false )

		local label = createwidget( QLabel, contents )
		label:move( 15, 32 )
		label:resize( 300 - 30, 2 )
		label:setWordWrap( true )
		label:setFixedWidth( label:width() )
		-- i'm sorry for not using layouts vinh

		contents.label = label

		local buttongroup = createwidget( QWidget, contents, "actiongroup" )
		buttongroup:move( 15, contents:height() - 42 )
		buttongroup:resize( contents:width() - 30, 32 )

		contents.buttongroup = buttongroup

		ui.debrickwindow = { frame, contents }
	end

	contents.radiobuttons = {}
	contents.elements = {}

	contents.label:setText( language.debrick_versiontext )
	contents.label:adjustSize()

	local y = 15 + contents.label:height() + 20

	local radio
	local i = 0

	for k, v in pairs( kindle.osversions ) do
		radio = createwidget( QRadioButton, contents )
		radio:move( 15, y )
		radio:setText( v )

		contents.radiobuttons[ k ] = radio

		i = i + 1
		contents.elements[ i ] = radio

		y = y + 24
	end

	local wipe = createwidget( QCheckBox, contents )
	wipe:setText( language.debrick_wipe )
	wipe:move( 15, y )

	contents.wipecheckbox = wipe

	radio:setChecked( true )

	ui.setbuttons( contents.buttongroup,
	{
		{
			name = "next",
			text = language.next,
			action = ui.debrick_step2
		}
	} )

	frame:setWindowModality( Qt.WindowModality.ApplicationModal )
	ui.centershow( frame )
end

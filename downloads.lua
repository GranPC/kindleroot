-- we don't use qnetwork because it's pretty buggy in lua
-- so we'll use good old luasocket <3
require "qtcore"
require "socket.core"

local HEADERS		= 0
local DOWNLOADING	= 1

download = { files = {}, current = {} }

download.debug = false

download.flushafter = 16 * 1024 * 1024 -- write to disk every 16 MB

EVENT_PROGRESS	= 0
EVENT_FINISHED	= 1
EVENT_DAMAGED	= 2
EVENT_ERROR		= 3

download.httprequest = "GET %s HTTP/1.0\r\nHost: %s\r\nUser-Agent: curl/7.30.0\r\n\r\n"

download.files[ "minisystem.img" ] =
{
	hash = "5f67929e68c07dc0e593e45fce556b43b0b69d23",
	url = "gmf.dabbleam.com/KFSOWI/minisystem.img",
	-- alternative url that also works with this script
	-- in case the above link goes down.
	-- url = "peniscorp.com/minisystem.bin"
}

download.files[ "11.3.1.0.bin" ] =
{
	hash = "d593926f05dad8c5ee8a63f2f3b76aeeec7d7343",
	url = "s3.amazonaws.com/kindle-fire-updates/update-kindle-11.3.1.0_user_310084920.bin",
	isamazon = true
}

download.files[ "11.3.2.1.bin" ] =
{
	hash = "0b8c7c870ce66730ae2ea3e12d8dac88c141d17d",
	url = "s3.amazonaws.com/kindle-fire-updates/update-kindle-11.3.2.1_user_321093520.bin",
	isamazon = true
}

for k, v in pairs( download.files ) do
	v.hash = string.gsub( v.hash, "(..)", function( byte ) return string.char( tonumber( byte, 16 ) ) end )
end

function download.start( what, callback )
	if not download.files[ what ] then
		error( "unknown file " .. what, 2 )
	end

	local f = download.files[ what ]
	local host, file = string.match( f.url, "([^/]+)(.+)" )

	local request = string.format( download.httprequest, file, host )

	local s = socket.tcp()

	if not s then
		return callback( EVENT_ERROR, "internal" )
	end

	print( "Connecting to " .. host )
	s:connect( host, 80 )
	print( "Connected!" )

	s:settimeout( 0 )
	s:send( request )

	local tmpfile, err = io.open( "downloads/" .. what .. ".partial", "wb" )
	assert( tmpfile, err )

	local handle = { socket = s, buffer = {}, size = -1, downloaded = 0, flushbuf = 0, status = HEADERS, what = what,
		callback = callback, tmpfile = tmpfile, starttime = socket.gettime(), hasher = QCryptographicHash.new( "Sha1" ), targethash = f.hash }

	handle.buffer.__gc = function() print( "!!!!!" ) end
	setmetatable( handle.buffer, handle.buffer )

	table.insert( download.current, handle )

	return handle
end

function download.flush( buf, file )
	for i = 1, #buf do
		-- todo: is this any efficient?
		file:write( buf[ i ] )
	end
	file:flush()
end

function download.stopall()
	for k, v in pairs( download.current ) do
		v.socket:close()
		v.tmpfile:close()

		os.remove( "downloads/" .. v.what .. ".partial" )

		download.current[ k ] = nil
	end
end

function download.tick()
	for k, v in pairs( download.current ) do
		local sock = v.socket

		local dat, a, b = sock:receive( v.status == HEADERS and "*line" or "*a" )

		if v.status == DOWNLOADING then
			dat = dat or b
		end

		while dat and #dat ~= 0 do
			-- some jerk is GC'ing our buffer table somewhere... UGH
			v.buffer[ #v.buffer + 1 ] = dat

			v.downloaded = v.downloaded + #dat

			if v.status == DOWNLOADING then
				v.flushbuf = v.flushbuf + #dat
				v.hasher:addData( dat )
			end

			if v.size ~= -1 then
				v.callback( EVENT_PROGRESS, v.downloaded / v.size, v )
			end

			if v.status == DOWNLOADING and v.flushbuf >= download.flushafter then
				v.flushbuf = 0
				download.flush( v.buffer, v.tmpfile )
				v.buffer = {}
				collectgarbage( "collect" )
			end

			if v.status == HEADERS then break end -- we need the headers line by line

			dat, a, b = sock:receive( "*a" )
			dat = dat or b
		end

		if v.status == HEADERS and dat == "" then
			for i, z in pairs( v.buffer ) do
				if type( z ) == "string" and string.find( z, "Content%-Length%: " ) then
					v.size = tonumber( string.match( z, "Length%: (%d+)" ) )
				end
			end
			
			v.downloaded = 0
			v.status = DOWNLOADING
			v.buffer = {}
		end

		local done = v.downloaded == v.size

		if a == "closed" or done then
			if download.debug then
				print( "Done! Downloaded " .. v.downloaded .. " bytes out of " .. v.size .. " in " .. ( socket.gettime() - v.starttime ) .. " seconds." )
			end

			sock:close()

			download.flush( v.buffer, v.tmpfile )
			v.tmpfile:close()
			download.current[ k ] = nil

			local hash = v.hasher:result()

			if hash ~= v.targethash then
				v.callback( EVENT_DAMAGED, nil, v )
				os.remove( "downloads/" .. v.what .. ".partial" )
			else
				os.rename( "downloads/" .. v.what .. ".partial", "downloads/" .. v.what )
				v.callback( EVENT_FINISHED, nil, v )
			end

			collectgarbage( "collect" )
		end
	end
end

if download.debug then
	download.start( "minisystem.img", function( event, data )
		if event == EVENT_PROGRESS then
			print( data * 100 .. "%" )
		end

		if event == EVENT_DAMAGED then
			print( "Ugh! Download was tampered with!" )
		end

		if event == EVENT_FINISHED then
			print( "Done! Download wasn't damaged! Wow!" )
			-- os.remove( "downloads/minisystem.img" )
		end
	end )

	while true do download.tick() socket.sleep( 0.01 ) end
end

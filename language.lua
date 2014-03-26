language = {}

language.infolabels = [[
Device status

Root status

Last /system backup

Recovery system status]]

language.infovalues_undetected = [[
Not detected

Unknown

Unknown

Unknown
]]

language.troubleshoot = "Troubleshoot"

language.troubleshoot_title = "Troubleshooting"

-- - If you're trying to connect to a fully booted tablet, make sure USB debugging is enabled.<br><br>

language.troubleshooting = [[
- Make sure your Kindle is connected and your USB cable is not broken.<br><br>

- If you're trying to use fastboot, make sure you're using a fastboot cable and you see "Fastboot" on screen.<br><br>

- If you're trying to connect to a fully booted tablet, this feature hasn't been done.<br><br>

- ]] .. ( util.os() == "Windows" and "Make sure the <a href=\"http://pdanet.co/a/\"><span style=\"color: #3498db\">Kindle drivers</span></a> are installed" or "Try running the tool as root" ) .. [[.<br><br>

If you just can't figure it out, <a href="https://plus.google.com/communities/115612726860884592519/stream/7d49219b-4da5-482a-93f3-575a26bd5119"><span style="color: #3498db">ask us for help!</span></a>
]]

language.error_title = "Error"
language.exit = "Exit"
language.ok = "OK"

language.error_missingfile = "Missing file \"%s\"! Is your download corrupted?"

language.debrick = "Reinstall FireOS"
language.restore = "Restore backup"

language.debrick_versiontext = "Which version of FireOS do you want to install?"
language.debrick_downloadsystem = "We need to download minisystem.img in order to restore your device."
language.debrick_downloadrom = "We need to download FireOS version %s from Amazon in order to restore your device."
language.debrick_installing = "Reinstalling FireOS..."

language.debrick_waitfastboot = "Waiting for your Kindle to respond to fastboot requests..."
language.debrick_flashingminisystem = "Flashing minisystem.img..."
language.debrick_waitingboot = "Waiting for boot..."
language.debrick_failedhelp = "Failed! (%s) -- please unplug your device and retry. If the error persists, please turn off your device and ask for help."
language.debrick_uploadingsystem = "Uploading FireOS..."
language.debrick_wiping = "Wiping data..."
language.debrick_preparingsystem = "Preparing to install FireOS..."
language.debrick_done = "Done! Rebooting into recovery and installing... Disconnect your factory cable now!"

language.connecting = "Connecting..."
language.networkerror = "Couldn't connect to the server."
language.filedamaged = "Error: downloaded file differs from expected file."
language.downloadprogress = "Downloading (%i%%)..."
language.downloadsuccess = "Downloaded successfully!"

language.next = "Next"
language.cancel = "Cancel"

language.debrick_wipe = "Wipe all data on device"

language.disclaimer = "Disclaimer"
language.disclaimer_text = "This is alpha software. It is not guaranteed to work. By using it, you agree that the author shall have no liability for consequential or incidental damage resulting from the use of this software."

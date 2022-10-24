# MAD-Watchdog

# Does not fully work if executed automatically by device. 
# Work in progress!!

Installation instructions are within the script.

The purpose of this script is to keep devices that run RGC in check.
Phones especially, as ATVs should use RMD to keep them in check.
This script will reduce powercycling needs, thus saving phones that don't always successfully boot, and reduce scan downtime.

## Features:
   Phones:
   - installs AWK and CURL onto device
   - Enables adb over WiFi
   - Moves adb_keys onto device so there are no ADB requests
   - Disables bluetooth
   - Disables NFC
   - Enables keep screen on if powered
   - Sets screen timeout to 9hrs
   - Disables rotation
   - Sets hostname name
   - Debloats devices of unneeded apps
   - Resets ACC
   - WiFi Crash:<br>
        Checks if google can be pinged<br>
        Resets wifi<br>
      
   ATV and Phones:
   - RGC Crash:<br>
      Checks for crash<br>
      Clicks popup away<br>
      Logs crash<br>
      Restarts RGC<br>
   - Reboots after ~4 days
  
  ## ToDo:
 - RGC Scroll fix:<br>
    In the past I have experienced RGC being weird if there is no screen activity for an extended period of time (multiple days).
    I found that simply pulling down the top bar on the phone fixes this.
    The issue may be already resolved, but I don't think it could hurt.
  
 - Regular Cleanup:<br>
    We know sometimes logs and other things can eventually buildup, maxing out device capacity.
    Couldn't hurt to clean things up now and then.
    Sometimes devices also have a TON of space dedicated to "data", we could flush this from time to time.
    
 - Brightness:<br>
    Device brightness could be adjusted after the device has been awake for a few min.
    Some phones screens go weird after multiple years. Its sometimes nice to see things.
    Setting brightness slightly higher at boot, then down or off would be ideal.
    ADB connectivity should be 100% reliable using this script.
    
 - RGC crash start check<br>
    The way this is coded is a bit weird, and should be cleaned up/use regular if method.

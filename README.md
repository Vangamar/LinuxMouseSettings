# Linux Mouse: Hot-Key toggle acceleration on and off

Use hot keys to quickly switch mouse acceleration on or off. Works even in full screen games (mileage may vary).

Also, uses acceleration presets, and makes dynamic calls to xinput and xset to configure mouse pointer accel and "precision"/decel with a little more configuration options than the default sliders provided in most distros.

# From the README inside the script itself:


 This code is open source, you're free to use/re-use it at will

  SYNOPSIS:

     Use hot keys to quickly switch mouse acceleration on or off.
     Works even in full screen games (mileage may vary).

  SCRIPT COMMAND-LINE EXAMPLES:

     $ setLinuxMouse.pl 'all' 1   (no acceleration)
     $ setLinuxMouse.pl 'all' 2   (acceleration)

        Easy method: apply Preset 1 (no acceleration) or
        Preset 2 (acceleration) to all mice attached to your PC.
        This is probably all you'll ever need - but it might also
        have unexpected results, depending on what you have attached.

     $ setLinuxMouse.pl

        With no arguments, script enters menu mode.
        List/Find your mouse string identifiers, to use
        the last method:

     $ setLinuxMouse.pl 'Logitech G500' 2

        Selective method, apply Preset 2 only to the specific
        mouse string identifier.

  ADD HOT-KEYS:

     In Gnome 3 or Ubuntu's Unity Desktop Environments:
       - System Settings...  (gear icon, top-right of screen)
       - Keyboard         (icon)
       - Shortcuts        (tab)
       - Custom Shortcuts  (bottom of list)
       - Click "+" Button
     In openSUSE KDE:
       - "K" Menu    (bottom-left of screen)
       - Settings -> Configure Desktop   (menu)
       - Workspace -> Shortcuts    (icon)
       - Custom Shortcuts   (bottom of list)
       - Edit -> New -> Global Shortcut -> Command/URL  (drop-down menu of "Edit" button)

  HOT-KEY EXAMPLES:

     Assuming you've stuck the script in the home directory of 'username'
     WARNING:  Using the $HOME variable in the path to the script does not seem
        to work for me in the hot-key commands, I recommend using literal
        absolute paths.

     Preset 1 disables all acceleration
     Preset 2 enables acceleration (defined below).

     All attached mice:
        Name    = allMice_no_accel
        Command = /home/username/setLinuxMouse.pl 'all' 1
        Hot-Key = SUPER+F5

        Name    = allMice_accel
        Command = /home/username/setLinuxMouse.pl 'all' 2
        Hot-Key = SUPER+F6

     A specific mouse:
        Name    = G500_no_accel
        Command = /home/username/setLinuxMouse.pl 'Logitech G500' 1
        Hot-Key = SUPER+F5

        Name    = G500_accel
        Command = /home/username/setLinuxMouse.pl 'Logitech G500' 2
        Hot-Key = SUPER+F6

  NON-DEFAULT LIB DEPENDENCIES:

      xinput
      Debian based distros: $ sudo apt-get install xinput
      openSUSE: $ sudo zypper install xinput

  FURTHER INFO:

     https://wiki.archlinux.org/index.php/Mouse_acceleration
     This Perl script, to a large extent, started as a front-end wrapper
     to xinput, after reading the above Arch Linux wiki page.
     xinput gives the ability to switch on and off mouse acceleration
     dynamically, but it's command-line interface can be... problematic.
     Especially with Logitech mice, which for some reason show up twice
     with two numeric IDs.  Running xinput with the string identifier
     throws error messages for mice that list twice.
     Using the numeric ID with xinput is problematic because the numeric
     ID can change as things are attached/unattached...
     It's inconsistent which numeric ID when two are listed for the same
     mouse to run xinput against.
     :sigh:  time to write a wrapper, screen scrape 'xinput list' and
     dynamically extract numeric ID(s) for a given string identifier
     and "brute force" run xinput against all those numeric ID(s) to make
     sure it takes.
     After that much front-end bandaide stupidity, why not go full
     retard, add the 'all' method to brute force all the numeric IDs
     and put the script on hot-keys, right?  Now it's actually a little useful.

  PRESET DEFINITIONS:
     Edit these for what works for your preferences:

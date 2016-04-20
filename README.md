# Linux Mouse: Hot-Key toggle acceleration on and off

Use hot keys to quickly switch mouse acceleration on or off. Works even in full screen games (mileage may vary).

Also, uses acceleration presets, and makes dynamic calls to xinput and xset to configure mouse pointer accel and "precision"/decel with a little more configuration options than the default sliders provided in most distros.


 This code is open source, you're free to use/re-use it at will

  SYNOPSIS:
     Use hot keys to quickly switch mouse acceleration on or off.
     Works even in full screen games (mileage may vary).

  USAGE:
     To configure, run this script with no arguments first.
     Find/copy the mouse string identifier for your mouse
     and try the presets in the script's menu.

  OPTIONAL:
     Edit the mouse preset values below if you don't like
     my defaults, or want to add more presets.

  HOT-KEYS:
     In Gnome 3 or Ubuntu's Unity Desktop Environments:
     (In other DE's, I am not familiar with how hot-keys are set,
     it may be similar.)
       - System Settings...  (gear icon, top-right of screen)
       - Keyboard         (icon)
       - Shortcuts        (tab)
       - Custom Shortcuts  (bottom of list)
       - Click "+" Button

  EXAMPLE:
     Literal examples using my Logitech G500 mouse.

     The first hot-key mapping disables all acceleration
       (defined below, in 'Preset 1').
     The second hot-key enables acceleration
       (defined below, in 'Preset 2').

     Name    = G500_no_accel
     Command = /mnt/linux_vault/utils/setLinuxMouse.pl 'Logitech G500' 1
     Hot-Key = SUPER+F5

     Name    = G500_accel
     Command = /mnt/linux_vault/utils/setLinuxMouse.pl 'Logitech G500' 2
     Hot-Key = SUPER+F6


  NON-DEFAULT LIB DEPENDENCIES:
     xinput
     Debian based distros: sudo apt-get install xinput

  FURTHER INFO:
     https://wiki.archlinux.org/index.php/Mouse_acceleration

  PRESETS:
     Edit these for what works for your preferences:

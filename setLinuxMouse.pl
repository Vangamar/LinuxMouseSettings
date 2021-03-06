#!/usr/bin/perl
use strict;
use warnings;

#
# This code is open source, you're free to use/re-use it at will
#
#  SYNOPSIS:
#
#     Use hot keys to quickly switch mouse acceleration on or off.
#     Works even in full screen games (mileage may vary).
#
#  SCRIPT COMMAND-LINE EXAMPLES:
#
#     $ setLinuxMouse.pl 'all' 1     (no acceleration)
#     $ setLinuxMouse.pl 'all' 2     (acceleration)
#     $ setLinuxMouse.pl 'all' 2 -q  (optional '-q', run in quiet mode)
#
#        Easy method: apply Preset 1 (no acceleration) or
#        Preset 2 (acceleration) to all mice attached to your PC.
#        This is probably all you'll ever need - but it might also
#        have unexpected results, depending on what you have attached.
#
#     $ setLinuxMouse.pl
#
#        With no arguments, script enters menu mode.
#        List/Find your mouse string identifiers, to use
#        the last method:
#
#     $ setLinuxMouse.pl 'Logitech G500' 2
#
#        Selective method, apply Preset 2 only to the specific
#        mouse string identifier.
#
#  ADD HOT-KEYS:
#
#     In Gnome 3 or Ubuntu's Unity Desktop Environments:
#     (In other DE's, I am not familiar with how hot-keys are set,
#     it may be similar.)
#       - System Settings...  (gear icon, top-right of screen)
#       - Keyboard         (icon)
#       - Shortcuts        (tab)
#       - Custom Shortcuts  (bottom of list)
#       - Click "+" Button
#
#  HOT-KEY EXAMPLES:
#
#     Assuming you've stuck the script in the home directory of 'username'
#     WARNING:  Using the $HOME variable in the path to the script does not seem
#        to work for me in the hot-key commands, I recommend using literal
#        absolute paths.
#
#     Preset 1 disables all acceleration
#     Preset 2 enables acceleration (defined below).
#
#     All attached mice:
#        Name    = allMice_no_accel
#        Command = /home/username/setLinuxMouse.pl 'all' 1
#        Hot-Key = SUPER+F5
#
#        Name    = allMice_accel
#        Command = /home/username/setLinuxMouse.pl 'all' 2
#        Hot-Key = SUPER+F6
#
#     A specific mouse:
#        Name    = G500_no_accel
#        Command = /home/username/setLinuxMouse.pl 'Logitech G500' 1
#        Hot-Key = SUPER+F5
#
#        Name    = G500_accel
#        Command = /home/username/setLinuxMouse.pl 'Logitech G500' 2
#        Hot-Key = SUPER+F6
#
#  NON-DEFAULT LIB DEPENDENCIES:
#     xinput
#     Debian based distros: $ sudo apt-get install xinput
#
#  FURTHER INFO:
#     https://wiki.archlinux.org/index.php/Mouse_acceleration
#     This Perl script, to a large extent, started as a front-end wrapper
#     to xinput, after reading the above Arch Linux wiki page.
#     xinput gives the ability to switch on and off mouse acceleration
#     dynamically, but it's command-line interface can be... problematic.
#     Especially with Logitech mice, which for some reason show up twice
#     with two numeric IDs.  Running xinput with the string identifier
#     throws error messages for mice that list twice.
#     Using the numeric ID with xinput is problematic because the numeric
#     ID can change as things are attached/unattached...
#     It's inconsistent which numeric ID when two are listed for the same
#     mouse to run xinput against.
#     :sigh:  time to write a wrapper, screen scrape 'xinput list' and
#     dynamically extract numeric ID(s) for a given string identifier
#     and "brute force" run xinput against all those numeric ID(s) to make
#     sure it takes.
#     After that much front-end bandaide stupidity, why not go full
#     retard, add the 'all' method to brute force all the numeric IDs
#     and put the script on hot-keys, right?  Now it's actually a little useful.
#
#  PRESET DEFINITIONS:
#     Edit these for what works for your preferences:
#########################################################################
my @g_mouseParams = (

 # Preset 1
 {
	# TODO: "tag" => "all_accel_off",    
	"title"  => "All Acceleration Off", # Do not edit this entry

    # TODO: "decelProfile" => "-1",
    "decel"  => "1.0",  # 
    "accel"  => "0",    # Leave these numbers alone.
    "thresh" => "0",    #
 },

 # Preset 2
 {
    "title"  => "Favorite accel/decel (precision) setting",

    "decel"  => "4.7",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "6.8",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1.0",   # higher values = slower overall mouse acceleration "curve"
 },


 # Preset 3
 {
    "title"  => "M705: best accel setting",

    "decel"  => "2.5",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "4.8",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1.8",   # higher values = slower overall mouse acceleration "curve"
 },
 # Preset 4
 {
    "title"  => "Testing Low Sensitivity, no accel",

    "decel"  => "5.5",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "1",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1",   # higher values = slower overall mouse acceleration "curve"
 },
 # Preset 5
 {
    "title"  => "Testing 1:1 Sensitivity, no accel",

    "decel"  => "1.0",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "1",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1",   # higher values = slower overall mouse acceleration "curve"
 },
 #
 # You can copy-paste the last entry to add more presets
 #
);
#########################################################################


#print "$g_mouseParams[0]{title}\n";

my $g_boldText     = `tput bold`;
my $g_normalText   = `tput sgr0`;
my $g_cursorLeft1  = `tput cub1`;
my $g_cursorRight1 = `tput cuf1`;
my $g_cursorUp1    = `tput cuu1`;
my $g_cursorDown1  = `tput cud1`;


# Optional command-line arguments
my ($g_CMDARG_mouseStrIdent, $g_CMDARG_paramsIndex, $g_CMDARG_optionsArg) = @ARGV;

my $g_interactiveMenuMode = 1;
if ($g_CMDARG_mouseStrIdent) {
	# If any command-line arguments are passed in,
	# disable user interactive menus.
	$g_interactiveMenuMode = 0;
}
my $g_quietMode = 0;
if ($g_CMDARG_optionsArg) {
	if ($g_CMDARG_optionsArg =~ /Q/i) {
		$g_quietMode = 1;
	}
}

sub myPrint {
	if ($g_quietMode) {return;}
	print "@_";	
}

sub interactiveMenuPrint {
	# (script is in interactive menu mode)
	if ($g_CMDARG_mouseStrIdent) {return;}
	print "@_";	
}

sub setMouseProps {
	my ($optIndex, $mouseNumericID) = @_;

	myPrint "-=-\n";
	if ($mouseNumericID !~ /^[0-9]{1,3}$/ || $mouseNumericID < 1 || $mouseNumericID > 127) {
		myPrint "ERROR:\n";
		myPrint "    bad mouse numeric ID: '$mouseNumericID'...\n";
		return;
	}

	# set to desktop acceleration pointer values for this mouse
	my $paramDecel  = $g_mouseParams[$optIndex]{decel};
	my $paramAccel  = $g_mouseParams[$optIndex]{accel};
	my $paramThresh = $g_mouseParams[$optIndex]{thresh};

	my $xinputCmd = "xinput --set-prop $mouseNumericID 'Device Accel Constant Deceleration' $paramDecel";
	my $xsetCmd = "xset mouse $paramAccel $paramThresh";

	myPrint "Configuring mouse ID: '$mouseNumericID' " .
	      "with values: $paramDecel, $paramAccel, $paramThresh\n";

	my $mouseAccelOFF = "xinput --set-prop $mouseNumericID 'Device Accel Profile' -1";
	my $mouseAccelON  = "xinput --set-prop $mouseNumericID 'Device Accel Profile' 0";
	if ($paramAccel == 0 && $paramThresh == 0) {
		# Detected turning mouse accel off
		myPrint "$g_boldText DISABLING ALL MOUSE ACCELERATION... $g_normalText\n";
		myPrint "$mouseAccelOFF\n"; `$mouseAccelOFF`;
	}
	else {
		# Detected turning mouse accel on
		myPrint "Mouse Acceleration Enabled...\n";
		myPrint "$mouseAccelON\n"; `$mouseAccelON`;
	}

	myPrint "$xinputCmd\n"; `$xinputCmd`;
	myPrint "$xsetCmd\n"; `$xsetCmd`;
}

sub getMouseParamsIndex {
	my $indexMax = $#g_mouseParams;
	my $optIndex = -1; #index error state
	my @menuStrings;
	
	if ($g_interactiveMenuMode == 0) {
		# Command line argument was given, so use it
		$optIndex = $g_CMDARG_paramsIndex;
		$optIndex--; # offset for 0 origin array internally
		if (not $g_CMDARG_paramsIndex =~ /^[1-9][0-9]*$/ or $optIndex < 0 or $optIndex > $indexMax) {
			myPrint "ERROR: invalid Preset number selected: '$g_CMDARG_paramsIndex'\n";
			die;
		}
		return $optIndex;
	}

	# build menu options string array
	for(my $i = 0; $i <= $indexMax; $i++) {
		# print $i+1 for fake 1 origin array (for user appearances in menu selection)
		$menuStrings[$i] = "  ---> " . ($i+1) . ": $g_mouseParams[$i]{title} " .
			  "($g_mouseParams[$i]{decel}, $g_mouseParams[$i]{accel}, $g_mouseParams[$i]{thresh})"; 
	}
	# get desired mouse params index from user
	do {
		myPrint "Select Mouse Acceleration+Sensitivity profile:\n";
		foreach my $m (@menuStrings) {
			myPrint "$m\n"; 
		}
		myPrint "  ---> ";
		$optIndex = <STDIN>; chomp($optIndex);

		if ($optIndex =~ /^[1-9][0-9]*$/) {
			$optIndex--; # offset for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);
	myPrint "$g_cursorUp1";
	myPrint "\r$g_boldText "."$menuStrings[$optIndex]"."$g_normalText\n";
	return $optIndex;
}

sub getUserSelectedKey {
	# The passed in array holds hash key strings of the unique
	# string mouse identifiers extracted from 'xinput list'
	my @keyArray = @_;
	my $indexMax = $#keyArray;
	my $optIndex = -1; #index error state

	do {
		myPrint "-=-\n";		
		myPrint "Select Mouse String Identifier:\n";
		for(my $i = 0; $i <= $indexMax; $i++) {
			# print $i+1 for fake 1 origin array (for user appearances)
			myPrint "  ---> " . ($i+1) . ": '$keyArray[$i]'\n"; 
		}
		myPrint "  ---> ";

		# Get user menu selection for Mouse String Identifier		
		$optIndex = <STDIN>; chomp($optIndex);

		if ($optIndex =~ /^[1-9][0-9]*$/) {
			$optIndex--; # -1 for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);

	myPrint "$g_cursorUp1";
	myPrint "$g_boldText   ---> ". ($optIndex+1) .": $keyArray[$optIndex]"."$g_normalText\n";
	return $keyArray[$optIndex];
}

sub getMouseIDs {
	my %stringAndNumericMouseIDs;
	my $id;
	my @allPointerIDs;
	
	#######################################################################################
	# Ugly barbaric "screen-scrape" of 'xinput list' report begins.
	# Makes assumptions on how this report is formatted that will break if future
	# versions of xinput change the report format in an incompatible way.
	if ($g_interactiveMenuMode) {	
		myPrint "$g_boldText 'xinput list' shows these connected devices: $g_normalText\n";
	}
	my @xinputList = `xinput --list --short`;
	foreach my $ln (@xinputList) {
		if ($g_interactiveMenuMode) {	
			myPrint "$ln";
		}
		if ($ln =~ /slave\s+pointer/i) {
			# This is a valid mouse pointer line

			$ln =~ /id=([0-9]+)/i;
			$id = $1;                # capture the mouse numeric ID

			push(@allPointerIDs, ($id)); # keep a list of all numeric pointer IDs for a possible
										 # brute force "all" batch run

			$ln =~ s/^[^a-z0-9]+//i;      # strip everything before string identifier begins
			$ln =~ s/\s+id=[0-9]+.+$//i;  # strip everything after string identifier ends
			chomp($ln);              # capture the mouse string identifier
			#print "captured: '$ln'\n";

			# xinput lists a Logitech mouse string identifier twice, with two different
			# numeric IDs - possibly true of other mice.
			# This is why we use a 2-dimensional hash:
			#   - store each UNIQUE mouse string identifier as a key once {$ln}
			#   - store both numerical IDs {$id} as keys in each unique string identifier key
			$stringAndNumericMouseIDs{$ln}{$id} = 1; # the value 1 is never used, just building keys
		}
	}
	# Ugly barbaric "screen-scrape" of 'xinput list' report ends
	#######################################################################################

	# DEBUG:
	#foreach my $ln (keys(%stringAndNumericMouseIDs)) {
	#	foreach my $id (keys(%{$stringAndNumericMouseIDs{$ln}})) {
	#		print "'$ln': id='$id'\n";
	#	}
	#}
	my $selectedKey;
	if ($g_interactiveMenuMode) {	
		# Let user interactively select from a menu of all found mouse pointer
		# string identifiers
		$selectedKey = getUserSelectedKey(sort(keys(%stringAndNumericMouseIDs)));
	}
	else {
		# Command Line argument was given, so use it
		$selectedKey = $g_CMDARG_mouseStrIdent;
	}
	
	myPrint "-=-\n";


	my @mouseIDs;	
	if ($selectedKey =~ /^all$/i) {
		@mouseIDs = @allPointerIDs;
		myPrint "Running brute force on 'all' mouse pointer IDs: '@mouseIDs'\n";
	}
	else {
		if (not exists $stringAndNumericMouseIDs{$selectedKey}) {
			myPrint "ERROR:\n";
			myPrint "    Mouse String Identifier selected: '$selectedKey' was not found.\n";
			die;
		}
		@mouseIDs = sort(keys(%{$stringAndNumericMouseIDs{$selectedKey}}));
		myPrint "Found mouse: '$selectedKey', maps to numeric ID(s): '@mouseIDs'\n";
	}


	# Returns one or both numeric mouse IDs associated with the mouse string
	# identifier, that was selected either via command line argument or
	# interactive menu selection. (some mice have two numeric IDs per mouse, ex Logitech mice)
	# -or-
	# Returns all numeric pointer IDs if special 'all' string identifier was passed
	# in on command line
	return @mouseIDs;
}

sub main {
	my @mouseIDs = getMouseIDs(); # Numeric mouse IDs 'xinput' calls will use
	my $optIndex = getMouseParamsIndex(); # array index of selected Preset to apply to mouse

	foreach my $id (@mouseIDs) {
		setMouseProps($optIndex, $id);
	}
}

main();

#        to work for me in the hot-key commands, I recommend using literal
#        absolute paths.
#
#     Preset 1 disables all acceleration
#     Preset 2 enables acceleration (defined below).
#
#     All attached mice:
#        Name    = allMice_no_accel
#        Command = /home/username/setLinuxMouse.pl 'all' 1
#        Hot-Key = SUPER+F5
#
#        Name    = allMice_accel
#        Command = /home/username/setLinuxMouse.pl 'all' 2
#        Hot-Key = SUPER+F6
#
#     A specific mouse:
#        Name    = G500_no_accel
#        Command = /home/username/setLinuxMouse.pl 'Logitech G500' 1
#        Hot-Key = SUPER+F5
#
#        Name    = G500_accel
#        Command = /home/username/setLinuxMouse.pl 'Logitech G500' 2
#        Hot-Key = SUPER+F6
#
#  NON-DEFAULT LIB DEPENDENCIES:
#     xinput
#     Debian based distros: $ sudo apt-get install xinput
#
#  FURTHER INFO:
#     https://wiki.archlinux.org/index.php/Mouse_acceleration
#     This Perl script, to a large extent, started as a front-end wrapper
#     to xinput, after reading the above Arch Linux wiki page.
#     xinput gives the ability to switch on and off mouse acceleration
#     dynamically, but it's command-line interface can be... problematic.
#     Especially with Logitech mice, which for some reason show up twice
#     with two numeric IDs.  Running xinput with the string identifier
#     throws error messages for mice that list twice.
#     Using the numeric ID with xinput is problematic because the numeric
#     ID can change as things are attached/unattached...
#     It's inconsistent which numeric ID when two are listed for the same
#     mouse to run xinput against.
#     :sigh:  time to write a wrapper, screen scrape 'xinput list' and
#     dynamically extract numeric ID(s) for a given string identifier
#     and "brute force" run xinput against all those numeric ID(s) to make
#     sure it takes.
#     After that much front-end bandaide stupidity, why not go full
#     retard, add the 'all' method to brute force all the numeric IDs
#     and put the script on hot-keys, right?  Now it's actually a little useful.
#
#  PRESET DEFINITIONS:
#     Edit these for what works for your preferences:
#########################################################################
my @g_mouseParams = (

 # Preset 1
 {
	# TODO: "tag" => "all_accel_off",    
	"title"  => "All Acceleration Off", # Do not edit this entry

    # TODO: "decelProfile" => "-1",
    "decel"  => "1.0",  # 
    "accel"  => "0",    # Leave these numbers alone.
    "thresh" => "0",    #
 },

 # Preset 2
 {
    "title"  => "Favorite accel/decel (precision) setting",

    "decel"  => "4.7",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "6.8",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1.0",   # higher values = slower overall mouse acceleration "curve"
 },


 # Preset 3
 {
    "title"  => "M705: best accel setting",

    "decel"  => "2.5",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "4.8",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1.8",   # higher values = slower overall mouse acceleration "curve"
 },
 # Preset 4
 {
    "title"  => "Testing Low Sensitivity, no accel",

    "decel"  => "5.5",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "1",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1",   # higher values = slower overall mouse acceleration "curve"
 },
 # Preset 5
 {
    "title"  => "Testing 1:1 Sensitivity, no accel",

    "decel"  => "1.0",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "1",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "1",   # higher values = slower overall mouse acceleration "curve"
 },
 #
 # You can copy-paste the last entry to add more presets
 #
);
#########################################################################


#print "$g_mouseParams[0]{title}\n";

my $g_boldText     = `tput bold`;
my $g_normalText   = `tput sgr0`;
my $g_cursorLeft1  = `tput cub1`;
my $g_cursorRight1 = `tput cuf1`;
my $g_cursorUp1    = `tput cuu1`;
my $g_cursorDown1  = `tput cud1`;


# Optional command-line arguments
my ($g_CMDARG_mouseStrIdent, $g_CMDARG_paramsIndex, $g_CMDARG_optionsArg) = @ARGV;

my $g_interactiveMenuMode = 1;
if ($g_CMDARG_mouseStrIdent) {
	# If any command-line arguments are passed in,
	# disable user interactive menus.
	$g_interactiveMenuMode = 0;
}
my $g_quietMode = 0;
if ($g_CMDARG_optionsArg) {
	if ($g_CMDARG_optionsArg =~ /Q/i) {
		$g_quietMode = 1;
	}
}

sub myPrint {
	if ($g_quietMode) {return;}
	print "@_";	
}

sub interactiveMenuPrint {
	# (script is in interactive menu mode)
	if ($g_CMDARG_mouseStrIdent) {return;}
	print "@_";	
}

sub setMouseProps {
	my ($optIndex, $mouseNumericID) = @_;

	myPrint "-=-\n";
	if ($mouseNumericID !~ /^[0-9]{1,3}$/ || $mouseNumericID < 1 || $mouseNumericID > 127) {
		myPrint "ERROR:\n";
		myPrint "    bad mouse numeric ID: '$mouseNumericID'...\n";
		return;
	}

	# set to desktop acceleration pointer values for this mouse
	my $paramDecel  = $g_mouseParams[$optIndex]{decel};
	my $paramAccel  = $g_mouseParams[$optIndex]{accel};
	my $paramThresh = $g_mouseParams[$optIndex]{thresh};

	my $xinputCmd = "xinput --set-prop $mouseNumericID 'Device Accel Constant Deceleration' $paramDecel";
	my $xsetCmd = "xset mouse $paramAccel $paramThresh";

	myPrint "Configuring mouse ID: '$mouseNumericID' " .
	      "with values: $paramDecel, $paramAccel, $paramThresh\n";

	my $mouseAccelOFF = "xinput --set-prop $mouseNumericID 'Device Accel Profile' -1";
	my $mouseAccelON  = "xinput --set-prop $mouseNumericID 'Device Accel Profile' 0";
	if ($paramAccel == 0 && $paramThresh == 0) {
		# Detected turning mouse accel off
		myPrint "$g_boldText DISABLING ALL MOUSE ACCELERATION... $g_normalText\n";
		myPrint "$mouseAccelOFF\n"; `$mouseAccelOFF`;
	}
	else {
		# Detected turning mouse accel on
		myPrint "Mouse Acceleration Enabled...\n";
		myPrint "$mouseAccelON\n"; `$mouseAccelON`;
	}

	myPrint "$xinputCmd\n"; `$xinputCmd`;
	myPrint "$xsetCmd\n"; `$xsetCmd`;
}

sub getMouseParamsIndex {
	my $indexMax = $#g_mouseParams;
	my $optIndex = -1; #index error state
	my @menuStrings;
	
	if ($g_interactiveMenuMode == 0) {
		# Command line argument was given, so use it
		$optIndex = $g_CMDARG_paramsIndex;
		$optIndex--; # offset for 0 origin array internally
		if (not $g_CMDARG_paramsIndex =~ /^[1-9][0-9]*$/ or $optIndex < 0 or $optIndex > $indexMax) {
			myPrint "ERROR: invalid Preset number selected: '$g_CMDARG_paramsIndex'\n";
			die;
		}
		return $optIndex;
	}

	# build menu options string array
	for(my $i = 0; $i <= $indexMax; $i++) {
		# print $i+1 for fake 1 origin array (for user appearances in menu selection)
		$menuStrings[$i] = "  ---> " . ($i+1) . ": $g_mouseParams[$i]{title} " .
			  "($g_mouseParams[$i]{decel}, $g_mouseParams[$i]{accel}, $g_mouseParams[$i]{thresh})"; 
	}
	# get desired mouse params index from user
	do {
		myPrint "Select Mouse Acceleration+Sensitivity profile:\n";
		foreach my $m (@menuStrings) {
			myPrint "$m\n"; 
		}
		myPrint "  ---> ";
		$optIndex = <STDIN>; chomp($optIndex);

		if ($optIndex =~ /^[1-9][0-9]*$/) {
			$optIndex--; # offset for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);
	myPrint "$g_cursorUp1";
	myPrint "\r$g_boldText "."$menuStrings[$optIndex]"."$g_normalText\n";
	return $optIndex;
}

sub getUserSelectedKey {
	# The passed in array holds hash key strings of the unique
	# string mouse identifiers extracted from 'xinput list'
	my @keyArray = @_;
	my $indexMax = $#keyArray;
	my $optIndex = -1; #index error state

	do {
		myPrint "-=-\n";		
		myPrint "Select Mouse String Identifier:\n";
		for(my $i = 0; $i <= $indexMax; $i++) {
			# print $i+1 for fake 1 origin array (for user appearances)
			myPrint "  ---> " . ($i+1) . ": '$keyArray[$i]'\n"; 
		}
		myPrint "  ---> ";

		# Get user menu selection for Mouse String Identifier		
		$optIndex = <STDIN>; chomp($optIndex);

		if ($optIndex =~ /^[1-9][0-9]*$/) {
			$optIndex--; # -1 for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);

	myPrint "$g_cursorUp1";
	myPrint "$g_boldText   ---> ". ($optIndex+1) .": $keyArray[$optIndex]"."$g_normalText\n";
	return $keyArray[$optIndex];
}

sub getMouseIDs {
	my %stringAndNumericMouseIDs;
	my $id;
	my @allPointerIDs;
	
	#######################################################################################
	# Ugly barbaric "screen-scrape" of 'xinput list' report begins.
	# Makes assumptions on how this report is formatted that will break if future
	# versions of xinput change the report format in an incompatible way.
	if ($g_interactiveMenuMode) {	
		myPrint "$g_boldText 'xinput list' shows these connected devices: $g_normalText\n";
	}
	my @xinputList = `xinput --list --short`;
	foreach my $ln (@xinputList) {
		if ($g_interactiveMenuMode) {	
			myPrint "$ln";
		}
		if ($ln =~ /slave\s+pointer/i) {
			# This is a valid mouse pointer line

			$ln =~ /id=([0-9]+)/i;
			$id = $1;                # capture the mouse numeric ID

			push(@allPointerIDs, ($id)); # keep a list of all numeric pointer IDs for a possible
										 # brute force "all" batch run

			$ln =~ s/^[^a-z0-9]+//i;      # strip everything before string identifier begins
			$ln =~ s/\s+id=[0-9]+.+$//i;  # strip everything after string identifier ends
			chomp($ln);              # capture the mouse string identifier
			#print "captured: '$ln'\n";

			# xinput lists a Logitech mouse string identifier twice, with two different
			# numeric IDs - possibly true of other mice.
			# This is why we use a 2-dimensional hash:
			#   - store each UNIQUE mouse string identifier as a key once {$ln}
			#   - store both numerical IDs {$id} as keys in each unique string identifier key
			$stringAndNumericMouseIDs{$ln}{$id} = 1; # the value 1 is never used, just building keys
		}
	}
	# Ugly barbaric "screen-scrape" of 'xinput list' report ends
	#######################################################################################

	# DEBUG:
	#foreach my $ln (keys(%stringAndNumericMouseIDs)) {
	#	foreach my $id (keys(%{$stringAndNumericMouseIDs{$ln}})) {
	#		print "'$ln': id='$id'\n";
	#	}
	#}
	my $selectedKey;
	if ($g_interactiveMenuMode) {	
		# Let user interactively select from a menu of all found mouse pointer
		# string identifiers
		$selectedKey = getUserSelectedKey(sort(keys(%stringAndNumericMouseIDs)));
	}
	else {
		# Command Line argument was given, so use it
		$selectedKey = $g_CMDARG_mouseStrIdent;
	}
	
	myPrint "-=-\n";


	my @mouseIDs;	
	if ($selectedKey =~ /^all$/i) {
		@mouseIDs = @allPointerIDs;
		myPrint "Running brute force on 'all' mouse pointer IDs: '@mouseIDs'\n";
	}
	else {
		if (not exists $stringAndNumericMouseIDs{$selectedKey}) {
			myPrint "ERROR:\n";
			myPrint "    Mouse String Identifier selected: '$selectedKey' was not found.\n";
			die;
		}
		@mouseIDs = sort(keys(%{$stringAndNumericMouseIDs{$selectedKey}}));
		myPrint "Found mouse: '$selectedKey', maps to numeric ID(s): '@mouseIDs'\n";
	}


	# Returns one or both numeric mouse IDs associated with the mouse string
	# identifier, that was selected either via command line argument or
	# interactive menu selection. (some mice have two numeric IDs per mouse, ex Logitech mice)
	# -or-
	# Returns all numeric pointer IDs if special 'all' string identifier was passed
	# in on command line
	return @mouseIDs;
}

sub main {
	my @mouseIDs = getMouseIDs(); # Numeric mouse IDs 'xinput' calls will use
	my $optIndex = getMouseParamsIndex(); # array index of selected Preset to apply to mouse

	foreach my $id (@mouseIDs) {
		setMouseProps($optIndex, $id);
	}
}

main();

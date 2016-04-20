#!/usr/bin/perl
use strict;
use warnings;

#
# This code is open source, you're free to use/re-use it at will
#
#  SYNOPSIS:
#     Use hot keys to quickly switch mouse acceleration on or off.
#     Works even in full screen games (mileage may vary).
#
#  USAGE:
#     To configure, run this script with no arguments first.
#     Find/copy the mouse string identifier for your mouse
#     and try the presets in the script's menu.
#
#  OPTIONAL:
#     Edit the mouse preset values below if you don't like
#     my defaults, or want to add more presets.
#
#  HOT-KEYS:
#     In Gnome 3 or Ubuntu's Unity Desktop Environments:
#     (In other DE's, I am not familiar with how hot-keys are set,
#     it may be similar.)
#       - System Settings...  (gear icon, top-right of screen)
#       - Keyboard         (icon)
#       - Shortcuts        (tab)
#       - Custom Shortcuts  (bottom of list)
#       - Click "+" Button
#
#  EXAMPLE:
#     Literal examples using my Logitech G500 mouse.
#
#     The first hot-key mapping disables all acceleration
#       (defined below, in 'Preset 1').
#     The second hot-key enables acceleration
#       (defined below, in 'Preset 2').
#
#     Name    = G500_no_accel
#     Command = /mnt/linux_vault/utils/setLinuxMouse.pl 'Logitech G500' 1
#     Hot-Key = SUPER+F5
#
#     Name    = G500_accel
#     Command = /mnt/linux_vault/utils/setLinuxMouse.pl 'Logitech G500' 2
#     Hot-Key = SUPER+F6
#
#
#  NON-DEFAULT LIB DEPENDENCIES:
#     xinput
#     Debian based distros: sudo apt-get install xinput
#
#  FURTHER INFO:
#     https://wiki.archlinux.org/index.php/Mouse_acceleration
#
#  PRESETS:
#     Edit these for what works for your preferences:
#########################################################################
my @g_mouseParams = (

 # Preset 1
 {
    "title"  => "All Acceleration Off", # Do not edit this entry

    "decel"  => "1.0",  # 
    "accel"  => "0",    # Leave these numbers alone.
    "thresh" => "0",    #
 },

 # Preset 2
 {
    "title"  => "Favorite accel/decel (precision) setting",

    "decel"  => "1.75",  # higher values = slower pointer at slow hand movement speeds
    "accel"  => "4.8",   # higher values = faster pointer at fast hand movement speeds
    "thresh" => "2.0",   # higher values = slower overall mouse acceleration "curve"
 },

 # Preset 3
 {
    "title"  => "Testing or Alt accel/decel setting",

    "decel"  => "1.7",
    "accel"  => "4.8",
    "thresh" => "2.0",
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


my ($g_CMDARG_mouseStrIdent, $g_CMDARG_paramsIndex) = @ARGV;

sub condPrint {
	if ($g_CMDARG_mouseStrIdent) {return;}
	print "$_[0]";	
}

sub setMouseProps {
	my ($optIndex, $mouseNumericID) = @_;

	print "-=-\n";
	if ($mouseNumericID !~ /^[0-9]{1,3}$/ || $mouseNumericID < 1 || $mouseNumericID > 127) {
		print "ERROR:\n";
		print "    bad mouse numeric ID: '$mouseNumericID'...\n";
		return;
	}

	# set to desktop acceleration pointer values for this mouse
	my $paramDecel  = $g_mouseParams[$optIndex]{decel};
	my $paramAccel  = $g_mouseParams[$optIndex]{accel};
	my $paramThresh = $g_mouseParams[$optIndex]{thresh};

	my $xinputCmd = "xinput --set-prop $mouseNumericID 'Device Accel Constant Deceleration' $paramDecel";
	my $xsetCmd = "xset mouse $paramAccel $paramThresh";

	print "Configuring mouse ID: '$mouseNumericID' " .
	      "with values: $paramDecel, $paramAccel, $paramThresh\n";

	my $mouseAccelOFF = "xinput --set-prop $mouseNumericID 'Device Accel Profile' -1";
	my $mouseAccelON  = "xinput --set-prop $mouseNumericID 'Device Accel Profile' 0";
	if ($paramAccel == 0 && $paramThresh == 0) {
		# Detected turning mouse accel off
		print "$g_boldText DISABLING ALL MOUSE ACCELERATION... $g_normalText\n";
		print "$mouseAccelOFF\n"; `$mouseAccelOFF`;
	}
	else {
		# Detected turning mouse accel on
		print "Mouse Acceleration Enabled...\n";
		print "$mouseAccelON\n"; `$mouseAccelON`;
	}

	print "$xinputCmd\n"; `$xinputCmd`;
	print "$xsetCmd\n"; `$xsetCmd`;
}

sub getMouseParamsIndex {
	my $indexMax = $#g_mouseParams;
	my $optIndex = -1; #index error state
	my @menuStrings;

	# build menu options string array
	for(my $i = 0; $i <= $indexMax; $i++) {
		# print $i+1 for fake 1 origin array (for user appearances in menu selection)
		$menuStrings[$i] = "  ---> " . ($i+1) . ": $g_mouseParams[$i]{title} " .
		      "($g_mouseParams[$i]{decel}, $g_mouseParams[$i]{accel}, $g_mouseParams[$i]{thresh})"; 
	}
	
	# get desired mouse params index from user
	do {
		condPrint "Select Mouse Acceleration+Sensitivity profile:\n";
		foreach my $m (@menuStrings) {
			condPrint "$m\n"; 
		}
		condPrint "  ---> ";

		if ($g_CMDARG_paramsIndex) {
			# Command line argument was given, so use it
			$optIndex = $g_CMDARG_paramsIndex;
		}
		else {
			$optIndex = <STDIN>; chomp($optIndex);
		}


		if ($optIndex =~ /^[1-9][0-9]*$/) {
			$optIndex--; # -1 for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);

	condPrint "$g_cursorUp1";
	condPrint "\r$g_boldText "."$menuStrings[$optIndex]"."$g_normalText\n";
	return $optIndex;
}

sub getUserSelectedKey {
	# The passed in array holds hash key strings of the unique
	# string mouse identifiers extracted from 'xinput list'
	my @keyArray = @_;
	my $indexMax = $#keyArray;
	my $optIndex = -1; #index error state

	do {
		print "-=-\n";		
		print "Select Mouse String Identifier:\n";
		for(my $i = 0; $i <= $indexMax; $i++) {
			# print $i+1 for fake 1 origin array (for user appearances)
			print "  ---> " . ($i+1) . ": '$keyArray[$i]'\n"; 
		}
		print "  ---> ";

		# Get user menu selection for Mouse String Identifier		
		$optIndex = <STDIN>; chomp($optIndex);

		if ($optIndex =~ /^[1-9][0-9]*$/) {
			$optIndex--; # -1 for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);

	print "$g_cursorUp1";
	print "$g_boldText   ---> ". ($optIndex+1) .": $keyArray[$optIndex]"."$g_normalText\n";
	return $keyArray[$optIndex];
}

sub getMouseIDs {
	my %stringAndNumericMouseIDs;
	my $id;
	my $BOOLingestIdentifier = 0;
	
	my @xinputList = `xinput list`;
	condPrint "$g_boldText 'xinput list' shows these connected pointers: $g_normalText\n";
	foreach my $ln (@xinputList) {
		condPrint "$ln";
		if ($ln =~ /Virtual core pointer/i) {
			$BOOLingestIdentifier = 1;
		}
		elsif ($ln =~ /Virtual core keyboard/i) {
			last;
		}
		elsif ($BOOLingestIdentifier) {
			#print "$ln";
			$ln =~ /id=([0-9]+)/i;
			$id = $1;                # capture the mouse numeric ID
			$ln =~ s/^[^a-z0-9]+//i;
			$ln =~ s/\s+id=[0-9]+.+$//i;
			chomp($ln);              # capture the mouse string identifier
			#print "captured: '$ln'\n";

			# xinput lists each mouse string identifier twice with two different
			# numeric IDs.
			# This is why we use a 2-dimensional hash:
			#   - store each UNIQUE mouse string identifier as a key once {$ln}
			#   - store both numerical IDs {$id} as keys in each unique string identifier key
			$stringAndNumericMouseIDs{$ln}{$id} = 1; # the value 1 is never used, just building keys
		}
	}

	# DEBUG:
	#foreach my $ln (keys(%stringAndNumericMouseIDs)) {
	#	foreach my $id (keys(%{$stringAndNumericMouseIDs{$ln}})) {
	#		print "'$ln': id='$id'\n";
	#	}
	#}
	my $selectedKey;
	if ($g_CMDARG_mouseStrIdent) {
		# Command Line argument was given, so use it
		$selectedKey = $g_CMDARG_mouseStrIdent;
	}
	else {
		$selectedKey = getUserSelectedKey(sort(keys(%stringAndNumericMouseIDs)));
	}
	
	print "-=-\n";
	if (not exists $stringAndNumericMouseIDs{$selectedKey}) {
		print "ERROR:\n";
		print "    Mouse String Identifier selected: '$selectedKey' was not found.\n";
		die;
	}
	my @mouseIDs = sort(keys(%{$stringAndNumericMouseIDs{$selectedKey}}));

	print "Found mouse: '$selectedKey', maps to numeric ID(s): '@mouseIDs'\n";

	# returns both numeric mouse IDs associated with the string identifier selected
	return @mouseIDs;
}

sub main {
	my @mouseIDs = getMouseIDs();
	my $optIndex;

	$optIndex = getMouseParamsIndex();
	foreach my $id (@mouseIDs) {
		setMouseProps($optIndex, $id);
	}
}

main();

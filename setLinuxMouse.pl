#!/usr/bin/perl
use strict;
use warnings;

#
# This code is open source, you're free to use/re-use it at will
#
#  SYNOPSIS:
#    Dynamically read all connected mice from xinput and provide a
#    text menu to select a mouse and pre-configured settings to apply.
#
#    Gives more precise and consistent settings than the default
#    acceleration slider used in most distros by using xinput and xset
#    directly with a few extra parameters (configured below).
#
#    Switches between acceleration and non-accelerated settings for
#    gaming.
#
#  NON-DEFAULT LIB DEPENDENCIES:
#    xinput
#    Debian based distros: sudo apt-get install xinput
#
#  FURTHER INFO:
#    https://wiki.archlinux.org/index.php/Mouse_acceleration
#

# Edit these for what works for your mice
my @g_mouseParams = (
 {
    "title"  => "Best Sensitivity for about 700 to 800 DPI",
    "decel"  => "2.0",              # higher decel numbers equals slower pointer
    "accel"  => "4.8",
    "thresh" => "2.0",
 },
 {
    "title"  => "Testing Sensitivity",
    "decel"  => "2.8",
    "accel"  => "3.5",
    "thresh" => "1.4",
 },
 {
    "title"  => "Acceleration Off",
    "decel"  => "1.0",
    "accel"  => "0",
    "thresh" => "0",
 },
);

#print "$g_mouseParams[0]{title}\n";

my $g_boldText     = `tput bold`;
my $g_normalText   = `tput sgr0`;
my $g_cursorLeft1  = `tput cub1`;
my $g_cursorRight1 = `tput cuf1`;
my $g_cursorUp1    = `tput cuu1`;
my $g_cursorDown1  = `tput cud1`;


my ($g_CMDARG_mouseStrIdent, $g_CMDARG_paramsIndex) = @ARGV;

sub setMouseProps {
	my ($optIndex, $mouseNumericID) = @_;

	if ($mouseNumericID !~ /^[0-9]{1,3}$/ || $mouseNumericID < 1 || $mouseNumericID > 127) {
		print "ERROR: bad mouse numeric ID: '$mouseNumericID'...\n";
		return;
	}

	# set to desktop acceleration pointer values for this mouse
	my $paramDecel  = $g_mouseParams[$optIndex]{decel};
	my $paramAccel  = $g_mouseParams[$optIndex]{accel};
	my $paramThresh = $g_mouseParams[$optIndex]{thresh};

	my $xinputCmd = "xinput --set-prop $mouseNumericID 'Device Accel Constant Deceleration' $paramDecel";
	my $xsetCmd = "xset mouse $paramAccel $paramThresh";

	print "Running xinput+xset settings for mouse: ID='$mouseNumericID' " .
	      "with parameters: $paramDecel, $paramAccel, $paramThresh\n";

	my $mouseAccelOFF = "xinput --set-prop $mouseNumericID 'Device Accel Profile' -1";
	my $mouseAccelON  = "xinput --set-prop $mouseNumericID 'Device Accel Profile' 0";
	if ($paramAccel == 0 && $paramThresh == 0) {
		# Detected turning mouse accel off
		print "DISABLING ALL MOUSE ACCELERATION...\n";
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
		print "Select Mouse Acceleration+Sensitivity profile:\n";
		foreach my $m (@menuStrings) {
			print "$m\n"; 
		}
		print "  ---> ";

		if ($g_CMDARG_paramsIndex) {
			# Command line argument was given, so use it
			$optIndex = $g_CMDARG_paramsIndex;
			print "$optIndex\n";
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

	print "$g_cursorUp1";
	print "\r$g_boldText "."$menuStrings[$optIndex]"."$g_normalText\n";
	return $optIndex;
}

sub getUserSelectedKey {
	# The passed in array holds hash key strings of the unique
	# string mouse identifiers extracted from 'xinput list'
	my @keyArray = @_;
	my $indexMax = $#keyArray;
	my $optIndex = -1; #index error state

	do {
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
	foreach my $ln (@xinputList) {
		print "$ln";
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
	
	if (not exists $stringAndNumericMouseIDs{$selectedKey}) {
		print "ERROR:\n";
		print "    Mouse String Identifier selected: '$selectedKey' was not found.\n";
		die;
	}
	my @mouseIDs = sort(keys(%{$stringAndNumericMouseIDs{$selectedKey}}));

	# returns both numeric mouse IDs associated with the string identifier selected
	return @mouseIDs;
}

sub main {
	my @mouseIDs = getMouseIDs();
	my $optIndex = getMouseParamsIndex();

	foreach my $id (@mouseIDs) {
		setMouseProps($optIndex, $id);
	}
}

main();

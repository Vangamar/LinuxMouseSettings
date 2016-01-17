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
my @G_mouseParams = (
 {
    "title"  => "High Sensitivity",
    "decel"  => "3.5",              # higher decel numbers equals slower pointer
    "accel"  => "4",
    "thresh" => "2",
 },
 {
    "title"  => "Medium Sensitivity",
    "decel"  => "3.0",
    "accel"  => "4",
    "thresh" => "1",
 },
 {
    "title"  => "Acceleration Off",
    "decel"  => "1.0",
    "accel"  => "1",
    "thresh" => "1",
 },
);

#print "$G_mouseParams[0]{title}\n";

my $G_boldText     = `tput bold`;
my $G_normalText   = `tput sgr0`;
my $G_cursorLeft1  = `tput cub1`;
my $G_cursorRight1 = `tput cuf1`;
my $G_cursorUp1    = `tput cuu1`;
my $G_cursorDown1  = `tput cud1`;


sub setMouseProps {
	my ($optIndex, $mouseNumericID) = @_;

	if ($mouseNumericID !~ /^[0-9]{1,3}$/ || $mouseNumericID < 1 || $mouseNumericID > 127) {
		print "ERROR: bad mouse numeric ID: '$mouseNumericID'...\n";
		return;
	}
	
	# set to desktop acceleration pointer values for this mouse
	my $paramDecel  = $G_mouseParams[$optIndex]{decel};
	my $paramAccel  = $G_mouseParams[$optIndex]{accel};
	my $paramThresh = $G_mouseParams[$optIndex]{thresh};

	print "Running xinput+xset settings for mouse: ID='$mouseNumericID' " .
	      "with parameters: $paramDecel, $paramAccel, $paramThresh\n";
	`xinput --set-prop $mouseNumericID 'Device Accel Constant Deceleration' $paramDecel &`;
	`xset mouse $paramAccel $paramThresh &`;
}

sub getMouseParamsIndex {
	my $indexMax = $#G_mouseParams;
	my $optIndex = -1; #index error state
	my @menuStrings;

	# build menu options string array
	for(my $i = 0; $i <= $indexMax; $i++) {
		# print $i+1 for fake 1 origin array (for user appearances in menu selection)
		$menuStrings[$i] = "  ---> " . ($i+1) . ": $G_mouseParams[$i]{title} " .
		      "($G_mouseParams[$i]{decel}, $G_mouseParams[$i]{accel}, $G_mouseParams[$i]{thresh})"; 
	}
	
	# get desired mouse params index from user
	do {
		print "Select Mouse Acceleration+Sensitivity profile:\n";
		foreach my $m (@menuStrings) {
			print "$m\n"; 
		}
		print "  ---> ";
		$optIndex = <STDIN>; chomp($optIndex);
		if ($optIndex =~ /^[0-9]+$/) {
			$optIndex--; # -1 for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);

	print "$G_cursorUp1";
	print "\r$G_boldText "."$menuStrings[$optIndex]"."$G_normalText\n";
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
		$optIndex = <STDIN>; chomp($optIndex);
		if ($optIndex =~ /^[0-9]+$/) {
			$optIndex--; # -1 for 0 origin array internally
		}
		else {
			$optIndex = "-1"; #index error state
		}
	} while ($optIndex < 0 || $optIndex > $indexMax);

	print "$G_cursorUp1";
	print "$G_boldText   ---> ". ($optIndex+1) .": $keyArray[$optIndex]"."$G_normalText\n";
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
	
	my $selectedKey = getUserSelectedKey(sort(keys(%stringAndNumericMouseIDs)));
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


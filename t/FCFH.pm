#-------------------------------------------------------------------------------
# Copyright (c)	2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	FCFH.pm
# Description:	First-Class Filehandle module for test programs
#-------------------------------------------------------------------------------
# Notes
#
# The single function, fcfh(), provided by this module implements the so-called
# "First-Class Filehandle Trick" described in an article by Mark-Jason Dominus
# called "Seven Useful Uses of Local" which first appeared in The Perl Journal,
# and can also be found (at the time of writing) on his website at the URL
# "http://perl.plover.com/local.html".
#
# Note that the function returns a typeglob (one which has been localised and
# goes out of scope, becoming anonymous, as it is returned), not a reference to
# a typeglob. Returning a reference to a localised typeglob is *not* what we
# want to do, as can be seen from the following test program:
#
#	use FCFH;
#
#	my $fh1  = fcfh();
#	my $ref1 = ref $fh1 ? $fh1 : \$fh1;
#	print "fh1  = $fh1.\n";
#	print "ref1 = $ref1.\n";
#
#	my $fh2  = fcfh();
#	my $ref2 = ref $fh2 ? $fh2 : \$fh2;
#	print "fh2  = $fh2.\n";
#	print "ref2 = $ref2.\n";
#
# With the fcfh() function as written below this test program outputs something
# like:
#
#	fh1  = *FCFH::FH.
#	ref1 = GLOB(0x176d6f0).
#	fh2  = *FCFH::FH.
#	ref2 = GLOB(0x1784d04).
#
# Do not be alarmed that $fh1 and $fh2 are apparently the same as shown in this
# output. They are actually two different anonymous typeglobs which just happen
# to be shown in this output as their original, but actually now out-of-scope,
# name '*FCFH::FH'. We can see this fact from the values of $ref1 and $ref2.
# These are references to $fh1 and $fh2 respectively, but have different values
# so they must be references to two different things, i.e. $fh1 and $fh2 are
# indeed two different typeglobs, as intended.
#
# However, if we were to change the line:
#
#	return local *FH;
#
# to:
#
#	return \local *FH;
#
# in fcfh() then the test program now outputs something like:
#
#	fh1  = GLOB(0x1784c5c).
#	ref1 = GLOB(0x1784c5c).
#	fh2  = GLOB(0x1784c5c).
#	ref2 = GLOB(0x1784c5c).
#
# In other words, $fh1 and $fh2 are now both references to start with, and
# moreover *are* references to the *same* typeglob, exactly like we didn't want!
#-------------------------------------------------------------------------------

package FCFH;

use 5.006;

use strict;
use warnings;

use Exporter qw();

sub fcfh();

our @ISA = qw(Exporter);

our @EXPORT = qw(fcfh);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = ();

our $VERSION = '1.00';

#-------------------------------------------------------------------------------
#
# Public subroutines.
#

sub fcfh() {
	no warnings 'once';
	return local *FH;
}

1;

#-------------------------------------------------------------------------------

#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2002-2003, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	10_fsopen_fh_leak.t
# Description:	Test program to check if fsopen() leaks filehandles
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Test;

BEGIN { plan tests => 513 }				# Number of tests to be executed

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$file							# Test file
		);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file = 'test.txt';

										# Tests 2-513: Use 512 filehandles
	for (1 .. 512) {
		my $fh = new_fh();
		if (ok(fsopen($fh, $file, 'w', SH_DENYNO))) {
			close $fh;
		}
		unlink $file;
	}
}

#-------------------------------------------------------------------------------

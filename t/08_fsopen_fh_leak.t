#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	08_fsopen_fh_leak.t
# Description:	Test program to check if fsopen() leaks filehandles
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use FindBin qw($Bin);
use Test;

use lib $Bin;
use FCFH;

BEGIN { plan tests => 513 }				# Number of tests to be executed

use Win32::SharedFileOpen;

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
		my $fh = fcfh();
		my $ret = fsopen($fh, $file, 'w', SH_DENYNO);
		if (ok(defined $ret and $ret != 0)) {
			close $fh;
		}
		unlink $file;
	}

	print STDERR "\n(Tests 510-513 are expected to fail: see " .
				 "WARNING-FSOPEN.TXT for details)\n";
}

#-------------------------------------------------------------------------------

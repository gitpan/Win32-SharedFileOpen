#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001-2003, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	09_sopen_share.t
# Description:	Test program to check sopen() share modes
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use Test;
use Win32::WinError;

BEGIN { plan tests => 13 };				# Number of tests to be executed

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$file,							# Test file
		$fh1,							# Test filehandle 1
		$ret1,							# Return value 1 from sopen()
		$fh2,							# Test filehandle 2
		$ret2,							# Return value 2 from sopen()
		$fh3,							# Test filehandle 3
		$ret3							# Return value 3 from sopen()
		);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file = 'test.txt';

										# Tests 2-4: Check SH_DENYNO
	$fh1 = new_fh();
	$ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	ok($ret1);

	$fh2 = new_fh();
	$ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	ok($ret2);

	$fh3 = new_fh();
	$ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
	ok($ret3);

	close $fh1;
	close $fh2;
	close $fh3;

										# Tests 5-7: Check SH_DENYRD
	$fh1 = new_fh();
	$ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);
	ok($ret1);

	$fh2 = new_fh();
	$ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	ok(not defined $ret2 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	$fh3 = new_fh();
	$ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
	ok($ret3);

	close $fh1;
	close $fh3;

										# Tests 8-10: Check SH_DENYWR
	$fh1 = new_fh();
	$ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYWR, S_IWRITE);
	ok($ret1);

	$fh2 = new_fh();
	$ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	ok($ret2);

	$fh3 = new_fh();
	$ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
	ok(not defined $ret3 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	close $fh1;
	close $fh2;

										# Tests 11-13: Check SH_DENYRW
	$fh1 = new_fh();
	$ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYRW, S_IWRITE);
	ok($ret1);

	$fh2 = new_fh();
	$ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	ok(not defined $ret2 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	$fh3 = new_fh();
	$ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
	ok(not defined $ret3 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	close $fh1;

	unlink $file;
}

#-------------------------------------------------------------------------------
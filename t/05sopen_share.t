#!/bin/perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	05sopen_share.t
# Description:	Test program to check sopen() share modes
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use Test;
use Win32::WinError;

BEGIN { plan tests => 13 };				# Number of tests to be executed

use Win32::SharedFileOpen;
ok(1);									# Test 1: Did we make it this far OK?

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$fh1,							# Test filehandle 1
		$fh2,							# Test filehandle 2
		$fh3,							# Test filehandle 3
		$file							# Test file
		);

	$file = 'test.txt';

										# Tests 2-4: Check SH_DENYNO
	$fh1 = sopen($file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	ok(defined $fh1);

	$fh2 = sopen($file, O_RDONLY, SH_DENYNO);
	ok(defined $fh2);

	$fh3 = sopen($file, O_WRONLY, SH_DENYNO);
	ok(defined $fh3);

	close $fh1;
	close $fh2;
	close $fh3;

										# Tests 5-7: Check SH_DENYRD
	$fh1 = sopen($file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);
	ok(defined $fh1);

	$fh2 = sopen($file, O_RDONLY, SH_DENYNO);
	ok(not defined $fh2 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	$fh3 = sopen($file, O_WRONLY, SH_DENYNO);
	ok(defined $fh3);

	close $fh1;
	close $fh3;

										# Tests 8-10: Check SH_DENYWR
	$fh1 = sopen($file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYWR, S_IWRITE);
	ok(defined $fh1);

	$fh2 = sopen($file, O_RDONLY, SH_DENYNO);
	ok(defined $fh2);

	$fh3 = sopen($file, O_WRONLY, SH_DENYNO);
	ok(not defined $fh3 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	close $fh1;
	close $fh2;

										# Tests 11-13: Check SH_DENYRW
	$fh1 = sopen($file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYRW, S_IWRITE);
	ok(defined $fh1);

	$fh2 = sopen($file, O_RDONLY, SH_DENYNO);
	ok(not defined $fh2 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	$fh3 = sopen($file, O_WRONLY, SH_DENYNO);
	ok(not defined $fh3 and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);

	close $fh1;

	unlink $file;
}

#-------------------------------------------------------------------------------

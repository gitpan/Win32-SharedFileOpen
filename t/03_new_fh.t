#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001-2003, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	03_new_fh.t
# Description:	Test program to check new_fh()
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Test;

BEGIN { plan tests => 8 };				# Number of tests to be executed

use Win32::SharedFileOpen qw(new_fh);

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$file1,							# Test file 1
		$file2,							# Test file 2
		$str,							# Test string to read/write
		$strlen,						# Test string length
		$fh1,							# Test filehandle 1
		$fh2							# Test filehandle 2
		);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file1  = 'test1.txt';
	$file2  = 'test2.txt';
	$str    = 'Hello, world.';
	$strlen = length $str;

										# Tests 2-3: Check a single new_fh()
	$fh1 = new_fh();
	ok(open $fh1, '>', $file1);

	ok(print $fh1 "$str\n");

										# Tests 4-5: Check another new_fh()
	$fh2 = new_fh();
	ok(open $fh2, '>', $file2);

	ok(print $fh2 "$str\n");

										# Test 6: Check $fh2 worked
	close $fh2;
	ok(-s $file2 == $strlen + 2);

										# Test 7: Check $fh1 is still OK
	ok(print $fh1 "$str\n");

										# Test 8: Check $fh1 worked
	close $fh1;
	ok(-s $file1 == ($strlen + 2) * 2);

	unlink $file1;
	unlink $file2;
}

#-------------------------------------------------------------------------------

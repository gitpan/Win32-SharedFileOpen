#!/bin/perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	02fsopen_access.t
# Description:	Test program to check fsopen() access modes
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use Test;
use Win32::WinError;

BEGIN { plan tests => 33 };				# Number of tests to be executed

use Win32::SharedFileOpen;
ok(1);									# Test 1: Did we make it this far OK?

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$fh,							# Test filehandle
		$file,							# Test file
		$str,							# Test string to read/write
		$strlen,						# Test string length
		$line							# Line read from file
		);

	$file   = 'test.txt';
	$str    = 'Hello, world.';
	$strlen = length $str;

	unlink $file or die "Cannot delete file '$file': $!\n" if -e $file;

										# Tests 2-10: Check "r"/"w"
	$fh = fsopen($file, "r", SH_DENYNO);
	ok(not defined $fh and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fsopen($file, "w", SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	{
		no warnings 'io';
		ok(not defined <$fh>);
	}

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fsopen($file, "r", SH_DENYNO);
	ok(defined $fh);

	{
		no warnings 'io';
		ok(not print $fh "$str\n");
	}

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

										# Tests 11-14: Check "a"
	$fh = fsopen($file, "a", SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	{
		no warnings 'io';
		ok(not defined <$fh>);
	}

	close $fh;
	ok(-s $file == ($strlen + 2) * 2);

	unlink $file;

										# Tests 15-23: Check "r+"/"w+"
	$fh = fsopen($file, "r+", SH_DENYNO);
	ok(not defined $fh and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fsopen($file, "w+", SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fsopen($file, "r+", SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

										# Tests 24-27: Check "a+"
	$fh = fsopen($file, "a+", SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == ($strlen + 2) * 2);

	unlink $file;

										# Tests 28-30: Check "t"/"b"
	$fh = fsopen($file, "wt", SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fsopen($file, "wt", SH_DENYNO);
	binmode $fh;
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	$fh = fsopen($file, "wb", SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	unlink $file;

										# Tests 31-33: Check permissions
	$fh = fsopen('.', "r", SH_DENYNO);
	ok(not defined $fh and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	$fh = fsopen($file, "w", SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	chmod 0444, $file;

	$fh = fsopen($file, "r", SH_DENYNO);
	ok(defined $fh);
	close $fh;

	$fh = fsopen($file, "w", SH_DENYNO);
	ok(not defined $fh and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	unlink $file;
}

#-------------------------------------------------------------------------------

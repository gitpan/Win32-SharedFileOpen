#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001-2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	04_fsopen_access.t
# Description:	Test program to check fsopen() access modes
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use FindBin qw($Bin);
use Test;
use Win32::WinError;

use lib $Bin;
use FCFH;

BEGIN { plan tests => 33 };				# Number of tests to be executed

use Win32::SharedFileOpen;

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$file,							# Test file
		$str,							# Test string to read/write
		$strlen,						# Test string length
		$fh,							# Test filehandle
		$ret,							# Return value from fsopen()
		$line							# Line read from file
		);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file   = 'test.txt';
	$str    = 'Hello, world.';
	$strlen = length $str;

	unlink $file or die "Cannot delete file '$file': $!\n" if -e $file;

										# Tests 2-10: Check 'r'/'w'
	$fh = fcfh();
	$ret = fsopen($fh, $file, 'r', SH_DENYNO);
	ok(not defined $ret and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fcfh();
	$ret = fsopen($fh, $file, 'w', SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	{
		no warnings 'io';
		ok(not defined <$fh>);
	}

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fcfh();
	$ret = fsopen($fh, $file, 'r', SH_DENYNO);
	ok(defined $ret and $ret != 0);

	{
		no warnings 'io';
		ok(not print $fh "$str\n");
	}

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

										# Tests 11-14: Check 'a'
	$fh = fcfh();
	$ret = fsopen($fh, $file, 'a', SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	{
		no warnings 'io';
		ok(not defined <$fh>);
	}

	close $fh;
	ok(-s $file == ($strlen + 2) * 2);

	unlink $file;

										# Tests 15-23: Check 'r+'/'w+'
	$fh = fcfh();
	$ret = fsopen($fh, $file, 'r+', SH_DENYNO);
	ok(not defined $ret and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fcfh();
	$ret = fsopen($fh, $file, 'w+', SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fcfh();
	$ret = fsopen($fh, $file, 'r+', SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

										# Tests 24-27: Check 'a+'
	$fh = fcfh();
	$ret = fsopen($fh, $file, 'a+', SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == ($strlen + 2) * 2);

	unlink $file;

										# Tests 28-30: Check 't'/'b'
	$fh = fcfh();
	fsopen($fh, $file, 'wt', SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fcfh();
	fsopen($fh, $file, 'wt', SH_DENYNO);
	binmode $fh;
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	$fh = fcfh();
	fsopen($fh, $file, 'wb', SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	unlink $file;

										# Tests 31-33: Check permissions
	$fh = fcfh();
	$ret = fsopen($fh, '.', 'r', SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	$fh = fcfh();
	fsopen($fh, $file, 'w', SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	chmod 0444, $file;

	$fh = fcfh();
	$ret = fsopen($fh, $file, 'r', SH_DENYNO);
	ok(defined $ret and $ret != 0);
	close $fh;

	$fh = fcfh();
	$ret = fsopen($fh, $file, 'w', SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	unlink $file;
}

#-------------------------------------------------------------------------------

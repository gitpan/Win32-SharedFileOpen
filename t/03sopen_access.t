#!/bin/perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	03sopen_access.t
# Description:	Test program to check sopen() access modes
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use Test;
use Win32::WinError;

BEGIN { plan tests => 39 };				# Number of tests to be executed

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

										# Tests 2-11: Check O_RDONLY/O_WRONLY
	$fh = sopen($file, O_RDONLY, SH_DENYNO);
	ok(not defined $fh and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = sopen($file, O_WRONLY, SH_DENYNO);
	ok(not defined $fh and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = sopen($file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	{
		no warnings 'io';
		ok(not defined <$fh>);
	}

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = sopen($file, O_RDONLY, SH_DENYNO);
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

										# Tests 12-15: Check O_WRONLY | O_APPEND
	$fh = sopen($file, O_WRONLY | O_APPEND, SH_DENYNO);
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

										# Tests 16-24: Check O_RDWR
	$fh = sopen($file, O_RDWR, SH_DENYNO);
	ok(not defined $fh and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = sopen($file, O_RDWR | O_CREAT, SH_DENYNO, S_IWRITE);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = sopen($file, O_RDWR, SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

										# Tests 25-28: Check O_RDWR | O_APPEND
	$fh = sopen($file, O_RDWR | O_APPEND, SH_DENYNO);
	ok(defined $fh);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == ($strlen + 2) * 2);

	unlink $file;

										# Tests 29-31: Check O_TEXT/O_BINARY
	$fh = sopen($file, O_WRONLY | O_CREAT | O_TEXT, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = sopen($file, O_WRONLY | O_TRUNC | O_TEXT, SH_DENYNO);
	binmode $fh;
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	$fh = sopen($file, O_WRONLY | O_TRUNC | O_BINARY, SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	unlink $file;

										# Test 32-33: Check O_CREAT | O_EXCL
	$fh = sopen($file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
	ok(defined $fh);
	close $fh;

	$fh = sopen($file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
	ok(not defined $fh and $!{EEXIST} and $ == ERROR_FILE_EXISTS);

										# Test 34: Check O_TEMPORARY
	$fh = sopen($file, O_WRONLY | O_CREAT | O_TEMPORARY, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	ok(not -e $file);

										# Test 35-36: Check O_TRUNC
	$fh = sopen($file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = sopen($file, O_WRONLY | O_TRUNC, SH_DENYNO);
	close $fh;
	ok(-e $file and -s $file == 0);

	unlink $file;

										# Tests 37-40: Check permissions
	$fh = sopen('.', O_RDONLY, SH_DENYNO);
	ok(not defined $fh and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	$fh = sopen($file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	chmod 0444, $file;

	$fh = sopen($file, O_RDONLY, SH_DENYNO);
	ok(defined $fh);
	close $fh;

	$fh = sopen($file, O_WRONLY, SH_DENYNO);
	ok(not defined $fh and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	unlink $file;
}

#-------------------------------------------------------------------------------

#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001-2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	05_sopen_access.t
# Description:	Test program to check sopen() access modes
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

BEGIN { plan tests => 39 };				# Number of tests to be executed

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
		$ret,							# Return value from sopen()
		$line							# Line read from file
		);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file   = 'test.txt';
	$str    = 'Hello, world.';
	$strlen = length $str;

	unlink $file or die "Cannot delete file '$file': $!\n" if -e $file;

										# Tests 2-11: Check O_RDONLY/O_WRONLY
	$fh = fcfh();
	$ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
	ok(not defined $ret and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY, SH_DENYNO);
	ok(not defined $ret and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
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
	$ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
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

										# Tests 12-15: Check O_WRONLY | O_APPEND
	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY | O_APPEND, SH_DENYNO);
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

										# Tests 16-24: Check O_RDWR
	$fh = fcfh();
	$ret = sopen($fh, $file, O_RDWR, SH_DENYNO);
	ok(not defined $ret and $!{ENOENT} and $ == ERROR_FILE_NOT_FOUND);

	$fh = fcfh();
	$ret = sopen($fh, $file, O_RDWR | O_CREAT, SH_DENYNO, S_IWRITE);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fcfh();
	$ret = sopen($fh, $file, O_RDWR, SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == $strlen + 2);

										# Tests 25-28: Check O_RDWR | O_APPEND
	$fh = fcfh();
	$ret = sopen($fh, $file, O_RDWR | O_APPEND, SH_DENYNO);
	ok(defined $ret and $ret != 0);

	ok(print $fh "$str\n");

	seek $fh, 0, 0;
	chomp($line = <$fh>);
	ok(length $line == $strlen);

	close $fh;
	ok(-s $file == ($strlen + 2) * 2);

	unlink $file;

										# Tests 29-31: Check O_TEXT/O_BINARY
	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_CREAT | O_TEXT, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_TRUNC | O_TEXT, SH_DENYNO);
	binmode $fh;
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_TRUNC | O_BINARY, SH_DENYNO);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 1);

	unlink $file;

										# Test 32-33: Check O_CREAT | O_EXCL
	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
	ok(defined $ret and $ret != 0);
	close $fh;

	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
	ok(not defined $ret and $!{EEXIST} and $ == ERROR_FILE_EXISTS);

										# Test 34: Check O_TEMPORARY
	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_CREAT | O_TEMPORARY, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	ok(not -e $file);

										# Test 35-36: Check O_TRUNC
	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	ok(-s $file == $strlen + 2);

	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_TRUNC, SH_DENYNO);
	close $fh;
	ok(-e $file and -s $file == 0);

	unlink $file;

										# Tests 37-40: Check permissions
	$fh = fcfh();
	$ret = sopen($fh, '.', O_RDONLY, SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	$fh = fcfh();
	sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
	print $fh "$str\n";
	close $fh;
	chmod 0444, $file;

	$fh = fcfh();
	$ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
	ok(defined $ret and $ret != 0);
	close $fh;

	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY, SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_ACCESS_DENIED);

	unlink $file;
}

#-------------------------------------------------------------------------------

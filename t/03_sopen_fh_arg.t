#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	03_sopen_fh_arg.t
# Description:	Test program to check sopen()'s filehandle argument
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use FileHandle;
use FindBin qw($Bin);
use IO::File;
use IO::Handle;
use Symbol;
use Test;

use lib $Bin;
use FCFH;

BEGIN { plan tests => 14 }				# Number of tests to be executed

use Win32::SharedFileOpen;

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	local(	*FH							# Glob for test filehandle
			);

	my(		$file,						# Test file
			$err,						# Error message from sopen()
			$fh,						# Test indirect filehandle
			$ret						# Return value from sopen()
			);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file = 'test.txt';
	$err = "sopen() can't use the undefined value as an indirect filehandle";

	unlink $file or die "Cannot delete file '$file': $!\n" if -e $file;

										# Test 2: Check undefined scalar
	eval {
		undef $fh;
		sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	};
	ok(defined $@ and $@ =~ /^\Q$err\E/);

										# Test 3: Check uninitialised IO member
	eval {
		sopen(*FH{IO}, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
			  S_IWRITE);
	};
	ok(defined $@ and $@ =~ /^\Q$err\E/);

										# Test 4: Check filehandle
	$ret = sopen(FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close FH;
	}

										# Test 5: Check string
	$ret = sopen('FH', $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
				 S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close FH;
	}

										# Test 6: Check named typeglob
	$ret = sopen(*FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close FH;
	}

										# Test 7: Check anonymous typeglob (1)
	$fh = gensym();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close $fh;
	}

										# Test 8: Check anonymous typeglob (2)
	$fh = do { local *FH };
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close $fh;
	}

										# Test 9: Check anonymous typeglob (3)
	$fh = fcfh();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close $fh;
	}

										# Test 10: Check typeglob reference
	$ret = sopen(\*FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
				 S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close FH;
	}

										# Test 11: Check initialised IO member
	$ret = sopen(*FH{IO}, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
				 S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close FH;
	}

										# Test 12: Check IO::Handle object
	$fh = IO::Handle->new();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close $fh;
	}

										# Test 13: Check IO::File object
	$fh = IO::File->new();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close $fh;
	}

										# Test 14: Check FileHandle object
	$fh = FileHandle->new();
	$ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	if (ok(defined $ret and $ret != 0)) {
		close $fh;
	}

	unlink $file;
}

#-------------------------------------------------------------------------------

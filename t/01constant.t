#!/bin/perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	constant.t
# Description:	Test program to check constant autoloading
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Test;

BEGIN { plan tests => 21 };				# Number of tests to be executed

use Win32::SharedFileOpen;
ok(1);									# Test 1: Did we make it this far OK?

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
										# Tests 2-15: Check O_* flags
	ok(defined O_APPEND);
	ok(defined O_BINARY);
	ok(defined O_CREAT);
	ok(defined O_EXCL);
	ok(defined O_NOINHERIT);
	ok(defined O_RANDOM);
	ok(defined O_RDONLY);
	ok(defined O_RDWR);
	ok(defined O_SEQUENTIAL);
	ok(defined O_SHORT_LIVED);
	ok(defined O_TEMPORARY);
	ok(defined O_TEXT);
	ok(defined O_TRUNC);
	ok(defined O_WRONLY);

										# Tests 16-17: Check S_* flags
	ok(defined S_IREAD);
	ok(defined S_IWRITE);

										# Tests 18-21: Check SH_* flags
	ok(defined SH_DENYNO);
	ok(defined SH_DENYRD);
	ok(defined SH_DENYWR);
	ok(defined SH_DENYRW);
}

#-------------------------------------------------------------------------------

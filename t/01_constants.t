#!perl
#===============================================================================
#
# t/01_constants.t
#
# DESCRIPTION
#   Test program to check autoloading of constants.
#
# COPYRIGHT
#   Copyright (c) 2001-2004, Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use Test;

#===============================================================================
# INITIALISATION
#===============================================================================

BEGIN {
    plan tests => 23;                   # Number of tests to be executed
}

use Win32::SharedFileOpen qw(:DEFAULT :retry);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
                                        # Test 1: Did we make it this far OK?
    ok(1);

                                        # Tests 2-16: Check O_* flags
    ok(defined O_APPEND);
    ok(defined O_BINARY);
    ok(defined O_CREAT);
    ok(defined O_EXCL);
    ok(defined O_NOINHERIT);
    ok(defined O_RANDOM);
    ok(defined O_RAW);
    ok(defined O_RDONLY);
    ok(defined O_RDWR);
    ok(defined O_SEQUENTIAL);
    ok(defined O_SHORT_LIVED);
    ok(defined O_TEMPORARY);
    ok(defined O_TEXT);
    ok(defined O_TRUNC);
    ok(defined O_WRONLY);

                                        # Tests 17-18: Check S_* flags
    ok(defined S_IREAD);
    ok(defined S_IWRITE);

                                        # Tests 19-22: Check SH_* flags
    ok(defined SH_DENYNO);
    ok(defined SH_DENYRD);
    ok(defined SH_DENYWR);
    ok(defined SH_DENYRW);

                                        # Test 23: Check INFINITE flag
    ok(defined INFINITE);
}

#===============================================================================

#!perl
#===============================================================================
#
# t/01_constants.t
#
# DESCRIPTION
#   Test script to check autoloading of constants.
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
    ok(eval { O_APPEND();      1 });
    ok(eval { O_BINARY();      1 });
    ok(eval { O_CREAT();       1 });
    ok(eval { O_EXCL();        1 });
    ok(eval { O_NOINHERIT();   1 });
    ok(eval { O_RANDOM();      1 });
    ok(eval { O_RAW();         1 });
    ok(eval { O_RDONLY();      1 });
    ok(eval { O_RDWR();        1 });
    ok(eval { O_SEQUENTIAL();  1 });
    ok(eval { O_SHORT_LIVED(); 1 });
    ok(eval { O_TEMPORARY();   1 });
    ok(eval { O_TEXT();        1 });
    ok(eval { O_TRUNC();       1 });
    ok(eval { O_WRONLY();      1 });

                                        # Tests 17-18: Check S_* flags
    ok(eval { S_IREAD();       1 });
    ok(eval { S_IWRITE();      1 });

                                        # Tests 19-22: Check SH_* flags
    ok(eval { SH_DENYNO();     1 });
    ok(eval { SH_DENYRD();     1 });
    ok(eval { SH_DENYWR();     1 });
    ok(eval { SH_DENYRW();     1 });

                                        # Test 23: Check INFINITE flag
    ok(eval { INFINITE();      1 });
}

#===============================================================================

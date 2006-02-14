#!perl
#===============================================================================
#
# t/01_constants.t
#
# DESCRIPTION
#   Test script to check autoloading of constants.
#
# COPYRIGHT
#   Copyright (C) 2001-2006 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use Config qw(%Config);
use Test::More tests => 23;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::SharedFileOpen', qw(:DEFAULT :retry));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $bcc = $Config{cc} =~ /bcc32/io;

    ok(eval { O_APPEND();          1 }, 'O_APPEND flag');
    ok(eval { O_BINARY();          1 }, 'O_BINARY flag');
    ok(eval { O_CREAT();           1 }, 'O_CREAT flag');
    ok(eval { O_EXCL();            1 }, 'O_EXCL flag');
    ok(eval { O_NOINHERIT();       1 }, 'O_NOINHERIT flag');
    SKIP: {
        skip "Borland CRT doesn't support O_RANDOM", 1 if $bcc;
        ok(eval { O_RANDOM();      1 }, 'O_RANDOM flag');
    }
    ok(eval { O_RAW();             1 }, 'O_RAW flag');
    ok(eval { O_RDONLY();          1 }, 'O_RDONLY flag');
    ok(eval { O_RDWR();            1 }, 'O_RDWR flag');
    SKIP: {
        skip "Borland CRT doesn't support O_SEQUENTIAL", 1 if $bcc;
        ok(eval { O_SEQUENTIAL();  1 }, 'O_SEQUENTIAL flag');
    }
    SKIP: {
        skip "Borland CRT doesn't support O_SHORT_LIVED", 1 if $bcc;
        ok(eval { O_SHORT_LIVED(); 1 }, 'O_SHORT_LIVED flag');
    }
    SKIP: {
        skip "Borland CRT doesn't support O_TEMPORARY", 1 if $bcc;
        ok(eval { O_TEMPORARY();   1 }, 'O_TEMPORARY flag');
    }
    ok(eval { O_TEXT();            1 }, 'O_TEXT flag');
    ok(eval { O_TRUNC();           1 }, 'O_TRUNC flag');
    ok(eval { O_WRONLY();          1 }, 'O_WRONLY flag');

    ok(eval { S_IREAD();           1 }, 'S_IREAD flag');
    ok(eval { S_IWRITE();          1 }, 'S_IWRITE flag');

    ok(eval { SH_DENYNO();         1 }, 'SH_DENYNO flag');
    ok(eval { SH_DENYRD();         1 }, 'SH_DENYRD flag');
    ok(eval { SH_DENYWR();         1 }, 'SH_DENYWR flag');
    ok(eval { SH_DENYRW();         1 }, 'SH_DENYRW flag');

    ok(eval { INFINITE();          1 }, 'INFINITE flag');
}

#===============================================================================

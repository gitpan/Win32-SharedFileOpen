#!perl
#===============================================================================
#
# 09_sopen_share.t
#
# DESCRIPTION
#   Test program to check sopen() share modes.
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

use Errno;
use Test;
use Win32::WinError;

#===============================================================================
# INITIALISATION
#===============================================================================

BEGIN {
    plan tests => 13;                   # Number of tests to be executed
}

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
                                        # Test 1: Did we make it this far OK?
    ok(1);

    my $file = 'test.txt';

    my($fh1, $fh2, $fh3, $ret1, $ret2, $ret3);

                                        # Tests 2-4: Check SH_DENYNO
    $fh1 = new_fh();
    $ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret1);

    $fh2 = new_fh();
    $ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ok($ret2);

    $fh3 = new_fh();
    $ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
    ok($ret3);

    close $fh1;
    close $fh2;
    close $fh3;

                                        # Tests 5-7: Check SH_DENYRD
    $fh1 = new_fh();
    $ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);
    ok($ret1);

    $fh2 = new_fh();
    $ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ok(not defined $ret2 and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);

    $fh3 = new_fh();
    $ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
    ok($ret3);

    close $fh1;
    close $fh3;

                                        # Tests 8-10: Check SH_DENYWR
    $fh1 = new_fh();
    $ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYWR, S_IWRITE);
    ok($ret1);

    $fh2 = new_fh();
    $ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ok($ret2);

    $fh3 = new_fh();
    $ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
    ok(not defined $ret3 and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);

    close $fh1;
    close $fh2;

                                        # Tests 11-13: Check SH_DENYRW
    $fh1 = new_fh();
    $ret1 = sopen($fh1, $file, O_RDWR | O_CREAT | O_TRUNC, SH_DENYRW, S_IWRITE);
    ok($ret1);

    $fh2 = new_fh();
    $ret2 = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ok(not defined $ret2 and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);

    $fh3 = new_fh();
    $ret3 = sopen($fh3, $file, O_WRONLY, SH_DENYNO);
    ok(not defined $ret3 and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);

    close $fh1;

    unlink $file;
}

#===============================================================================

#!perl
#===============================================================================
#
# 05_sopen_fh_arg.t
#
# DESCRIPTION
#   Test program to check sopen()'s filehandle argument.
#
# COPYRIGHT
#   Copyright (c) 2002-2004, Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use FileHandle;
use IO::File;
use IO::Handle;
use Symbol;
use Test;

#===============================================================================
# INITIALISATION
#===============================================================================

BEGIN {
    plan tests => 14;                   # Number of tests to be executed
}

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
                                        # Test 1: Did we make it this far OK?
    ok(1);

    my $file = 'test.txt';
    my $err = qr/^sopen\(\) can't use the undefined value/;

    my($fh, $ret);
    local *FH;

    unlink $file or die "Can't delete file '$file': $!\n" if -e $file;

                                        # Test 2: Check undefined scalar
    eval {
        undef $fh;
        sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    };
    ok($@ =~ $err);

                                        # Test 3: Check uninitialised IO member
    eval {
        sopen(*FH{IO}, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
              S_IWRITE);
    };
    ok($@ =~ $err);

                                        # Test 4: Check filehandle
    $ret = sopen(FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close FH;

                                        # Test 5: Check string
    $ret = sopen('FH', $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                 S_IWRITE);
    ok($ret) and close FH;

                                        # Test 6: Check named typeglob
    $ret = sopen(*FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close FH;

                                        # Test 7: Check anonymous typeglob (1)
    $fh = gensym();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close $fh;

                                        # Test 8: Check anonymous typeglob (2)
    $fh = do { local *FH };
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close $fh;

                                        # Test 9: Check anonymous typeglob (3)
    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close $fh;

                                        # Test 10: Check typeglob reference
    $ret = sopen(\*FH, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                 S_IWRITE);
    ok($ret) and close FH;

                                        # Test 11: Check initialised IO member
    $ret = sopen(*FH{IO}, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                 S_IWRITE);
    ok($ret) and close FH;

                                        # Test 12: Check IO::Handle object
    $fh = IO::Handle->new();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close $fh;

                                        # Test 13: Check IO::File object
    $fh = IO::File->new();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close $fh;

                                        # Test 14: Check FileHandle object
    $fh = FileHandle->new();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    ok($ret) and close $fh;

    unlink $file;
}

#===============================================================================

#!perl
#-------------------------------------------------------------------------------
# Copyright (c) 2002-2003, Steve Hay. All rights reserved.
#
# Module Name:  Win32::SharedFileOpen
# Source File:  04_fsopen_fh_arg.t
# Description:  Test program to check fsopen()'s filehandle argument
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use FileHandle;
use IO::File;
use IO::Handle;
use Symbol;
use Test;

BEGIN { plan tests => 14 }              # Number of tests to be executed

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
    local(  *FH                         # Glob for test filehandle
            );

    my(     $file,                      # Test file
            $err,                       # Error message from fsopen()
            $fh,                        # Test indirect filehandle
            $ret                        # Return value from fsopen()
            );

                                        # Test 1: Did we make it this far OK?
    ok(1);

    $file = 'test.txt';
    $err = qr/^fsopen\(\) can't use the undefined value/;

    unlink $file or die "Can't delete file '$file': $!\n" if -e $file;

                                        # Test 2: Check undefined scalar
    eval {
        undef $fh;
        fsopen($fh, $file, 'w', SH_DENYNO);
    };
    ok($@ =~ $err);

                                        # Test 3: Check uninitialised IO member
    eval {
        fsopen(*FH{IO}, $file, 'w', SH_DENYNO);
    };
    ok($@ =~ $err);

                                        # Test 4: Check filehandle
    $ret = fsopen(FH, $file, 'w', SH_DENYNO);
    ok($ret) and close FH;

                                        # Test 5: Check string
    $ret = fsopen('FH', $file, 'w', SH_DENYNO);
    ok($ret) and close FH;

                                        # Test 6: Check named typeglob
    $ret = fsopen(*FH, $file, 'w', SH_DENYNO);
    ok($ret) and close FH;

                                        # Test 7: Check anonymous typeglob (1)
    $fh = gensym();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret) and close $fh;

                                        # Test 8: Check anonymous typeglob (2)
    $fh = do { local *FH };
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret) and close $fh;

                                        # Test 9: Check anonymous typeglob (3)
    $fh = new_fh();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret) and close $fh;

                                        # Test 10: Check typeglob reference
    $ret = fsopen(\*FH, $file, 'w', SH_DENYNO);
    ok($ret) and close FH;

                                        # Test 11: Check initialised IO member
    $ret = fsopen(*FH{IO}, $file, 'w', SH_DENYNO);
    ok($ret) and close FH;

                                        # Test 12: Check IO::Handle object
    $fh = IO::Handle->new();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret) and close $fh;

                                        # Test 13: Check IO::File object
    $fh = IO::File->new();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret) and close $fh;

                                        # Test 14: Check FileHandle object
    $fh = FileHandle->new();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret) and close $fh;

    unlink $file;
}

#-------------------------------------------------------------------------------

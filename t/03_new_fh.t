#!perl
#===============================================================================
#
# 03_new_fh.t
#
# DESCRIPTION
#   Test program to check new_fh().
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
    plan tests => 8;                    # Number of tests to be executed
}

use Win32::SharedFileOpen qw(new_fh);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
                                        # Test 1: Did we make it this far OK?
    ok(1);

    my $file1  = 'test1.txt';
    my $file2  = 'test2.txt';
    my $str    = 'Hello, world.';
    my $strlen = length $str;

    my($fh1, $fh2);

                                        # Tests 2-3: Check a single new_fh()
    $fh1 = new_fh();
    ok(open $fh1, '>', $file1);

    ok(print $fh1 "$str\n");

                                        # Tests 4-5: Check another new_fh()
    $fh2 = new_fh();
    ok(open $fh2, '>', $file2);

    ok(print $fh2 "$str\n");

                                        # Test 6: Check $fh2 worked
    close $fh2;
    ok(-s $file2 == $strlen + 2);

                                        # Test 7: Check $fh1 is still OK
    ok(print $fh1 "$str\n");

                                        # Test 8: Check $fh1 worked
    close $fh1;
    ok(-s $file1 == ($strlen + 2) * 2);

    unlink $file1;
    unlink $file2;
}

#===============================================================================

#!perl
#===============================================================================
#
# 10_fsopen_fh_leak.t
#
# DESCRIPTION
#   Test program to check if fsopen() leaks filehandles.
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

use Test;

#===============================================================================
# INITIALISATION
#===============================================================================

BEGIN {
    plan tests => 513;                  # Number of tests to be executed
}

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
                                        # Test 1: Did we make it this far OK?
    ok(1);

    my $file = 'test.txt';

                                        # Tests 2-513: Use 512 filehandles
    for (1 .. 512) {
        my $fh = new_fh();
        if (ok(fsopen($fh, $file, 'w', SH_DENYNO))) {
            close $fh;
        }
        unlink $file;
    }
}

#===============================================================================

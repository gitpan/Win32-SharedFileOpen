#!perl
#===============================================================================
#
# t/11_sopen_fh_leak.t
#
# DESCRIPTION
#   Test script to check if sopen() leaks filehandles.
#
# COPYRIGHT
#   Copyright (C) 2002, 2004-2005 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use Test::More tests => 513;

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    use_ok('Win32::SharedFileOpen', qw(:DEFAULT new_fh));
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    my $file = 'test.txt';

    for my $i (1 .. 512) {
        my $fh = new_fh();
        my $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO,
                        S_IWRITE);
        my($errno, $lasterror) = ($!, $^E);
        ok($ret, "filehandle $i works")
            ? close $fh : diag("\$! = '$errno', \$^E = '$lasterror'");
        unlink $file;
    }
}

#===============================================================================

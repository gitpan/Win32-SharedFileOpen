#!perl
#===============================================================================
#
# t/08_fsopen_share.t
#
# DESCRIPTION
#   Test script to check fsopen() share modes.
#
# COPYRIGHT
#   Copyright (C) 2001-2005 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use Errno qw(:POSIX);
use Test::More tests => 27;
use Win32::WinError;

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

    my($fh1, $fh2, $ret, $errno, $lasterror);

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w', SH_DENYNO);

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYNO doesn't deny readers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYNO doesn't deny writers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w+', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYNO doesn't deny read-writers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    close $fh1;

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w', SH_DENYRD);

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRD denies readers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYRD doesn't deny writers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w+', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRD denies read-writers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    close $fh1;

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w', SH_DENYWR);

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYWR doesn't deny readers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYWR denies writers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w+', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYWR denies read-writers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    close $fh1;

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w', SH_DENYRW);

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRW denies readers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRW denies writers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'w+', SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRW denies read-writers');
    is($errno, EACCES, '... and $! is set correctly');
    is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');

    close $fh1;

    unlink $file;
}

#===============================================================================

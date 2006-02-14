#!perl
#===============================================================================
#
# t/09_sopen_share.t
#
# DESCRIPTION
#   Test script to check sopen() share modes.
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
use Errno qw(EACCES);
use Test::More tests => 27;
use Win32::WinError qw(ERROR_SHARING_VIOLATION);

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
    my $bcc  = $Config{cc} =~ /bcc32/io;

    my($fh1, $fh2, $ret, $errno, $lasterror);

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYNO does not deny readers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYNO does not deny writers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDWR, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYNO does not deny read-writers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    close $fh1;

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRD denies readers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYRD does not deny writers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDWR, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRD denies read-writers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    close $fh1;

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYWR, S_IWRITE);

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, "SH_DENYWR does not deny readers") or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh2;

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYWR denies writers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDWR, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYWR denies read-writers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    close $fh1;

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRW, S_IWRITE);

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRW denies readers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRW denies writers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDWR, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'SH_DENYRW denies read-writers');
    is($errno, EACCES, '... and $! is set correctly');
    SKIP: {
        skip "Borland CRT doesn't set Win32 last error code", 1 if $bcc;
        is($lasterror, ERROR_SHARING_VIOLATION, '... and $^E is set correctly');
    }

    close $fh1;

    unlink $file;
}

#===============================================================================

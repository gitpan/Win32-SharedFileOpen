#!perl
#===============================================================================
#
# t/06_fsopen_access.t
#
# DESCRIPTION
#   Test script to check fsopen() access modes.
#
# COPYRIGHT
#   Copyright (C) 2001-2004 Steve Hay.  All rights reserved.
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
    plan tests => 34;                   # Number of tests to be executed
}

use Win32::SharedFileOpen qw(:DEFAULT new_fh);

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
                                        # Test 1: Did we make it this far OK?
    ok(1);

    my $file   = 'test.txt';
    my $str    = 'Hello, world.';
    my $strlen = length $str;

    my($fh, $ret, $line);

    unlink $file or die "Can't delete file '$file': $!\n" if -e $file;

                                        # Tests 2-10: Check 'r'/'w'
    $fh = new_fh();
    $ret = fsopen($fh, $file, 'r', SH_DENYNO);
    ok(not defined $ret and $!{ENOENT} and $^E == ERROR_FILE_NOT_FOUND);

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    {
        no warnings 'io';
        ok(not defined <$fh>);
    }

    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'r', SH_DENYNO);
    ok($ret);

    {
        no warnings 'io';
        ok(not print $fh "$str\n");
    }

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == $strlen + 2);

                                        # Tests 11-14: Check 'a'
    $fh = new_fh();
    $ret = fsopen($fh, $file, 'a', SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    {
        no warnings 'io';
        ok(not defined <$fh>);
    }

    close $fh;
    ok(-s $file == ($strlen + 2) * 2);

    unlink $file;

                                        # Tests 15-23: Check 'r+'/'w+'
    $fh = new_fh();
    $ret = fsopen($fh, $file, 'r+', SH_DENYNO);
    ok(not defined $ret and $!{ENOENT} and $^E == ERROR_FILE_NOT_FOUND);

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'w+', SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'r+', SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == $strlen + 2);

                                        # Tests 24-27: Check 'a+'
    $fh = new_fh();
    $ret = fsopen($fh, $file, 'a+', SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == ($strlen + 2) * 2);

    unlink $file;

                                        # Tests 28-31: Check 't'/'b'
    $fh = new_fh();
    fsopen($fh, $file, 'wt', SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    fsopen($fh, $file, 'wt', SH_DENYNO);
    binmode $fh, ':raw';
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 1);

    $fh = new_fh();
    fsopen($fh, $file, 'wb', SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 1);

    $fh = new_fh();
    fsopen($fh, $file, 'wb', SH_DENYNO);
    binmode $fh, ':crlf';
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 2);

    unlink $file;

                                        # Tests 32-34: Check permissions
    $fh = new_fh();
    $ret = fsopen($fh, '.', 'r', SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_ACCESS_DENIED);

    $fh = new_fh();
    fsopen($fh, $file, 'w', SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    chmod 0444, $file;

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'r', SH_DENYNO);
    ok($ret);
    close $fh;

    $fh = new_fh();
    $ret = fsopen($fh, $file, 'w', SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_ACCESS_DENIED);

    unlink $file;
}

#===============================================================================

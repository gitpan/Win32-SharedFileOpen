#!perl
#===============================================================================
#
# t/07_sopen_access.t
#
# DESCRIPTION
#   Test script to check sopen() access modes.
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
    plan tests => 42;                   # Number of tests to be executed
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

                                        # Tests 2-11: Check O_RDONLY/O_WRONLY
    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
    ok(not defined $ret and $!{ENOENT} and $^E == ERROR_FILE_NOT_FOUND);

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY, SH_DENYNO);
    ok(not defined $ret and $!{ENOENT} and $^E == ERROR_FILE_NOT_FOUND);

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
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
    $ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
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

                                        # Tests 12-15: Check O_WRONLY | O_APPEND
    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_APPEND, SH_DENYNO);
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

                                        # Tests 16-24: Check O_RDWR
    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR, SH_DENYNO);
    ok(not defined $ret and $!{ENOENT} and $^E == ERROR_FILE_NOT_FOUND);

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR | O_CREAT, SH_DENYNO, S_IWRITE);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR, SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == $strlen + 2);

                                        # Tests 25-28: Check O_RDWR | O_APPEND
    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR | O_APPEND, SH_DENYNO);
    ok($ret);

    ok(print $fh "$str\n");

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    ok($line eq $str);

    close $fh;
    ok(-s $file == ($strlen + 2) * 2);

    unlink $file;

                                        # Tests 29-34: Check O_TEXT/O_BINARY|RAW
    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT | O_TEXT, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_TEXT, SH_DENYNO);
    binmode $fh, ':raw';
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 1);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_BINARY, SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 1);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_RAW, SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 1);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_BINARY, SH_DENYNO);
    binmode $fh, ':crlf';
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_RAW, SH_DENYNO);
    binmode $fh, ':crlf';
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 2);

    unlink $file;

                                        # Tests 35-36: Check O_CREAT | O_EXCL
    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
    ok($ret);
    close $fh;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
    ok(not defined $ret and $!{EEXIST} and $^E == ERROR_FILE_EXISTS);

                                        # Test 37: Check O_TEMPORARY
    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT | O_TEMPORARY, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    ok(not -e $file);

                                        # Tests 38-39: Check O_TRUNC
    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    ok(-s $file == $strlen + 2);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC, SH_DENYNO);
    close $fh;
    ok(-e $file and -s $file == 0);

    unlink $file;

                                        # Tests 40-42: Check permissions
    $fh = new_fh();
    $ret = sopen($fh, '.', O_RDONLY, SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_ACCESS_DENIED);

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    chmod 0444, $file;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
    ok($ret);
    close $fh;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY, SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_ACCESS_DENIED);

    unlink $file;
}

#===============================================================================

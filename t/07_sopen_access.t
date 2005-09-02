#!perl
#===============================================================================
#
# t/07_sopen_access.t
#
# DESCRIPTION
#   Test script to check sopen() access modes.
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
use Test::More tests => 61;
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
    my $file   = 'test.txt';
    my $str    = 'Hello, world.';
    my $strlen = length $str;

    my($fh, $ret, $errno, $lasterror, $line);

    unlink $file or die "Can't delete file '$file': $!\n" if -e $file;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() initially fails with O_RDONLY');
    is($errno, ENOENT, '... and sets $! correctly');
    is($lasterror, ERROR_FILE_NOT_FOUND, '... and sets $^E correctly');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() initially fails with O_WRONLY');
    is($errno, ENOENT, '... and sets $! correctly');
    is($lasterror, ERROR_FILE_NOT_FOUND, '... and sets $^E correctly');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() succeeds with O_WRONLY | O_CREAT') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    ok(print($fh "$str\n"), '... and we can print');

    seek $fh, 0, 0;
    {
        no warnings 'io';
        is(<$fh>, undef, '... but not read');
    }

    close $fh;
    is(-s $file, $strlen + 2, '... and the file is ok');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() now succeeds with O_RDONLY') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    {
        no warnings 'io';
        ok(!print($fh "$str\n"), "... and we can't print");
    }

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    is($line, $str, '... but we can read');

    close $fh;
    is(-s $file, $strlen + 2, '... and the file is still ok');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() now succeeds with O_WRONLY') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    ok(print($fh "$str\n"), '... and we can print');

    seek $fh, 0, 0;
    {
        no warnings 'io';
        is(<$fh>, undef, '... but not read');
    }

    close $fh;
    is(-s $file, $strlen + 2, '... and the file is ok');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_APPEND, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() succeeds with O_WRONLY | O_APPEND') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    ok(print($fh "$str\n"), '... and we can print');

    seek $fh, 0, 0;
    {
        no warnings 'io';
        is(<$fh>, undef, '... but not read');
    }

    close $fh;
    is(-s $file, ($strlen + 2) * 2, '... and the file is ok');

    unlink $file;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() initially fails with O_RDWR');
    is($errno, ENOENT, '... and sets $! correctly');
    is($lasterror, ERROR_FILE_NOT_FOUND, '... and sets $^E correctly');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR | O_CREAT, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() succeeds with O_RDWR | O_CREAT') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    ok(print($fh "$str\n"), '... and we can print');

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    is($line, $str, '... and read');

    close $fh;
    is(-s $file, $strlen + 2, '... and the file is ok');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() now succeeds with O_RDWR') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    ok(print($fh "$str\n"), '... and we can print');

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    is($line, $str, '... and read');

    close $fh;
    is(-s $file, $strlen + 2, '... and the file is ok');

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDWR | O_APPEND, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() succeeds with O_RDWR | O_APPEND') or
        diag("\$! = '$errno', \$^E = '$lasterror'");

    ok(print($fh "$str\n"), '... and we can print');

    seek $fh, 0, 0;
    chomp($line = <$fh>);
    is($line, $str, '... and read');

    close $fh;
    is(-s $file, ($strlen + 2) * 2, '... and the file is ok');

    unlink $file;

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT | O_TEXT, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    is(-s $file, $strlen + 2, 'O_TEXT works');

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_TEXT, SH_DENYNO);
    binmode $fh, ':raw';
    print $fh "$str\n";
    close $fh;
    is(-s $file, $strlen + 1, "O_TEXT and a ':raw' layer works");

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_BINARY, SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    is(-s $file, $strlen + 1, 'O_BINARY works');

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_RAW, SH_DENYNO);
    print $fh "$str\n";
    close $fh;
    is(-s $file, $strlen + 1, 'O_RAW works');

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_BINARY, SH_DENYNO);
    binmode $fh, ':crlf';
    print $fh "$str\n";
    close $fh;
    is(-s $file, $strlen + 2, "O_BINARY and a ':crlf' layer works");

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC | O_RAW, SH_DENYNO);
    binmode $fh, ':crlf';
    print $fh "$str\n";
    close $fh;
    is(-s $file, $strlen + 2, "O_RAW and a ':crlf' layer works");

    unlink $file;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() initially succeeds with O_CREAT | O_EXCL') or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY | O_CREAT | O_EXCL, SH_DENYNO, S_IWRITE);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() now fails with O_CREAT | O_EXCL');
    is($errno, EEXIST, '... and sets $! correctly');
    is($lasterror, ERROR_FILE_EXISTS, '... and sets $^E correctly');

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT | O_TEMPORARY, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    ok(! -e $file, 'O_TEMPORARY works');

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_TRUNC, SH_DENYNO);
    close $fh;
    ok(-e $file, 'O_TRUNC works: file exists');
    is(-s $file, 0, 'O_TRUNC works: file is empty');

    unlink $file;

    $fh = new_fh();
    $ret = sopen($fh, '.', O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() fails reading a directory');
    is($errno, EACCES, '... and sets $! correctly');
    is($lasterror, ERROR_ACCESS_DENIED, '... and sets $^E correctly');

    $fh = new_fh();
    $ret = sopen($fh, '.', O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() fails writing a directory');
    is($errno, EACCES, '... and sets $! correctly');
    is($lasterror, ERROR_ACCESS_DENIED, '... and sets $^E correctly');

    $fh = new_fh();
    sopen($fh, $file, O_WRONLY | O_CREAT, SH_DENYNO, S_IWRITE);
    print $fh "$str\n";
    close $fh;
    chmod 0444, $file;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_RDONLY, SH_DENYNO);
    ($errno, $lasterror) = ($!, $^E);
    ok($ret, 'sopen() succeeds reading a read-only file') or
        diag("\$! = '$errno', \$^E = '$lasterror'");
    close $fh;

    $fh = new_fh();
    $ret = sopen($fh, $file, O_WRONLY, SH_DENYNO);
    ($errno, $lasterror) = ($! + 0, $^E + 0);
    is($ret, undef, 'sopen() fails writing a read-only file');
    is($errno, EACCES, '... and sets $! correctly');
    is($lasterror, ERROR_ACCESS_DENIED, '... and sets $^E correctly');

    unlink $file;
}

#===============================================================================

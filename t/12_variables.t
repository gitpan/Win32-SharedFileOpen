#!perl
#-------------------------------------------------------------------------------
# Copyright (c) 2001-2003, Steve Hay. All rights reserved.
#
# Module Name:  Win32::SharedFileOpen
# Source File:  12_variables.t
# Description:  Test program to check debug and retry variables
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use Test;
use Win32::WinError;

sub _stderr(;$);

BEGIN { plan tests => 62 };             # Number of tests to be executed

use Win32::SharedFileOpen qw(:DEFAULT :retry new_fh);

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
    my( $file,                          # Test file
        $err,                           # Error message from STORE()
        $fh1,                           # Test filehandle 1
        $output,                        # Captured warn() output
        $fh2,                           # Test filehandle 2
        $ret,                           # Return value from fsopen()/sopen()
        $start,                         # Start time for fsopen()/sopen() call
        $finish,                        # Finish time for fsopen()/sopen() call
        $time                           # Time taken for fsopen()/sopen() call
        );

                                        # Test 1: Did we make it this far OK?
    ok(1);

    $file = 'test.txt';
    $err = qr/^Invalid value for '(.*?)': '(.*?)' is not a natural number/;

    $SIG{__WARN__} = \&_stderr;

                                        # Tests 2-14: Check $Debug
    eval {
        $Win32::SharedFileOpen::Debug = '';
    };
    ok($@ =~ $err and $1 eq '$Debug' and $2 eq '');

    eval {
        $Win32::SharedFileOpen::Debug = 'a';
    };
    ok($@ =~ $err and $1 eq '$Debug' and $2 eq 'a');

    eval {
        $Win32::SharedFileOpen::Debug = -1;
    };
    ok($@ =~ $err and $1 eq '$Debug' and $2 eq '-1');

    eval {
        $Win32::SharedFileOpen::Debug = 0.5;
    };
    ok($@ =~ $err and $1 eq '$Debug' and $2 eq '0.5');

    eval {
        $Win32::SharedFileOpen::Debug = undef;
    };
    ok($@ eq '');

    eval {
        $Win32::SharedFileOpen::Debug = 0;
    };
    ok($@ eq '');

    eval {
        $Win32::SharedFileOpen::Debug = 1;
    };
    ok($@ eq '');

    $Win32::SharedFileOpen::Debug = 0;

    _stderr(undef);
    $fh1 = new_fh();
    fsopen($fh1, $file, 'w+', SH_DENYNO);
    close $fh1;
    $output = _stderr();
    ok(not defined $output);

    $Win32::SharedFileOpen::Debug = 1;

    _stderr(undef);
    $fh1 = new_fh();
    fsopen($fh1, $file, 'w+', SH_DENYNO);
    close $fh1;
    $output = _stderr();
    ok(defined $output and $output =~ /_fsopen\(\) on '$file' succeeded/);

    $Win32::SharedFileOpen::Debug = 2;
    unlink $file;

    _stderr(undef);
    $fh1 = new_fh();
    fsopen($fh1, $file, 'r', SH_DENYNO);
    $output = _stderr();
    ok(defined $output and $output =~ /MSVC function _fsopen\(.*\) failed/);

    $Win32::SharedFileOpen::Debug = 0;

    _stderr(undef);
    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    close $fh1;
    $output = _stderr();
    ok(not defined $output);

    $Win32::SharedFileOpen::Debug = 1;

    _stderr(undef);
    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
    close $fh1;
    $output = _stderr();
    ok(defined $output and $output =~ /_sopen\(\) on '$file' succeeded/);

    $Win32::SharedFileOpen::Debug = 2;
    unlink $file;

    _stderr(undef);
    $fh1 = new_fh();
    sopen($fh1, $file, O_RDONLY, SH_DENYNO);
    $output = _stderr();
    ok(defined $output and $output =~ /MSVC function _sopen\(.*\) failed/);

                                        # Tests 15-30: Check $Max_Time
    eval {
        $Max_Time = '';
    };
    ok($@ =~ $err and $1 eq '$Max_Time' and $2 eq '');

    eval {
        $Max_Time = 'a';
    };
    ok($@ =~ $err and $1 eq '$Max_Time' and $2 eq 'a');

    eval {
        $Max_Time = -1;
    };
    ok($@ =~ $err and $1 eq '$Max_Time' and $2 eq '-1');

    eval {
        $Max_Time = 0.5;
    };
    ok($@ =~ $err and $1 eq '$Max_Time' and $2 eq '0.5');

    eval {
        $Max_Time = undef;
    };
    ok($@ eq '');

    eval {
        $Max_Time = 0;
    };
    ok($@ eq '');

    eval {
        $Max_Time = 1;
    };
    ok($@ eq '');

    eval {
        $Max_Time = INFINITE;
    };
    ok($@ eq '');

    $Max_Time = 1;

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w+', SH_DENYRD);

    $fh2 = new_fh();
    $start = time;
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 1 and $time < 2);

    $Max_Time = 3;

    $fh2 = new_fh();
    $start = time;
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 3 and $time < 4);

    close $fh1;

    $Max_Time = 1;

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

    $fh2 = new_fh();
    $start = time;
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 1 and $time < 2);

    $Max_Time = 3;

    $fh2 = new_fh();
    $start = time;
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 3 and $time < 4);

    close $fh1;

                                        # Tests 31-46: Check $Max_Tries
    # Disable off $Max_Time to use $Max_Tries;
    $Max_Time = undef;

    eval {
        $Max_Tries = '';
    };
    ok($@ =~ $err and $1 eq '$Max_Tries' and $2 eq '');

    eval {
        $Max_Tries = 'a';
    };
    ok($@ =~ $err and $1 eq '$Max_Tries' and $2 eq 'a');

    eval {
        $Max_Tries = -1;
    };
    ok($@ =~ $err and $1 eq '$Max_Tries' and $2 eq '-1');

    eval {
        $Max_Tries = 0.5;
    };
    ok($@ =~ $err and $1 eq '$Max_Tries' and $2 eq '0.5');

    eval {
        $Max_Tries = undef;
    };
    ok($@ eq '');

    eval {
        $Max_Tries = 0;
    };
    ok($@ eq '');

    eval {
        $Max_Tries = 1;
    };
    ok($@ eq '');

    eval {
        $Max_Tries = INFINITE;
    };
    ok($@ eq '');

    $Max_Tries = 1;

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w+', SH_DENYRD);

    _stderr(undef);
    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $output = _stderr();
    ok(defined $output and $output =~ /after 1 try/);

    $Max_Tries = 10;

    _stderr(undef);
    $fh2 = new_fh();
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $output = _stderr();
    ok(defined $output and $output =~ /after 10 tries/);

    close $fh1;

    $Max_Tries = 1;

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

    _stderr(undef);
    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $output = _stderr();
    ok(defined $output and $output =~ /after 1 try/);

    $Max_Tries = 10;

    _stderr(undef);
    $fh2 = new_fh();
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $output = _stderr();
    ok(defined $output and $output =~ /after 10 tries/);

    close $fh1;

                                        # Tests 47-62: Check $Retry_Timeout
    # Use $Max_Tries to check $Retry_Timeout.
    $Max_Time  = undef;
    $Max_Tries = 5;

    eval {
        $Retry_Timeout = '';
    };
    ok($@ =~ $err and $1 eq '$Retry_Timeout' and $2 eq '');

    eval {
        $Retry_Timeout = 'a';
    };
    ok($@ =~ $err and $1 eq '$Retry_Timeout' and $2 eq 'a');

    eval {
        $Retry_Timeout = -1;
    };
    ok($@ =~ $err and $1 eq '$Retry_Timeout' and $2 eq '-1');

    eval {
        $Retry_Timeout = 0.5;
    };
    ok($@ =~ $err and $1 eq '$Retry_Timeout' and $2 eq '0.5');

    eval {
        $Retry_Timeout = undef;
    };
    ok($@ eq '');

    eval {
        $Retry_Timeout = 0;
    };
    ok($@ eq '');

    eval {
        $Retry_Timeout = 1;
    };
    ok($@ eq '');

    eval {
        $Retry_Timeout = INFINITE;
    };
    ok($@ eq '');

    $Retry_Timeout = 250;

    $fh1 = new_fh();
    fsopen($fh1, $file, 'w+', SH_DENYRD);

    $fh2 = new_fh();
    $start = time;
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 1 and $time <= 2);

    $Retry_Timeout = 750;

    $fh2 = new_fh();
    $start = time;
    $ret = fsopen($fh2, $file, 'r', SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 3 and $time <= 4);

    close $fh1;

    $Retry_Timeout = 250;

    $fh1 = new_fh();
    sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

    $fh2 = new_fh();
    $start = time;
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 1 and $time <= 2);

    $Retry_Timeout = 750;

    $fh2 = new_fh();
    $start = time;
    $ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
    $finish = time;
    ok(not defined $ret and $!{EACCES} and $^E == ERROR_SHARING_VIOLATION);
    $time = $finish - $start;
    ok($time >= 3 and $time <= 4);

    close $fh1;

    unlink $file;
}

#-------------------------------------------------------------------------------
#
# Subroutines.
#

lexicalscope: {
    my $_stderr;

    sub _stderr(;$) {
        my( $msg,                       # Optional message to store
            ) = @_;

        if (@_) {
            if (defined $msg and defined $_stderr) {
                $_stderr .= $msg;
            }
            else {
                $_stderr  = $msg;
            }
        }

        return $_stderr;
    }
}

1;

#-------------------------------------------------------------------------------

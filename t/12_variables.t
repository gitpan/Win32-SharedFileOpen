#!perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001-2002, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	12_variables.t
# Description:	Test program to check debug and retry variables
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Errno;
use Test;
use Win32::WinError;

BEGIN { plan tests => 35 };				# Number of tests to be executed

use Win32::SharedFileOpen qw(:DEFAULT :retry new_fh);

#-------------------------------------------------------------------------------
#
# Main program.
#

MAIN: {
	my(	$file,							# Test file
		$err1,							# Error message 1 from STORE()
		$err2,							# Error message 2 from STORE()
		$err3,							# Error message 3 from STORE()
		$stderr,						# _CaptureOutput object for STDERR
		$fh1,							# Test filehandle 1
		$output,						# Captured STDERR output
		$fh2,							# Test filehandle 2
		$ret,							# Return value from fsopen()
		$start,							# Start time for fsopen() call
		$finish,						# Finish time for fsopen() call
		$time							# Time taken for fsopen() call
		);

										# Test 1: Did we make it this far OK?
	ok(1);

	$file = 'test.txt';
	$err1 = qr/^Can't set '(.*?)' to the undefined value/;
	$err2 = qr/^Can't set '(.*?)' to the null string/;
	$err3 = qr/^Invalid value for '(.*?)': '(.*?)' is not a natural number/;

	$stderr = tie *STDERR, '_CaptureOutput';

										# Tests 2-5: Check $Debug
	$Win32::SharedFileOpen::Debug = 0;

	$stderr->clear_buffer();
	$fh1 = new_fh();
	fsopen($fh1, $file, 'w+', SH_DENYNO);
	close $fh1;
	$output = $stderr->read_buffer();
	ok(not defined $output);

	$Win32::SharedFileOpen::Debug = 1;

	$stderr->clear_buffer();
	$fh1 = new_fh();
	fsopen($fh1, $file, 'w+', SH_DENYNO);
	close $fh1;
	$output = $stderr->read_buffer();
	ok(defined $output and $output =~ /_fsopen\(\) succeeded after 1 try/);

	$Win32::SharedFileOpen::Debug = 0;

	$stderr->clear_buffer();
	$fh1 = new_fh();
	sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	close $fh1;
	$output = $stderr->read_buffer();
	ok(not defined $output);

	$Win32::SharedFileOpen::Debug = 1;

	$stderr->clear_buffer();
	$fh1 = new_fh();
	sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYNO, S_IWRITE);
	close $fh1;
	$output = $stderr->read_buffer();
	ok(defined $output and $output =~ /_sopen\(\) succeeded after 1 try/);

										# Test 6-20: Check $Max_Tries
	eval {
		$Max_Tries = undef;
	};
	ok($@ =~ $err1 and $1 eq '$Max_Tries');

	eval {
		$Max_Tries = '';
	};
	ok($@ =~ $err2 and $1 eq '$Max_Tries');

	eval {
		$Max_Tries = 'a';
	};
	ok($@ =~ $err3 and $1 eq '$Max_Tries' and $2 eq 'a');

	eval {
		$Max_Tries = -1;
	};
	ok($@ =~ $err3 and $1 eq '$Max_Tries' and $2 eq '-1');

	eval {
		$Max_Tries = 0.5;
	};
	ok($@ =~ $err3 and $1 eq '$Max_Tries' and $2 eq '0.5');

	eval {
		$Max_Tries = INFINITE;
	};
	ok($@ eq '');

	eval {
		$Max_Tries = 1;
	};
	ok($@ eq '');

	$Max_Tries = 1;

	$fh1 = new_fh();
	fsopen($fh1, $file, 'w+', SH_DENYRD);

	$stderr->clear_buffer();
	$fh2 = new_fh();
	$ret = fsopen($fh2, $file, 'r', SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$output = $stderr->read_buffer();
	ok(defined $output and $output =~ /_fsopen\(\) failed after 1 try/);

	$Max_Tries = 10;

	$stderr->clear_buffer();
	$fh2 = new_fh();
	$ret = fsopen($fh2, $file, 'r', SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$output = $stderr->read_buffer();
	ok(defined $output and $output =~ /_fsopen\(\) failed after 10 tries/);

	close $fh1;

	$Max_Tries = 1;

	$fh1 = new_fh();
	sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

	$stderr->clear_buffer();
	$fh2 = new_fh();
	$ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$output = $stderr->read_buffer();
	ok(defined $output and $output =~ /_sopen\(\) failed after 1 try/);

	$Max_Tries = 10;

	$stderr->clear_buffer();
	$fh2 = new_fh();
	$ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$output = $stderr->read_buffer();
	ok(defined $output and $output =~ /_sopen\(\) failed after 10 tries/);

	close $fh1;

										# Test 21-35: Check $Retry_Timeout
	eval {
		$Retry_Timeout = undef;
	};
	ok($@ =~ $err1 and $1 eq '$Retry_Timeout');

	eval {
		$Retry_Timeout = '';
	};
	ok($@ =~ $err2 and $1 eq '$Retry_Timeout');

	eval {
		$Retry_Timeout = 'a';
	};
	ok($@ =~ $err3 and $1 eq '$Retry_Timeout' and $2 eq 'a');

	eval {
		$Retry_Timeout = -1;
	};
	ok($@ =~ $err3 and $1 eq '$Retry_Timeout' and $2 eq '-1');

	eval {
		$Retry_Timeout = 0.5;
	};
	ok($@ =~ $err3 and $1 eq '$Retry_Timeout' and $2 eq '0.5');

	eval {
		$Retry_Timeout = INFINITE;
	};
	ok($@ eq '');

	eval {
		$Retry_Timeout = 1;
	};
	ok($@ eq '');

	$Retry_Timeout = 250;

	$fh1 = new_fh();
	fsopen($fh1, $file, 'w+', SH_DENYRD);

	$fh2 = new_fh();
	$start = time;
	$ret = fsopen($fh2, $file, 'r', SH_DENYNO);
	$finish = time;
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$time = $finish - $start;
	ok($time >= 2 and $time <= 3);

	$Retry_Timeout = 1000;

	$fh2 = new_fh();
	$start = time;
	$ret = fsopen($fh2, $file, 'r', SH_DENYNO);
	$finish = time;
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$time = $finish - $start;
	ok($time >= 9 and $time <= 11);

	close $fh1;

	$Retry_Timeout = 250;

	$fh1 = new_fh();
	sopen($fh1, $file, O_WRONLY | O_CREAT | O_TRUNC, SH_DENYRD, S_IWRITE);

	$fh2 = new_fh();
	$start = time;
	$ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	$finish = time;
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$time = $finish - $start;
	ok($time >= 2 and $time <= 3);

	$Retry_Timeout = 1000;

	$fh2 = new_fh();
	$start = time;
	$ret = sopen($fh2, $file, O_RDONLY, SH_DENYNO);
	$finish = time;
	ok(not defined $ret and $!{EACCES} and $ == ERROR_SHARING_VIOLATION);
	$time = $finish - $start;
	ok($time >= 9 and $time <= 11);

	close $fh1;

	undef $stderr;
	untie *STDERR;

	unlink $file;
}

#-------------------------------------------------------------------------------
#
# Package to tie() a filehandle to capture any output sent to it into a buffer.
#

package _CaptureOutput;

use Tie::Handle;

BEGIN {
	our @ISA = qw(Tie::StdHandle);
}

sub TIEHANDLE {
	my(	$class							# Invocant class
		) = @_;

	my(	$self							# New object
		);

	return bless \$self, $class;
}

sub WRITE {
	my(	$self,							# Invocant object
		$buffer,						# Buffer to write some data of
		$length,						# Length of data to write
		$offset							# Offset of data to write from
		) = @_;

	$$self .= substr($buffer, $offset, $length);
}

sub read_buffer {
	my(	$self							# Invocant object
		) = @_;

	return $$self;
}

sub clear_buffer {
	my(	$self							# Invocant object
		) = @_;

	$$self = undef;
}

1;

#-------------------------------------------------------------------------------

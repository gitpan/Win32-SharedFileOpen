#!/bin/perl
#-------------------------------------------------------------------------------
# Copyright (c)	2001, Steve Hay. All rights reserved.
#
# Module Name:	Win32::SharedFileOpen
# Source File:	Makefile.PL
# Description:	Makefile creation program
#-------------------------------------------------------------------------------

use 5.006;

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

BEGIN {
	unless ($Config{osname} =~ /MSWin32/i and $Config{libc} =~ /msvcrt/i) {
		die "This module requires Microsoft Visual C to build.\n";
	}
}

#-------------------------------------------------------------------------------
#
# Main program.
#


MAIN: {
	WriteMakefile(
		NAME			=> 'Win32::SharedFileOpen',
		VERSION_FROM	=> 'SharedFileOpen.pm',
		PREREQ_PM		=> { Win32 => 0 },
		dist			=> { DIST_CP => 'cp' }
	);
}

#-------------------------------------------------------------------------------

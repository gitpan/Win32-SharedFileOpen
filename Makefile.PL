#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation program.
#
# COPYRIGHT
#   Copyright (c) 2001-2004, Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use Config;
use inc::Module::Install;

#===============================================================================
# INITIALISATION
#===============================================================================

BEGIN {
    unless ($Config{osname} =~ /MSWin32/i and $Config{cc} =~ /cl/i) {
        die "This module requires Microsoft Visual C to build.\n";
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    name           ('Win32-SharedFileOpen');
    abstract       ('Open a file for shared reading and/or writing');
    version_from   ('lib/Win32/SharedFileOpen.pm');
    author         ('Steve Hay <shay@cpan.org>');
    license        ('perl');
    perl_version   (5.006000);
    requires       ('Carp');
    requires       ('Exporter');
    requires       ('Symbol');
    requires       ('Win32');
    requires       ('Win32::WinError');
    requires       ('XSLoader');
    build_requires ('Errno');
    build_requires ('File::Copy');
    build_requires ('File::Spec');
    build_requires ('FileHandle');
    build_requires ('IO::File');
    build_requires ('IO::Handle');
    build_requires ('Test');
    recommends     ('Test::Pod' => 1.00);
    clean_files    ('const-c.inc const-xs.inc');

    WriteMakefile(
        dist => {
            DIST_CP  => 'cp',
            PREOP    => 'chmod -R a-x+rwX,go-w $(DISTVNAME)',
            COMPRESS => 'gzip -9fv',
            SUFFIX   => '.gz',
            ZIPFLAGS => '-9r'
        }
    );

    if  (eval { require ExtUtils::Constant; 1 }) {
        ExtUtils::Constant::WriteConstants(
            NAME => 'Win32::SharedFileOpen',

            NAMES => [ {
                name => 'INFINITE',
                type => 'UV'
            }, qw(
                O_APPEND
                O_BINARY
                O_CREAT
                O_EXCL
                O_NOINHERIT
                O_RANDOM
                O_RAW
                O_RDONLY
                O_RDWR
                O_SEQUENTIAL
                O_SHORT_LIVED
                O_TEMPORARY
                O_TEXT
                O_TRUNC
                O_WRONLY
                S_IREAD
                S_IWRITE
                SH_DENYNO
                SH_DENYRD
                SH_DENYRW
                SH_DENYWR
            ) ],

            DEFAULT_TYPE => 'IV',

            C_FILE => 'const-c.inc',

            XS_FILE => 'const-xs.inc'
        );
    }
    else {
        require File::Copy;
        require File::Spec;

        foreach my $file ('const-c.inc', 'const-xs.inc') {
            my $fallback_file = File::Spec->catfile('fallback', $file);
            File::Copy::copy($fallback_file, $file) or
                die "Can't copy '$fallback_file' to '$file': $!.\n";
        }
    }
}

#===============================================================================

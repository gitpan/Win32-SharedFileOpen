#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
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

use inc::Module::Install;

#===============================================================================
# INITIALISATION
#===============================================================================

BEGIN {
    unless ($^O =~ /MSWin32/i) {
        die qq{This module requires a "native" (i.e. non-Cygwin) Microsoft } .
            qq{Windows platform.\n};
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    name           ('Win32-SharedFileOpen');
    abstract_from  ('lib/Win32/SharedFileOpen.pm');
    version_from   ('lib/Win32/SharedFileOpen.pm');
    author         ('Steve Hay <shay@cpan.org>');
    license        ('perl');
    perl_version   (5.006000);
    requires       ('Win32::WinError');
    features       ('POD testing' => [
        -default   => 0,
        recommends ('Test::Pod' => '1.00')
    ]);
    include        ('ExtUtils::AutoInstall');
    clean_files    ('const-c.inc const-xs.inc');

    my $obj = get_shay_private_obj();
    $obj->check_compiler(1);

    auto_install();

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

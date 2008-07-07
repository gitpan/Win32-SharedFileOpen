#!perl
#===============================================================================
#
# Makefile.PL
#
# DESCRIPTION
#   Makefile creation script.
#
# COPYRIGHT
#   Copyright (C) 2001-2008 Steve Hay.  All rights reserved.
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

use Config qw(%Config);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile updir);

#===============================================================================
# INITIALIZATION
#===============================================================================

BEGIN {
    unless ($^O =~ /MSWin32/i) {
        die qq{OS unsupported: This module requires a "native" } .
            qq{(i.e. non-Cygwin) Microsoft Windows platform.\n};
    }
}

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    name          ('Win32-SharedFileOpen');
    license       ('perl');
    all_from      ('lib/Win32/SharedFileOpen.pm');
    requires      ('Win32::WinError');
    test_requires ('Test::More');
    feature       ('POD testing' => [
                   -default    => 0,
                   'Test::Pod' => '1.00'
    ]);
    clean_files   ('const-c.inc const-xs.inc');

    my $obj = get_shay_private_obj();
    $obj->check_compiler(1);

    auto_install();

    WriteMakefile(
        dist => {
            DIST_CP  => 'cp',
            PREOP    => 'C:\\cygwin\\bin\\chmod -R a+w $(DISTVNAME) && ' .
                        'C:\\cygwin\\bin\\find $(DISTVNAME) -type f ' .
                        '-exec C:\\cygwin\\bin\\unix2dos {} ; && ' .
                        'C:\\cygwin\\bin\\chmod -R a-x+rwX,go-w $(DISTVNAME)',
            TAR      => 'C:\\cygwin\\bin\\tar',
            COMPRESS => 'C:\\cygwin\\bin\\gzip --best'
        }
    );

    if  (eval { require ExtUtils::Constant; 1 }) {
        my @oflags = qw(
            O_APPEND
            O_BINARY
            O_CREAT
            O_EXCL
            O_NOINHERIT
            O_RAW
            O_RDONLY
            O_RDWR
            O_TEXT
            O_TRUNC
            O_WRONLY
            S_IREAD
            S_IWRITE
            SH_DENYNO
            SH_DENYRD
            SH_DENYRW
            SH_DENYWR
        );

        # Borland C++ (as of 5.5.1) doesn't support the following flags, so
        # don't try to export them.
        if ($Config{cc} !~ /bcc32/io) {
            push @oflags, qw(
                O_RANDOM
                O_SEQUENTIAL
                O_SHORT_LIVED
                O_TEMPORARY
            );
        }

        ExtUtils::Constant::WriteConstants(
            NAME => 'Win32::SharedFileOpen',

            NAMES => [ {
                name => 'INFINITE',
                type => 'UV'
            },  @oflags ],

            DEFAULT_TYPE => 'IV',

            C_FILE => 'const-c.inc',

            XS_FILE => 'const-xs.inc'
        );
    }
    else {
        foreach my $file ('const-c.inc', 'const-xs.inc') {
            my $fallback_file = catfile('fallback', $file);
            copy($fallback_file, $file) or
                die "Can't copy '$fallback_file' to '$file': $!.\n";
        }
    }
}

#===============================================================================

#!perl
#===============================================================================
#
# t/13_pod.t
#
# DESCRIPTION
#   Test script to check POD.
#
# COPYRIGHT
#   Copyright (C) 2004-2005 Steve Hay.  All rights reserved.
#
# LICENCE
#   You may distribute under the terms of either the GNU General Public License
#   or the Artistic License, as specified in the LICENCE file.
#
#===============================================================================

use 5.006000;

use strict;
use warnings;

use Test::More;

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    eval {
        require Test::Pod;
        Test::Pod->import();
    };

    if ($@) {
        plan skip_all => 'Test::Pod required to test POD';
    }
    elsif ($Test::Pod::VERSION < 1.00) {
        plan skip_all => 'Test::Pod 1.00 or higher required to test POD';
    }
    else {
        all_pod_files_ok();
    }
}

#===============================================================================

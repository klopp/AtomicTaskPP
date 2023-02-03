#!/usr/bin/perl

# ------------------------------------------------------------------------------
use strict;
use warnings;
use lib q{.};

use atomicPP;
use Const::Fast;
use English qw/-no_match_vars/;
use File::Basename qw/basename/;
use Mutex;
use Sys::Info;
use threads;

# ------------------------------------------------------------------------------
const my $FILE    => './' . basename($PROGRAM_NAME) . '.dat';
const my $MUTEX   => Mutex->new;
const my $THREADS => Sys::Info->new->device('CPU')->count - 1 || 2;

# ------------------------------------------------------------------------------
threads->create(
    \&atomicPP::modify_file,
    {   id    => int( rand 100_000 ) + 1,
        mutex => $MUTEX,
        file  => $FILE
    },
) for 1 .. $THREADS;
$_->join for threads->list;

# ------------------------------------------------------------------------------
__END__

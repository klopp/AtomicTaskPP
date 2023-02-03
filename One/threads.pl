#!/usr/bin/perl

# ------------------------------------------------------------------------------
use strict;
use warnings;
use lib q{.};

use AtomicTaskPP;
use Const::Fast;
use English qw/-no_match_vars/;
use File::Basename qw/basename/;
use File::Touch;
use Mutex;
use Sys::Info;
use threads;

# ------------------------------------------------------------------------------
const my $FILE    => '../data/' . basename($PROGRAM_NAME) . '.dat';
const my $MUTEX   => Mutex->new;
const my $THREADS => Sys::Info->new->device('CPU')->count - 1 || 2;

# ------------------------------------------------------------------------------
srand;
touch $FILE;
threads->create(
    \&AtomicTaskPP::modify_file,
    {   id    => int( rand 100_000 ) + 1,
        mutex => $MUTEX,
        file  => $FILE
    },
) for 1 .. $THREADS;
$_->join for threads->list;

# ------------------------------------------------------------------------------
__END__

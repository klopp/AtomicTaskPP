#!/usr/bin/perl

# ------------------------------------------------------------------------------
use strict;
use warnings;
use lib q{.};

use atomic;
use Const::Fast;
use English qw/-no_match_vars/;
use File::Basename qw/basename/;
use Mutex;
use Parallel::ForkManager;
use Sys::Info;

# ------------------------------------------------------------------------------
const my $CHILDREN => Sys::Info->new->device('CPU')->count - 1 || 2;
const my $FILE     => './' . basename($PROGRAM_NAME) . '.dat';
const my $LOCKFILE => '/tmp/' . basename($PROGRAM_NAME) . q{.} . $PID . '.lock';
const my $MUTEX    => Mutex->new( path => $LOCKFILE );

# ------------------------------------------------------------------------------
my $pm = Parallel::ForkManager->new($CHILDREN);
for ( 1 .. $CHILDREN ) {
    my $pid = $pm->start and next;
    atomic::modify_file( { id => $PID, mutex => $MUTEX, file => $FILE } );
    $pm->finish;
}
$pm->wait_all_children;
unlink $LOCKFILE;

# ------------------------------------------------------------------------------
__END__

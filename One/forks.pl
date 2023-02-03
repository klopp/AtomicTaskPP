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
use File::Util::Tempdir qw/get_tempdir get_user_tempdir/;
use Mutex;
use Parallel::ForkManager;
use Sys::Info;
use Try::Tiny;

# ------------------------------------------------------------------------------
const my $CHILDREN => Sys::Info->new->device('CPU')->count - 1 || 2;
const my $FILE     => '../data/' . basename($PROGRAM_NAME) . '.dat';
my $LOCKFILE;
try {
    $LOCKFILE = get_tempdir || get_user_tempdir;
}
catch {
    $LOCKFILE = q{.};
}
finally {
    $LOCKFILE .= q{/} . basename($PROGRAM_NAME) . q{.} . $PID . '.lock';
};
const my $MUTEX => Mutex->new( path => $LOCKFILE );

# ------------------------------------------------------------------------------
touch $FILE;
my $pm = Parallel::ForkManager->new($CHILDREN);
for ( 1 .. $CHILDREN ) {
    my $pid = $pm->start and next;
    AtomicTaskPP::modify_file( { id => $PID, mutex => $MUTEX, file => $FILE } );
    $pm->finish;
}
$pm->wait_all_children;
unlink $LOCKFILE;

# ------------------------------------------------------------------------------
__END__

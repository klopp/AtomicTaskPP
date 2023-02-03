#!/usr/bin/perl

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Const::Fast;
use English qw/-no_match_vars/;
use File::Basename qw/basename/;
use File::Touch;
use Mutex;
use Parallel::ForkManager;
use Sys::Info;

use lib q{.};
use Resource::File;

# ------------------------------------------------------------------------------
const my $CHILDREN => Sys::Info->new->device('CPU')->count - 1 || 2;
const my $DATADIR  => '../data/';
const my $DATAFILE => $DATADIR . '%u.dat';
const my $LOCKFILE => $DATADIR . basename($PROGRAM_NAME) . q{.} . $PID . '.lock';
const my $MUTEX    => Mutex->new( path => $LOCKFILE );
const my $TEMPDIR  => q{.};

# ------------------------------------------------------------------------------
unlink glob $DATADIR . q{*};
my $pm = Parallel::ForkManager->new($CHILDREN);
for ( 0 .. $CHILDREN ) {
    my $pid = $pm->start and next;
    srand;
    my ( $id1, $id2 ) = ( int( rand 100_000 ) + 1, int( rand 100_000 ) + 1 );
    my ( $file1, $file2 ) = ( sprintf( $DATAFILE, $id1 ), sprintf( $DATAFILE, $id2 ) );
    touch $file1, $file2;
    Task->new(
        [   Resource::File->new( { mutex => $MUTEX, source => $file1, tempdir => $TEMPDIR, id => $id1, } ),
            Resource::File->new( { mutex => $MUTEX, source => $file2, tempdir => $TEMPDIR, id => $id2, } ),
        ]
    )->run;
    $pm->finish;
}
$pm->wait_all_children;

# ------------------------------------------------------------------------------
package Task;
use AtomicTask;
use parent qw/AtomicTask/;

# ------------------------------------------------------------------------------
sub execute
{
    my ($self) = @_;
    for ( @{ $self->{resources} } ) {
        printf "Task ID: %s, resource ID: %s\n", $self->id, $_->id;
        print { $_->{workh} } $_->id;
        truncate $_->{workh}, length $_->id;
        $_->{modified} = 1;
    }
    return;
}

# ------------------------------------------------------------------------------
__END__

#!/usr/bin/perl

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Const::Fast;
use File::Touch;
use Mutex;
use Sys::Info;
use threads;

use lib q{.};
use Resource::File;

# ------------------------------------------------------------------------------
const my $DATADIR  => '../data/';
const my $DATAFILE => $DATADIR . '%u.dat';
const my $MUTEX    => Mutex->new;
const my $THREADS  => Sys::Info->new->device('CPU')->count - 1 || 2;
const my $TEMPDIR  => q{.};
my @tasks;

# ------------------------------------------------------------------------------
unlink glob $DATADIR . q{*};
srand;
for ( 1 .. $THREADS ) {
    my ( $id1, $id2 ) = ( int( rand 100_000 ) + 1, int( rand 100_000 ) + 1 );
    my ( $file1, $file2 ) = ( sprintf( $DATAFILE, $id1 ), sprintf( $DATAFILE, $id2 ) );
    touch $file1, $file2;
    push @tasks,
        Task->new(
        [   Resource::File->new( { mutex => $MUTEX, source => $file1, tempdir => $TEMPDIR, id => $id1, } ),
            Resource::File->new( { mutex => $MUTEX, source => $file2, tempdir => $TEMPDIR, id => $id2, } ),
        ]
        );
}

threads->create( sub { $_->run } ) for @tasks;
$_->join for threads->list;

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

#!/usr/bin/perl

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Const::Fast;
use Sys::Info;
use threads;
use threads::shared;

use lib q{..};
use Atomic::Resource::Data;
use Atomic::Mutex::LinuxFutex;

# ------------------------------------------------------------------------------
const my $THREADS => Sys::Info->new->device('CPU')->count - 1 || 2;
const my $MUTEX   => Atomic::Mutex::LinuxFutex->new;
my @tasks;

# ------------------------------------------------------------------------------
my $data1 :shared = '123';
my $data2 :shared = '456';

for ( 1 .. $THREADS ) { 
    my ( $id1, $id2 ) = ( int( rand 100_000 ) + 1, int( rand 100_000 ) + 1 );
    push @tasks,
        Task->new(
        [   Atomic::Resource::Data->new( { source => \$data1, id => $id1, }, ),
            Atomic::Resource::Data->new( { source => \$data2, id => $id2, }, ),
        ],
        { mutex => $MUTEX, quiet => 1, },
        );
}

threads->create( sub { 
    $_->run;
    printf "Data: '%s'\n", $data1;
    printf "Data: '%s'\n", $data2;
     } ) for @tasks;
$_->join for threads->list;

# ------------------------------------------------------------------------------
package Task;
use lib q{..};
use Atomic::Task;
use parent qw/Atomic::Task/;

sub execute
{
    my ($self) = @_;
    for ( @{ $self->{resources} } ) {
        $_->{work} = sprintf "Task ID: %s, resource ID: %s", $self->id, $_->id;
        $_->modified;
    }
    return;
}

# ------------------------------------------------------------------------------
__END__

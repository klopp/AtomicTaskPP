#!/usr/bin/perl

# ------------------------------------------------------------------------------
use Modern::Perl;

use Const::Fast;
use Parallel::ForkManager;
use Sys::Info;

use lib q{..};
use Atomic::Resource::Data;
use Atomic::Mutex::JipLockSocket;

# ------------------------------------------------------------------------------
const my $CHILDREN => Sys::Info->new->device('CPU')->count - 1 || 2;
const my $MUTEX => Atomic::Mutex::JipLockSocket->new( port => 5005 );

# ------------------------------------------------------------------------------
my $pm = Parallel::ForkManager->new($CHILDREN);
for ( 1 .. $CHILDREN ) {
    my $pid = $pm->start and next;
    srand;
    my ( $id1, $id2 ) = ( int( rand 100_000 ) + 1, int( rand 100_000 ) + 1 );
    my ( $data1, $data2 ) = ( $id1, $id2 );
    printf "Resource '%s', data: '%s'\n", $id1, $data1;
    printf "Resource '%s', data: '%s'\n", $id2, $data2;
    Task->new(
        [   Atomic::Resource::Data->new( { source => \$data1, id => $id1, } )
        ,
            Atomic::Resource::Data->new( { source => \$data2, id => $id2, } ),
        ],
        { mutex => $MUTEX, },
    )->run;
    printf "Resource '%s', data: '%s'\n", $id1, $data1;
    printf "Resource '%s', data: '%s'\n", $id2, $data2;
    $pm->finish;
}
$pm->wait_all_children;

# ------------------------------------------------------------------------------
package Task;
use lib q{..};
use Atomic::Task;
use parent qw/Atomic::Task/;

# ------------------------------------------------------------------------------
sub execute
{
    my ($self) = @_;
    for ( @{ $self->{resources} } ) {
        $_->{work} = sprintf "Task ID: %s, resource ID: %s", $self->id, $_->id;
        $_->{modified} = 1;
    }
    return;
}

# ------------------------------------------------------------------------------
__END__

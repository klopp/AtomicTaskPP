#!/usr/bin/perl

# ------------------------------------------------------------------------------
use Modern::Perl;

use Const::Fast;
use DDP;
use Mutex;
use Sys::Info;
use threads;

use lib q{.};
use Resource::Data;


# ------------------------------------------------------------------------------
#my $bkp = 'bkp';
#my $data = 'data';
#tie $data, 'DataScalar', $bkp;
#say $data;
#exit;
# ------------------------------------------------------------------------------
my $data1 = '1';
my $rd = Resource::Data->new( { source => \$data1, }, );
=for comment
$rd->create_backup_copy;
$rd->{modified} = 1;
$rd->{work} = '123';
$rd->commit;
say $data1;
$rd->rollback;
say $data1;
=cut
my $dt = Task->new( [$rd], { quiet => 1, }, );
$dt->run;
say $data1;

# ------------------------------------------------------------------------------
package Task;
use AtomicTaskPP;
use parent qw/AtomicTaskPP/;
use DDP;

sub execute
{
    my ($self) = @_;
    for my $rs ( @{ $self->{resources} } ) {

        $rs->{work} = 'execute';
        $rs->{modified} = 1;
    }
    return;
}

# ------------------------------------------------------------------------------
package DataScalar;
use Scalar::Util qw/reftype/;
use DDP;
sub TIESCALAR 
{ 
    my ( $class, $data ) = @_;
    
    say sprintf '{%s} {%s}', ref $data, reftype $data;
    
    bless \$data, $class; 
}

sub STORE 
{ 
    #p @_;
    ${ $_[0] } = $_[1] 
}

sub FETCH 
{ 
    p @_;
    ${ my $self = shift } 
}

# ------------------------------------------------------------------------------
__END__

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
#my $data1 = '1';
my $data1 = { a => 2, b => [ 1,2,3, {c => { d => 9 } } ] };
say np $data1;
my $rd = Resource::Data->new( { source => \$data1, }, );
=for comment
$rd->create_backup_copy;
$rd->{modified} = 1;
$rd->{work} = [9,9,9];
$rd->commit;
p $data1;
$rd->rollback;
p $data1;
=cut
my $dt = Task->new( [$rd], { quiet => 1, }, );
$dt->run;
say np $data1;

# ------------------------------------------------------------------------------
package Task;
use AtomicTaskPP;
use parent qw/AtomicTaskPP/;
use DDP;

sub execute
{
    my ($self) = @_;
    for my $rs ( @{ $self->{resources} } ) {

        $rs->{work}->{b}->[3] = [4,5,6];
        $rs->{modified} = 1;
    }
    return;
}

# ------------------------------------------------------------------------------
__END__

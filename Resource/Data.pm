package Resource::Data;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp;
use Clone qw/clone/;
#use Data::Clone;
#use Data::Peek;
use DDP;

use lib q{..};
use Resource::Base;
use base qw/Resource::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source}
    В {params} МОЖЕТ быть:
        {id}
    Структура после полной инициализации:
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
#    ${$params->{source}} = 'ggg';
    $params->{backup} = ${$params->{source}};
    tie $params->{source}, 'Resource::DataScalar', \$params->{backup};
    
    my $self = $class->SUPER::new($params);
#    print DDump($params->{source});
#    print "\n\n";
#    print DDump($self->{params}->{source});
#    print "\n\n";
#    ${$params->{source}} = 'hhh';
#    ${$self->{params}->{source}} = 'iii';
#    print DDump($params->{source});
#    print "\n\n";
#    print DDump($self->{params}->{source});
#    print "\n\n";
    return $self;
}

# ------------------------------------------------------------------------------
sub check_params
{
    my ($self) = @_;
    #${$self->{params}->{source}} = 'fff';
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;
####    $self->{backup} = clone( $self->{source} );
    return;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{
    my ($self) = @_;
    delete $self->{backup};
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;
    $self->{work} = '$self->{work}';
####    $self->{work} = clone( $self->{source} );
    return;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{
    my ($self) = @_;
    delete $self->{work};
    return;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
#    printf "pre\n%s", np $self->{params}->{source};
#    printf "commit\n%s", np $self->{work};
#    ${$self->{params}->{source}} = clone( $self->{work} );
#    print np( $self->{params}->{source} ); 
#    ${$self->{params}->{source}} = $self->{work};
#    $self->{params}->{source} = clone( $self->{work} );
#    ${$self->{source}} = clone($self->{work});
#    printf "rs<src>  :: %s\n", np ${$self->{source}};
#    $self->{params}->{source} = clone($self->{work});
#    $self->{params}->{source} = [8,8,8]; #clone($self->{work});
#p ${$self->{params}->{source}};
    ${$self->{params}->{source}} = 'eee';
#p ${$self->{params}->{source}};
#    printf "res\n%s", np $self->{params}->{source};
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    $self->{params}->{source} = clone( $self->{backup} );
    return;
}

# ------------------------------------------------------------------------------
package Resource::DataScalar;
=for comment
use Tie::Scalar;
use parent qw/Tie::Scalar/;

sub new
{
    my ($class, @data) = @_;
    use DDP;
    p @data;
    return bless {}, $class;
}
=cut
sub TIESCALAR { bless \my $self, shift }
sub STORE { ${ $_[0] } = $_[1] }  # do the default thing
sub FETCH { ${ my $self = shift } } # round value

# ------------------------------------------------------------------------------
1;
__END__

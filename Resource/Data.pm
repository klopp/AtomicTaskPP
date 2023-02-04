package Resource::Data;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Clone qw/clone/;

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
    my $self = $class->SUPER::new($params);
    return $self;
}

# ------------------------------------------------------------------------------
sub check_params
{
    my ($self) = @_;
    ref $self->{params}->{source} eq 'REF' or return '{params}->{source} is not REF';
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;
    $self->{backup} = clone( ${ $self->{params}->{source} } );
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
    $self->{work} = clone( ${ $self->{params}->{source} } );
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
    $self->{work} and ${ $self->{params}->{source} } = clone( $self->{work} );
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    $self->{backup} and ${ $self->{params}->{source} } = clone( $self->{backup} );
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

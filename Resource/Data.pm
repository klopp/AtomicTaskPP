package Resource::Data;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Data::Clone qw/clone/;

use lib q{..};
use Resource::Base;
use base qw/Resource::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source} ссылка на скаляр, массив или хэш любой степени 
                    вложенности 
                    может быть blessed, желательно с методом clone()
    В {params} МОЖЕТ быть:
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    return $class->SUPER::new($params);
}

# ------------------------------------------------------------------------------
sub check_params
{
    my ($self) = @_;

    if (   ref $self->{params}->{source} ne 'REF'
        && ref $self->{params}->{source} ne 'SCALAR' )
    {

        return 'ref {params}->{source} is not REF or SCALAR';
    }
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

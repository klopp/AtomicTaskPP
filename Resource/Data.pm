package Resource::Data;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp qw/cluck/;
use Clone qw/clone/;
use Scalar::Util qw/blessed/;

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
        {quiet} не выводить предупреждения
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    my $blessed = blessed ${ $params->{source} };
    if ( $blessed && !$blessed->can('clone') ) {
        $params->{quiet}
            or cluck sprintf 'Data :: %s->clone() is not defined, object cloning may be inaccurate!', $blessed;
    }
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
sub _clone
{
    my ( $self, $src ) = @_;
    ( blessed $src && $src->can('clone') ) and return $src->clone;
    return clone $src;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;
    $self->{backup} = $self->_clone( ${ $self->{params}->{source} } );
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
    $self->{work} = $self->_clone( ${ $self->{params}->{source} } );
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
    $self->{work} and ${ $self->{params}->{source} } = $self->_clone( $self->{work} );
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    $self->{backup} and ${ $self->{params}->{source} } = $self->_clone( $self->{backup} );
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

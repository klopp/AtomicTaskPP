package Resource::Base;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp qw/cluck/;

#use Clone qw/clone/;
#use Data::Clone;
#use Storable qw/dclone/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    Базовый класс для работы с ресурсами. Обеспечивает:
    * создание резервной копии ресурса для отката изменений
    * создание рабочей копии ресурса, в которой производятся все изменения
    * замену ресурса на рабочую копию поле внесения изменений
    * замену ресурса на резервную копию при неудаче предыдущего пункта
=cut

    my ( $class, $params ) = @_;
    $params //= {};
    ref $params eq 'HASH' or cluck 'Invalid {params} value.';
    $params->{source}     or cluck 'No {source} in {params}.';
    $params->{id}         or $params->{id} = int( rand 100_000 );

=for comment
    my %data = ( modified => 0, params => $params );
    my $self = bless \%data, $class;
=cut

    my $self = bless {
        params   => $params,
        modified => 0,
        },
        $class;
    my $error = $self->check_params;
    $error and cluck sprintf 'Invalid parameters: %s', $error;
    return $self;
}

# ------------------------------------------------------------------------------
sub id
{
    my ($self) = @_;
    return $self->{params}->{id};
}

# ------------------------------------------------------------------------------
sub modified
{
    my ($self) = @_;
    return $self->{modified};
}

# ------------------------------------------------------------------------------
sub _emethod
{
    my ($self) = @_;
    return cluck sprintf 'Method "$error = %s()" must be overloaded.', ( caller 1 )[3];
}

# ------------------------------------------------------------------------------
sub check_params
{

=for comment
    Проверка входных параметров. ДОЛЖЕН быть перегружен в 
    производных объектах.
    NB! Проверка {params}->{source} происходит в базовом конструкторе.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{

=for comment
    Создание копии ресурса для отката. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{

=for comment
    Удаление копии ресурса для отката. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{

=for comment
    Создание рабочей копии ресурса для модификации. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{

=for comment
    Удаление рабочей копии ресура. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub commit
{

=for comment
    Замена ресурса на рабочую копию. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub rollback
{

=for comment
    Замена ресурса на резервную копию. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
1;
__END__

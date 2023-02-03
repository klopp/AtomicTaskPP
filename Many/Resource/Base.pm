package Resource::Base;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;

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
    croak 'Invalid {params} value.' unless ref $params eq 'HASH';
    $params->{id} = int(rand 100_000) unless $params->{id};
    my %self = ( modified => 0, params => $params );
    my $obj  = bless \%self, $class;
    my $error = $obj->check_params;
    croak sprintf 'Invalid parameters: %s', $error if $error;
    return $obj;
}

# ------------------------------------------------------------------------------
sub is_modified
{
    my ($self) = @_;
    return $self->{modified};
}

# ------------------------------------------------------------------------------
sub _emethod
{
    my ($self) = @_;
    return croak sprintf 'Method "$error = %s()" must be overloaded.', ( caller 1 )[3];
}

# ------------------------------------------------------------------------------
sub id
{
    my ($self) = @_;
    return $self->{params}->{id};
}

# ------------------------------------------------------------------------------
sub check_params
{
=for comment
    Проверка входных параметров. ДОЛЖЕН быть перегружен в 
    производных объектах.
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

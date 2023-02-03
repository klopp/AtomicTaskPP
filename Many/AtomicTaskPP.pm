package AtomicTaskPP;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;

use lib q{.};
use Resource::Base;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} МОЖЕТ быть:
        {mutex}
        {commit_lock} лочить только коммит
        {quiet}       не выводить предупреждения
        {id}
    Структура после полной инициализации:
        {resources}
        {params}
        {id}
=cut    

    my ( $class, $resources, $params ) = @_;

    $params //= {};
    croak 'Invalid {resources} value' unless ref $resources eq 'ARRAY';
    croak 'Invalid {params} value'    unless ref $params eq 'HASH';
    croak 'Invalid {resources} value' if ref $resources ne 'ARRAY' || !@{$resources};

    srand;
    $params->{id} = int( rand 100_000 ) unless $params->{id};

    if ( $params->{mutex} ) {
        croak '{mutex} can not lock()!'   unless $params->{mutex}->can('lock');
        croak '{mutex} can not unlock()!' unless $params->{mutex}->can('unlock');
    }
    else {
        carp 'Warning: no {mutex} in parameters list, multi-threaded code may not be safe!'
            unless $params->{quiet};
    }

    my %self = (
        resources => $resources,
        params    => $params,
    );

    return bless \%self, $class;
}

# ------------------------------------------------------------------------------
sub id
{
    my ($self) = @_;
    return $self->{params}->{id};
}

# ------------------------------------------------------------------------------
sub run
{
    my ( $error, $self ) = ( undef, @_ );
    for ( my $i = 0; $i < @{ $self->{resources} }; ++$i ) {
        my $rs = $self->{resources}->[$i];

=for comment
    Создаём копию ресурса для отката
=cut

        $error = $rs->create_backup_copy;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

        if ($error) {
            if ($i) {
                $self->_delete_backups( $i - 1 );
                $self->_delete_works( $i - 1 );
            }
            return croak sprintf "Error creating backup copy: %s\n", $error;
        }

=for comment
    Создаём рабочую копию ресурса
=cut

        $error = $rs->create_work_copy;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

        if ($error) {
            $self->_delete_backups($i);
            $self->_delete_works( $i - 1 ) if $i;
            return croak sprintf "Error creating work copy: %s\n", $error;
        }
    }
    $self->{params}->{mutex}->lock if $self->{params}->{mutex} && !$self->{params}->{commit_lock};

=for comment
    Модифицируем реурсы
=cut

    $error = $self->execute;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

    if ($error) {
        $self->{params}->{mutex}->unlock if $self->{params}->{mutex} && !$self->{params}->{commit_lock};
        $self->_delete_backups;
        $self->_delete_works;
        return croak sprintf "Error executing task: %s\n", $error;
    }

=for comment
    Меняем оригинальные ресурсы на модифицированные
=cut

    $self->{params}->{mutex}->unlock if $self->{params}->{mutex} && $self->{params}->{commit_lock};
    for ( my $i = 0; $i < @{ $self->{resources} }; ++$i ) {
        my $rs = $self->{resources}->[$i];
        if ( $rs->is_modified ) {
            $error = $rs->commit;

=for comment
    При ошибке откатываемся на резервные копии
=cut

            if ($error) {
                $self->_rollback;
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return croak sprintf "Error commit changes: %s\n", $error;
            }
        }
    }
    $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
    $self->_delete_backups;
    $self->_delete_works;
    return;
}

# ------------------------------------------------------------------------------
sub execute
{

=for comment
    Основной метод для работы с ресурсами. ДОЛЖЕН быть перегружен в 
    производных объектах.
    Если ресурс был модифицирован - должен выставлять у него {modified}.
    Возвращает undef при отсутствии ошибок, или сообщение об ошибке.
=cut

    my ($self) = @_;
    croak sprintf 'Method "$error = %s()" must be overloaded', ( caller 0 )[3];
    return $self;
}

# ------------------------------------------------------------------------------
sub _rollback
{
    my ( $self, $i ) = @_;
    return unless @{ $self->{resources} };
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        $self->{resources}->[$_]->rollback if $self->{resources}->[$_]->is_modified;
    }
    return $i;
}

# ------------------------------------------------------------------------------
sub _delete_backups
{
    my ( $self, $i ) = @_;
    return unless @{ $self->{resources} };
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        $self->{resources}->[$_]->delete_backup_copy;
    }
    return $i;
}

# ------------------------------------------------------------------------------
sub _delete_works
{
    my ( $self, $i ) = @_;
    return unless @{ $self->{resources} };
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        $self->{resources}->[$_]->delete_work_copy;
    }
    return $i;
}

# ------------------------------------------------------------------------------
1;
__END__

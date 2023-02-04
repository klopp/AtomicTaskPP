package AtomicTaskPP;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp qw/cluck confess/;
use Clone qw/clone/;
use DDP;
use lib q{.};
use Resource::Base;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    На входе ДОЛЖНО быть:
        {resources} [ Resource::*, ...] 
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
    confess 'Error: invalid {params} value' unless ref $params eq 'HASH';
    confess 'Error: invalid {resources} value' if ref $resources ne 'ARRAY' || !@{$resources};

    srand;
    $params->{id} = int( rand 100_000 ) unless $params->{id};

    if ( $params->{mutex} ) {
        $params->{mutex}->can('lock')   or confess 'Error: {mutex} can not lock()!';
        $params->{mutex}->can('unlock') or confess 'Error: {mutex} can not unlock()!';
    }
    else {
        $params->{quiet}
            or cluck 'Warning: no {mutex} in parameters list, multi-threaded code may not be safe!';
    }

    my %data = (
        resources => $resources,
        params    => $params,
    );

    my $self = bless \%data, $class;
    return $self;
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
            return confess sprintf "Error creating backup copy: %s\n", $error;
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
            return confess sprintf "Error creating work copy: %s\n", $error;
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
        return confess sprintf "Error executing task: %s\n", $error;
    }

=for comment
    Меняем оригинальные ресурсы на модифицированные
=cut

    $self->{params}->{mutex}->unlock if $self->{params}->{mutex} && $self->{params}->{commit_lock};
    for ( my $i = 0; $i < @{ $self->{resources} }; ++$i ) {
        my $rs = $self->{resources}->[$i];
        if ( $rs->modified ) {
            $error = $rs->commit;

=for comment
    При ошибке откатываемся на резервные копии
=cut

            if ($error) {
                $self->_rollback;
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return confess sprintf "Error commit changes: %s\n", $error;
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
    return confess sprintf 'Error: method "$error = %s()" must be overloaded', ( caller 0 )[3];
}

# ------------------------------------------------------------------------------
sub _rollback
{
    my ( $self, $i ) = @_;
    @{ $self->{resources} } or return;
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        $self->{resources}->[$_]->modified and $self->{resources}->[$_]->rollback;
    }
    return $i;
}

# ------------------------------------------------------------------------------
sub _delete_backups
{
    my ( $self, $i ) = @_;
    @{ $self->{resources} } or return;
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
    @{ $self->{resources} } or return;
    $i //= @{ $self->{resources} } - 1;
    for ( 0 .. $i ) {
        $self->{resources}->[$_]->delete_work_copy;
    }
    return $i;
}

# ------------------------------------------------------------------------------
1;
__END__

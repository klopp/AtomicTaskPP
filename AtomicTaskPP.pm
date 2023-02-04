package AtomicTaskPP;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp qw/cluck confess/;
use List::Util qw/first/;
use Time::HiRes qw/gettimeofday/;

use lib q{.};
use Resource::Base;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------

=for comment
    Базовый класс, реализующий псевдо-атомарную задачу. На входе принимает массив
    потенциально изменяемых ресурсов, см. соответствующие классы Resource::*.
    * Создаёт резервные копии ресурсов для отката изменений (rollback)
    * Создаёт рабочие копии ресурсов
    * Вызывает перегруженный метод execute()
    * Заменяет ресурсы изменёнными рабочими копиями если ошибок не случилось (commit)
    * В случае ошибок на этапе коммита откатывает затронутые ресурсы на 
        резервные копии
    
    Схема использования:
    
        # Файл отмапленный в память:
        use Resource::MemFile;
        my $rfm = Resource::MemFile->new( { source => '/my/data/table.xyz', id => 'memfile' }, );

        # Сложная структура данных:
        use Resource::Data;
        my $data = { ... };
        my $rd = Resource::Data->new( { source => \$data, id => 'data' }, );
         
        my $task = MyTask->new( [ $rfm, $rd ], { mutex => Mutex->new }, );
        $task->run;
        exit;

        use AtomicTaskPP;
        use base qw/AtomicTaskPP/;
        
        sub execute
        {
            my ($self) = @_;
            
            my $memfile = $self->getr( 'memfile' );
            my $data    = $self->getr( 'data' );
            #
            # Что здесь доступно для каждого типа ресурсов
            #   описано в соответствующих исходниках.
            #   Основное (а другого и не нужно):
            #       $data->{work} (копия данных)
            #       $data->{modified} = 1; (если менялось)
            #       $memfile->{work} (содержимое файла)
            #       $memfile->{modified} = 1; (если менялось)
            #            
            return;
        }       
=cut

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
    ref $params eq 'HASH'                          or confess 'Error: invalid {params} value';
    ( ref $resources eq 'ARRAY' && @{$resources} ) or confess 'Error: invalid {resources} value';

    if ( $params->{mutex} ) {
        $params->{mutex}->can('lock')   or confess 'Error: {mutex} can not lock()!';
        $params->{mutex}->can('unlock') or confess 'Error: {mutex} can not unlock()!';
    }
    else {
        $params->{quiet}
            or cluck 'Warning: no {mutex} in {params}, multi-threaded code may not be safe!';
    }

    my %data = (
        resources  => $resources,
        params     => $params,
        id         => $params->{id},
    );
    $data{id} or $data{id} = join q{.}, ( gettimeofday() );
    %{$data{_hresources}} = map { $_->id => $_ } @{$data{resources}};

    my $self = bless \%data, $class;
    return $self;
}

# ------------------------------------------------------------------------------
sub id
{
    my ($self) = @_;
    return $self->{id};
}

# ------------------------------------------------------------------------------
sub getr
{
    my ( $self, $id ) = @_;
    return $self->{_hresources}->{$id};
}

# ------------------------------------------------------------------------------
sub run
{
    my ( $error, $self ) = ( undef, @_ );

    for ( my $i = 0; $i < @{ $self->{resources} }; ++$i ) {
        my $rs = $self->{resources}->[$i];

=for comment
    Создаём рабочую копию ресурса
=cut

        $error = $rs->create_work_copy;

=for comment
    При ошибке удаляем все временные ресурсы и уходим
=cut

        if ($error) {
            $i and $self->_delete_works( $i - 1 );
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
        $self->_delete_works;
        return confess sprintf "Error executing task: %s\n", $error;
    }

=for comment
    Меняем оригинальные ресурсы на модифицированные
=cut

    $self->{params}->{mutex}->lock if $self->{params}->{mutex} && $self->{params}->{commit_lock};
    for ( my $i = 0; $i < @{ $self->{resources} }; ++$i ) {
        my $rs = $self->{resources}->[$i];
        if ( $rs->modified ) {
            $error = $rs->create_backup_copy;
            if ($error) {
                $self->_rollback;
                $self->{params}->{mutex}->unlock if $self->{params}->{mutex};
                return confess sprintf "Error creating backup copy: %s\n", $error;
            }

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
    my ($self) = @_;
    for ( @{ $self->{resources} } ) {
        if ( $_->modified ) {
            $_->rollback;
            $_->delete_bakup_copy;
        }
        $_->delete_work_copy;
    }
    return;
}

# ------------------------------------------------------------------------------
sub _delete_backups
{
    my ($self) = @_;
    for ( @{ $self->{resources} } ) {
        $_->modified and $_->delete_backup_copy;
    }
    return;
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

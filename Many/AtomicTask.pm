package AtomicTask;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;

use lib q{.};
use Resource::Base;

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $resources, $params ) = @_;

    $params //= {};
    croak 'Invalid {resources} value' unless ref $resources eq 'ARRAY';
    croak 'Invalid {params} value'    unless ref $params eq 'HASH';

    srand;
    $params->{id} = int(rand 100_000) unless $params->{id};

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
        $error = $rs->create_backup_copy;
        if ($error) {
            if ($i) {
                $self->_delete_backups( $i - 1 );
                $self->_delete_works( $i - 1 );
            }
            return croak sprintf "Error creating backup copy: %s\n", $error;
        }
        $error = $rs->create_work_copy;
        if ($error) {
            $self->_delete_backups($i);
            $self->_delete_works( $i - 1 ) if $i;
            return croak sprintf "Error creating work copy: %s\n", $error;
        }
    }
    $self->{params}->{mutex}->lock if $self->{params}->{mutex}; 
    $error = $self->execute;
    if ($error) {
        $self->{params}->{mutex}->unlock if $self->{params}->{mutex}; 
        $self->_delete_backups;
        $self->_delete_works;
        return croak sprintf "Error executing task: %s\n", $error;
    }
    for ( my $i = 0; $i < @{ $self->{resources} }; ++$i ) {
        my $rs = $self->{resources}->[$i];
        if ( $rs->is_modified ) {
            $error = $rs->commit;
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

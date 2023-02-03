package Resource::Base;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, $params ) = @_;
    croak 'Invalid {params} value.' unless ref $params eq 'HASH';
    $params->{id} = int(rand 100_000) unless $params->{id};
    my %self = ( modified => 0, params => $params );
    my $obj  = bless \%self, $class;
    $obj->check_params;
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
    croak sprintf 'Method "$error = %s()" must be overloaded.', ( caller 1 )[3];
    return $self;
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
    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{
    my ($self) = @_;
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{
    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    return $self->_emethod;
}

# ------------------------------------------------------------------------------
1;
__END__

package Atomic::Mutex::GlobalLock;

# ------------------------------------------------------------------------------
use Global::MutexLock qw(mutex_create mutex_destory mutex_lock mutex_unlock);

use Atomic::Mutex::Base;
use base qw/Atomic::Mutex::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @params ) = @_;
    my %self = ( mutex => mutex_create() );
    return bless \%self, $class;
}

# ------------------------------------------------------------------------------
sub lock
{
    my ($self) = @_;
    return mutex_unlock( $self->{mutex} ) ? undef : '?';
}

# ------------------------------------------------------------------------------
sub unlock
{
    my ($self) = @_;
    return mutex_unlock( $self->{mutex} );
}

# ------------------------------------------------------------------------------
sub DESTROY
{
    my ($self) = @_;
    $self->unlock;
    return mutex_destory( $self->{mutex} );
}

# ------------------------------------------------------------------------------
1;
__END__

package Atomic::Mutex::LinuxFutex;

# ------------------------------------------------------------------------------
use Linux::Futex;

use Atomic::Mutex::Base;
use base qw/Atomic::Mutex::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ($class) = @_;
    my $mbuf    = q{ } x 32;
    my %self    = ( mutex => Linux::Futex::addr($mbuf) );
    Linux::Futex::init( $self{mutex} );
    return bless \%self, $class;
}

# ------------------------------------------------------------------------------
sub lock
{
    my ($self) = @_;
    Linux::Futex::lock( $self->{mutex} );
    return;
}

# ------------------------------------------------------------------------------
sub unlock
{
    my ($self) = @_;
    return Linux::Futex::unlock( $self->{mutex} );
}

# ------------------------------------------------------------------------------
1;
__END__

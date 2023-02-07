package Atomic::Mutex::IoLambda;

# ------------------------------------------------------------------------------
use IO::Lambda qw/:lambda/;
use IO::Lambda::Mutex qw/mutex/;

use Atomic::Mutex::Base;
use base qw/Atomic::Mutex::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ($class) = @_;
    my %self = ( mutex => IO::Lambda::Mutex->new );
    return bless \%self, $class;
}

# ------------------------------------------------------------------------------
sub lock
{
    my ($self) = @_;
    my $error;
    lambda {
        context $self->{mutex}->waiter;
        tail {
            $error = shift or $error = $self->{mutex}->take;
        }
    }
    ->wait;
    return $error;
}

# ------------------------------------------------------------------------------
sub unlock
{
    my ($self) = @_;
    return $self->{mutex}->release;
}

# ------------------------------------------------------------------------------
1;
__END__

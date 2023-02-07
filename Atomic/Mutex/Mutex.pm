package Atomic::Mutex::Mutex;

# ------------------------------------------------------------------------------
use Mutex;

use Atomic::Mutex::Base;
use base qw/Atomic::Mutex::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{
    my ( $class, @params ) = @_;
    my %self = ( mutex => Mutex->new(@params) );
    return bless \%self, $class;
}

# ------------------------------------------------------------------------------
1;
__END__

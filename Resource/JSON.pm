package Resource::JSON;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp qw/confess cluck/;
use JSON::XS;
use Try::Tiny;

use lib q{..};
use Resource::Data;
use base qw/Resource::Data/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source} ссылка на скаляр с JSON
    В {params} МОЖЕТ быть:
        {quiet} не выводить предупреждения
        {id}
        {json}  список методов для инициализации JSON::XS в формате { метод=>зачение, ...}
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new($params);

    $self->{json} = JSON::XS->new;
    try {
        while ( my ( $method, $value ) = each %{ $self->{params}->{json} } ) {
            if ( $self->{json}->can($method) ) {
                $self->{json}->$method($value);
            }
            else {
                $params->{quiet}
                    or cluck sprintf 'JSON :: %s() is not defined in JSON!', $method;
            }
        }
    }
    catch {
        confess sprintf 'JSON :: %s', $_;
    };
    return $self;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;
    my $error = $self->SUPER::create_work_copy;
    $error and return $error;

    try {
        $self->{work} = $self->{json}->decode( $self->{work} );
    }
    catch {
        $error = sprintf 'JSON :: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;

    my $error;
    try {
        $self->{work} and $self->{work} = $self->{json}->encode( $self->{work} );
    }
    catch {
        $error = sprintf 'JSON :: %s', $_;
    };
    return $error ? $error : $self->SUPER::commit;
}

# ------------------------------------------------------------------------------
1;
__END__

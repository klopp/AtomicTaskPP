package Resource::BSON;

# ------------------------------------------------------------------------------
use Modern::Perl;

use BSON;
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
        {source} ссылка на скаляр с BSON
    В {params} МОЖЕТ быть:
        {id}
        {bson} флаги BSON
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new($params);
    $self->{bson} = BSON->new( $params->{bson} || {} );
    return $self;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;

    my $error = $self->SUPER::create_work_copy;
    $error and return $error;

    try {
        $self->{work} = $self->{bson}->decode_one( $self->{work} );
    }
    catch {
        $error = sprintf 'BSON: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    try {
        $self->{work} and $self->{work} = $self->{bson}->encode_one( $self->{work} );
    }
    catch {
        return sprintf 'BSON: %s', $_;
    };
    return $self->SUPER::commit;
}

# ------------------------------------------------------------------------------
1;
__END__

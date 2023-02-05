package Resource::JSON;

# ------------------------------------------------------------------------------
use Modern::Perl;

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
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    return $class->SUPER::new($params);
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;
    my $error = $self->SUPER::create_work_copy;
    $error and return $error;

    try {
        $self->{work} = decode_json( $self->{work} );
    }
    catch {
        $error = sprintf 'JSON: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    try {
        $self->{work} and $self->{work} = encode_json( $self->{work} );
    }
    catch {
        return sprintf 'JSON: %s', $_;
    };
    return $self->SUPER::commit;
}

# ------------------------------------------------------------------------------
1;
__END__

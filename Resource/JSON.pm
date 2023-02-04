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
        {source} ссылка на массив или хэш любой степени вложенности 
                    НЕ может быть blessed
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
sub check_params
{
    my ($self) = @_;
    ref $self->{params}->{source} eq 'SCALAR' or return 'ref {params}->{source} is not SCALAR';
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;
    my $rc = $self->SUPER::create_work_copy;
    $rc and return $rc;

    my $error;
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
        $self->{work} = encode_json( $self->{work} );
    }
    catch {
        return sprintf 'JSON: %s', $_;
    };
    return $self->SUPER::commit;
}

# ------------------------------------------------------------------------------
1;
__END__

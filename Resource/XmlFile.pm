package Resource::XmlFile;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Try::Tiny;
use XML::Hash::XS;

use lib q{..};
use Resource::MemFile;
use base qw/Resource::MemFile/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source} имя исходного файла
    В {params} МОЖЕТ быть:
        {encoding} кодировка 
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified}
        {work}      рабочие данные
        {backup}    копия исходных данных
=cut    

    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new($params);
    return $self;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;
    my $error = $self->SUPER::create_work_copy;
    $error and return $error;

    try {
        $self->{work} = xml2hash( $self->{work}, %{ $self->{params}->{xml} } );
    }
    catch {
        $error = sprintf 'XML: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    try {
        $self->{work} and $self->{work} = hash2xml( $self->{work}, %{ $self->{params}->{xml} } );
    }
    catch {
        return sprintf 'XML: %s', $_;
    };
    return $self->SUPER::commit;
}

# ------------------------------------------------------------------------------
1;
__END__

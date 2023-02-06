package Resource::MemFile;

# ------------------------------------------------------------------------------
use Modern::Perl;
use utf8::all;
use open qw/:std :utf8/;

use Path::Tiny;
use Try::Tiny;

use lib q{..};
use Resource::Base;
use base qw/Resource::Base/;

our $VERSION = 'v1.0';

# ------------------------------------------------------------------------------
sub new
{

=for comment
    В {params} ДОЛЖНО быть:
        {source} имя исходного файла
    В {params} МОЖЕТ быть:
        {quiet}    не выводить предупреждения
        {id}
        {encoding} кодировка 
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      буфер с рабочим файлом
        {backup}    буфер с копией исходного файла
=cut    

    my ( $class, $params ) = @_;
    my $self     = $class->SUPER::new($params);
    my $encoding = ':raw';
    $params->{encoding} and $encoding .= sprintf ':encoding(%s)', $params->{encoding};
    $self->{_filemode} = { binmode => $encoding };

    return $self;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;

    my $error;
    try {
        $self->{backup} = path( $self->{params}->{source} )->slurp( $self->{_filemode} );
    }
    catch {
        $error = sprintf 'MemFile :: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{
    my ($self) = @_;
    delete $self->{backup};
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;

    my $error;
    try {
        $self->{work} = path( $self->{params}->{source} )->slurp( $self->{_filemode} );
    }
    catch {
        $error = sprintf 'MemFile :: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{
    my ($self) = @_;
    delete $self->{work};
    return;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;

    my $error;
    try {
        $self->{work} and path( $self->{params}->{source} )->spew( $self->{_filemode}, $self->{work} );
    }
    catch {
        $error = sprintf 'MemFile :: "%s" (%s)', $self->{params}->{source}, $_
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;

    my $error;
    try {
        $self->{backup} and path( $self->{params}->{source} )->spew( $self->{_filemode}, $self->{backup} );
    }
    catch {
        $error = sprintf 'MemFile :: "%s" (%s)', $self->{params}->{source}, $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
1;
__END__

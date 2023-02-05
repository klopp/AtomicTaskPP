package Resource::MemFile;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Carp;
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
    return $class->SUPER::new($params);
}

# ------------------------------------------------------------------------------
sub check_params
{
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;

    try {
        my $encoding = ':raw';
        $self->{params}->{encoding} and $encoding .= sprintf ':encoding(%s)', $self->{params}->{encoding};
        $self->{backup} = path( $self->{params}->{source} )->slurp( { binmode => $encoding } );
    }
    catch {
        return $_;
    };
    return;
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

    try {
        my $encoding = ':raw';
        $self->{params}->{encoding} and $encoding .= sprintf ':encoding(%s)', $self->{params}->{encoding};
        $self->{work} = path( $self->{params}->{source} )->slurp( { binmode => $encoding } );
    }
    catch {
        return $_;
    };
    return;
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
    try {
        my $encoding = ':raw';
        $self->{params}->{encoding} and $encoding .= sprintf ':encoding(%s)', $self->{params}->{encoding};
        path( $self->{params}->{source} )->spew( { binmode => $encoding }, $self->{work} );
        delete $self->{work};
    }
    catch {
        return sprintf 'file "%s" (%s)', $self->{params}->{source}, $_
    };
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    if ( $self->{backup} ) {
        try {
            my $encoding = ':raw';
            $self->{params}->{encoding} and $encoding .= sprintf ':encoding(%s)', $self->{params}->{encoding};
            path( $self->{params}->{source} )->spew( { binmode => $encoding }, $self->{backup} );
            delete $self->{backup};
        }
        catch {
            return sprintf 'file "%s" (%s)', $self->{params}->{source}, $_;
        };
    }
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

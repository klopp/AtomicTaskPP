package Resource::File;

# ------------------------------------------------------------------------------
use Modern::Perl;

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
        {quiet}   не выводить предупреждения
        {tempdir}
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified}
        {work}     рабочий файл (Path::Tiny)
        {bakup}    резервная копия исходного файла (Path::Tiny)
=cut    

    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new($params);
    $self->{tempdir} = $params->{tempdir};
    $self->{tempdir}    or $self->{tempdir} = $ENV{HOME} . '/tmp';
    -d $self->{tempdir} or $self->{tempdir} = q{.};
    return $self;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;

    my $error;
    try {
        $self->{backup} = Path::Tiny->tempfile( DIR => $self->{tempdir} );
        path( $self->{params}->{source} )->copy( $self->{backup} );
    }
    catch {
        $error = sprintf 'File :: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{
    my ($self) = @_;
    $self->{backup} and path( $self->{backup} )->remove;
    delete $self->{backup};
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;

    my $error;
    try {
        $self->{work} = Path::Tiny->tempfile( DIR => $self->{tempdir} );
        path( $self->{params}->{source} )->copy( $self->{work} );
    }
    catch {
        $error = sprintf 'File :: %s', $_;
    };
    return $error;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{
    my ($self) = @_;
    $self->{work} and path( $self->{work} )->remove;
    delete $self->{work};
    return;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;

    my $error;
    try {
        $self->{work} and $self->{work}->move( $self->{params}->{source} );
    }
    catch {
        $error = sprintf 'File :: "%s": %s', $self->{params}->{source}, $_;
    }
    return $error;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;

    my $error;
    try {
        $self->{backup} and $self->{backup}->move( $self->{params}->{source} );
    }
    catch {
        $error = sprintf 'File :: "%s": %s', $self->{params}->{source}, $_;
    }
    return $error;
}

# ------------------------------------------------------------------------------
1;
__END__

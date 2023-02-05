package Resource::File;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;
use English qw/-no_match_vars/;
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
sub check_params
{
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;

    try {
        $self->{backup} = Path::Tiny->tempfile( DIR => $self->{tempdir} );
        path( $self->{params}->{source} )->copy( $self->{backup} );
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
    $self->{backup} and path( $self->{backup} )->remove;
    delete $self->{backup};
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;

    try {
        $self->{work}  = Path::Tiny->tempfile( DIR => $self->{tempdir} );
        path( $self->{params}->{source} )->copy( $self->{work} );
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
    if ( $self->{work} ) {
        path( $self->{work} )->remove;
    }
    delete $self->{work};
    return;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    if ( $self->{work} ) {
        try {
            $self->{work}->move( $self->{params}->{source} );
        }
        catch {
            return sprintf 'file "%s": %s', $self->{params}->{source}, $_;
        }
        delete $self->{work};
    }
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    if ( $self->{backup} ) {
        try {
            $self->{backup}->move( $self->{params}->{source} );
        }
        catch {
            return sprintf 'file "%s": %s', $self->{params}->{source}, $_;
        }
        delete $self->{backup};
    }
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

package Resource::File;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;
use English qw/-no_match_vars/;
use File::Copy qw/copy/;
use File::Temp qw/tempfile/;
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
        {source}
    В {params} МОЖЕТ быть:
        {tempdir}
        {id}
    Структура после полной инициализации:
        {params}
        {modified}
        {workh}    хэндл рабочего файла
        {work}     имя рабочего файла
        {bakup}    имя файла с копией исходного
=cut    
    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new($params);
    $self->{tempdir} = $params->{tempdir};
    $self->{tempdir} = $ENV{HOME} . '/tmp' unless $self->{tempdir};
    $self->{tempdir} = q{.}                unless -d $self->{tempdir};
    return $self;
}

# ------------------------------------------------------------------------------
sub check_params
{
    my ($self) = @_;
    return sprintf 'No {source} in params.' unless $self->{params}->{source};
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ( $backup, $self ) = ( undef, @_ );

    try {
        ( undef, $backup ) = tempfile DIR => $self->{tempdir};
    }
    catch {
        return sprintf 'can not create BACKUP file (%s)', $_;
    };
    $self->{backup} = $backup;
    unless ( copy( $self->{params}->{source}, $backup ) ) {
        my $error = $ERRNO;
        $self->delete_backup_copy;
        return sprintf 'can not save BACKUP file (%s)', $ERRNO;
    }
    return;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{
    my ($self) = @_;
    unlink $self->{backup} if $self->{backup};
    undef $self->{backup};
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ( $workh, $work, $self ) = ( undef, undef, @_ );

    try {
        ( $workh, $work ) = tempfile DIR => $self->{tempdir};
    }
    catch {
        return sprintf 'can not create WORK file (%s)', $_;
    };
    $self->{work}  = $work;
    $self->{workh} = $workh;
    unless ( copy( $self->{params}->{source}, $work ) ) {
        my $error = $ERRNO;
        $self->delete_work_copy;
        return sprintf 'can not save WORK file (%s)', $ERRNO;
    }
    return;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{
    my ($self) = @_;
    close $self->{workh} if $self->{workh};
    unlink $self->{work} if $self->{work};
    undef $self->{workh};
    undef $self->{work};
    return;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    close $self->{workh};
    undef $self->{workh};
    if ( $self->{work} ) {
        unless ( rename $self->{work}, $self->{params}->{source} ) {
            return sprintf 'can not rename "%s" to "%s": %s', $self->{work}, $self->{params}->{source}, $ERRNO;
        }
        undef $self->{work};
    }
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    if ( $self->{backup} ) {
        unless ( rename $self->{backup}, $self->{params}->{source} ) {
            return sprintf 'can not rename "%s" to "%s": %s', $self->{backup}, $self->{params}->{source},
                $ERRNO;
        }
        undef $self->{params}->{backup};
    }
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

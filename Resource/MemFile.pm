package Resource::MemFile;

# ------------------------------------------------------------------------------
use strict;
use warnings;

use Carp;
use File::Slurper qw/read_text read_binary write_text write_binary/;
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
        {id}
        {textmode} тектовый режим
        {encoding} кодировка для текстового режима
        {crlf}     интерпретация crlf (см. File::Slurper)
    Структура после полной инициализации:
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
    my ($self) = @_;
    return sprintf 'No {source} in params.' unless $self->{params}->{source};
    return;
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;

    try {
        if ( $self->{params}->{textmode} ) {
            $self->{backup}
                = read_text( $self->{params}->{source}, $self->{params}->{encoding}, $self->{params}->{crlf} );
        }
        else {
            $self->{backup} = read_binary( $self->{params}->{source} );
        }
    }
    catch {
        return sprintf 'can not create BACKUP file (%s)', $_;
    };
    return;
}

# ------------------------------------------------------------------------------
sub delete_backup_copy
{
    my ($self) = @_;
    undef $self->{backup};
    return;
}

# ------------------------------------------------------------------------------
sub create_work_copy
{
    my ($self) = @_;

    try {
        if ( $self->{params}->{textmode} ) {
            $self->{work}
                = read_text( $self->{params}->{source}, $self->{params}->{encoding}, $self->{params}->{crlf} );
        }
        else {
            $self->{work} = read_binary( $self->{params}->{source} );
        }
    }
    catch {
        return sprintf 'can not create WORK file (%s)', $_;
    };
    return;
}

# ------------------------------------------------------------------------------
sub delete_work_copy
{
    my ($self) = @_;
    undef $self->{work};
    return;
}

# ------------------------------------------------------------------------------
sub commit
{
    my ($self) = @_;
    try {
        if ( $self->{params}->{textmode} ) {
            write_text( $self->{params}->{source}, $self->{work}, $self->{params}->{encoding},
                $self->{params}->{crlf} );
        }
        else {
            write_binary( $self->{params}->{source}, $self->{work} );
        }
        undef $self->{work};
    }
    catch {
        return sprintf 'can not overwrite source file "%s" (%s)', $self->{params}->{source}, $_;
    };
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    try {
        if ( $self->{params}->{textmode} ) {

            write_text(
                $self->{params}->{source},
                $self->{backup},
                $self->{params}->{encoding},
                $self->{params}->{crlf}
            );
        }
        else {
            write_binary( $self->{params}->{source}, $self->{backup} );
        }
        undef $self->{backup};
    }
    catch {
        return sprintf 'can not overwrite source file "%s" (%s)', $self->{params}->{source}, $_;
    };
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

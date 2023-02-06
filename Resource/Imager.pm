package Resource::Imager;

# ------------------------------------------------------------------------------
use Modern::Perl;

use Imager;
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
        {quiet} не выводить предупреждения
        {id}
    Структура после полной инициализации:
        {id}
        {params}
        {modified} 
        {work}      рабочий объект Imager
        {backup}    объект Imager с копией исходной картинки
=cut    

    my ( $class, $params ) = @_;
    return $class->SUPER::new($params);
}

# ------------------------------------------------------------------------------
sub create_backup_copy
{
    my ($self) = @_;

    $self->{backup} = Imager->new( file => $self->{params}->{source} )
        or return sprintf 'Imager :: %s', Imager->errstr();
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

    $self->{work} = Imager->new( file => $self->{params}->{source} )
        or return sprintf 'Imager :: %s', Imager->errstr();
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
    if ( $self->{work} ) {
        $self->{work}->write( file => $self->{params}->{source} )
            or return sprintf 'Imager :: "%s" (%s)', $self->{params}->{source}, $self->{work}->errstr;
    }
    return;
}

# ------------------------------------------------------------------------------
sub rollback
{
    my ($self) = @_;
    if ( $self->{backup} ) {
        $self->{backup}->write( file => $self->{params}->{source} )
            or return sprintf 'Imager :: "%s" (%s)', $self->{params}->{source},
            $self->{backup}->errstr;
    }
    return;
}

# ------------------------------------------------------------------------------
1;
__END__

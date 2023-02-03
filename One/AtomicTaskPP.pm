package AtomicTaskPP;

# ------------------------------------------------------------------------------
use Modern::Perl;

use File::Copy qw/copy/;
use File::Slurper qw/read_text/;
use File::Temp qw/tempfile/;
use Mutex;
use Try::Tiny;

# ------------------------------------------------------------------------------

=for comment
    Не создаём временный файл в системном или пользовательском $TEMP, 
    так как он может оказаться на другом разделе, и в этом случае
    условно-атомарный вызов rename не сработает.
    Другие варианты (File::Copy::move и т.д.) уж точно не атомарные.
=cut

my $TEMPDIR = q{.};

# ------------------------------------------------------------------------------
sub modify_file
{
    my ( $tmph, $tmpfile, $param ) = ( undef, undef, @_ );
    $param->{mutex}->lock;

    try {

=for comment
    1) создаём копию исходного файла
=cut

        ( $tmph, $tmpfile ) = tempfile DIR => $TEMPDIR;
        copy( $param->{file}, $tmpfile );

=for comment
    2) издеваемся над ней
=cut

        my $content = read_text $tmpfile;
        say "<<\n$content";
        $content = join "\n", map { $param->{id} } 0 .. int( rand 9 ) + 1;
        say ">>\n$content";
        print $tmph $content;
        truncate $tmph, length $content;
        close $tmph;

=for comment
    3) и атомарно вносим все изменения в исходный файл
        (на самом деле условно атомарно, всё зависит от
        конкретной реализации rename)
=cut

        rename $tmpfile, $param->{file};
    }
    catch {
        say sprintf 'Error :: %s', $_;
    }
    finally {
        unlink $tmpfile if $tmpfile;
    };

    return $param->{mutex}->unlock;
}

# ------------------------------------------------------------------------------
1;
__END__

use ExtUtils::MakeMaker;

use Config;

my %deps = ('Math::Int64' => '0.27_04');

unless (-f "c_api.h") {
    $deps{'Module::CAPIMaker'} = '0.01';
}

unless (-f "perl_math_int64.c" and -f "perl_math_int64.h") {
    warn "perl_math_int64.c or perl_math_int64.h files are not found, Math::Int64 has to be cloned under the same root directory as Math::Int128\n";
}

my $mm = WriteMakefile(NAME          => 'Math::Int128',
                       VERSION_FROM  => 'lib/Math/Int128.pm',
                       ABSTRACT_FROM => 'lib/Math/Int128.pm',
                       AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
                       PREREQ_PM     => \%deps,
                       CONFIGURE_REQUIRES => {
                           'ExtUtils::MakeMaker' => 0,
                           'Config::AutoConf'    => 0.22,
                        },
                       TEST_REQUIRES => { 'Test::More' => '0.88' },
                       LIBS          => [''],
                       DEFINE        => '',
                       INC           => '-I.',
                       # OPTIMIZE    => '-g -O0',
                       OBJECT        => '$(O_FILES)',
                       META_MERGE    => {
                           resources => {
                               repository  =>  'https://github.com/salva/p5-Math-Int128',
                           },
                      },
                      );

use Config::AutoConf;
Config::AutoConf->check_cc();
my $has_int128;
Config::AutoConf->check_type( '__int128', sub { $has_int128 = 1 } );

unless ($has_int128) {
    Config::AutoConf->msg_checking( 'for GCC 4.4/4.5 int128 workaround' );
    Config::AutoConf->compile_if_else( <<TEST_INT128
        typedef int int128_t __attribute__ ((__mode__ (TI)));
        typedef unsigned int uint128_t __attribute__ ((__mode__ (TI)));
TEST_INT128
        , sub { print "yes\n"; $has_int128 = 1 });
}

unless ($has_int128) {
    unlink $mm->{MAKEFILE};
    die "128bit integers not supported by your C compiler.\nAborting!\n\n";
}


package MY;

sub postamble {
    my $self = shift;
    my $author = $self->{AUTHOR};
    $author = join(', ', @$author) if ref $author;
    $author =~ s/'/'\''/g;

    return <<MAKE_FRAG

c_api.h: c_api.decl
	make_perl_module_c_api module_name=\$(NAME) module_version=\$(VERSION) author='$author'
MAKE_FRAG
}

sub init_dirscan {
    my $self = shift;
    $self->SUPER::init_dirscan(@_);
    push @{$self->{H}}, 'c_api.h' unless grep $_ eq 'c_api.h', @{$self->{H}};
}

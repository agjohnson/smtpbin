use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'SMTPbin',
    license => 'MIT',
    dist_author => q{Anthony Johnson <aj@ohess.org>},
    dist_version_from => 'lib/SMTPbin.pm',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
        'Twiggy' => 0,
        'Plack' => 0,
        'Plack::Middleware::Static' => 0,
        'Template' => 0,
        'JSON' => 0,
        'Text::Caml' => 0,
        'Data::UUID' => 0,
        'Mouse' => 0,
        'AnyEvent::Redis' => 0,
        'AnyEvent' => 0
    },
    add_to_cleanup => [ 'SMTPbin-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

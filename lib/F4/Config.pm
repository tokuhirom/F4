package F4::Config;
use strict;
use warnings;
use base qw/Class::Singleton/;

sub _new_instance {
    my ($class, ) = @_;
    bless {}, $class;
}

1;

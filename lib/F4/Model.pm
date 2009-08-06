package F4::Model;
use strict;
use warnings;
use base qw/Exporter/;
use F4::Registrar;
use Carp::Assert qw/assert/;
use Any::Moose;
use B::Hooks::EndOfScope;

our $EXPORT = qw/assert/;

sub import {
    strict->import;
    warnings->import;
    any_moose->import({into_level => 1});
    F4::Registrar->export_to_level(1);
    __PACKAGE__->export_to_level(1);

    my $caller = caller(0);
    on_scope_end { $caller->meta->make_immutable };
}

1;

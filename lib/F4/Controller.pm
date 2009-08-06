package F4::Controller;
use strict;
use warnings;
use base qw/Exporter/;
use F4::Registrar;
use HTTP::Engine;
use Carp::Assert qw/assert/;
use F4::Util;

our @EXPORT = qw/res assert/;

sub import {
    my $class = shift;
    string->import;
    warnings->import;
    $class->export_to_level(1);
    F4::Registrar->export_to_level(1);
    F4::Util->export_to_level(1);
}

sub res { HTTP::Engine::Response->new(@_) }

1;


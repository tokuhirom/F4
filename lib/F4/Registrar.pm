package F4::Registrar;
use strict;
use warnings;
use base qw/Exporter/;
use Any::Moose;
use F4::Config;

our @EXPORT = qw/model config controller set_context context/;

my $BASENAME = 'F4';

{
    my $cache;
    sub model {
        my $pkg = shift;
        my @args = @_;
        $cache->{$pkg} ||= do {
           my $klass = "${BASENAME}::Model::$pkg";
           Any::Moose::load_class($klass);
           my $obj = $klass->new(@args);
           if ($obj->can('init')) {
                $obj->init();
           }
           $obj;
        };
    }
}

sub controller {
    my $pkg = shift;
    my $klass = "${BASENAME}::Controller::$pkg";
    Any::Moose::load_class($klass);
    $klass;
}

sub config {
    my $pkg = shift;
    my $conf = F4::Config->instance;
    if (defined($pkg)) {
        $conf->{$pkg} ||= {};
        $conf->{$pkg};
    } else {
        $conf;
    }
}

{
    my $c;
    sub set_context { $c = $_[0] }
    sub context     { $c         }
}

1;

package F4::Util;
use strict;
use warnings;
use base qw/Exporter/;
use F4::Registrar;
use Data::Dumper;
use Carp::Assert;
our @EXPORT = qw/bucket_name dbg p Dumper/;

sub bucket_name {
    my ($req) = @_;
    assert $req;

    my $context = context();
    if ($req->uri->host ne $context->basename) {
        (my $prefix = $req->uri->host) =~ s/\Q.@{[ $context->basename ]}\E$//;
        $prefix =~ s/\///g;
        return $prefix;
    } else {
        my ($prefix,) = split m{/}, $req->uri->path;
        return $prefix;
    }
}

sub dbg(@) { print STDERR "[dbg] @_\n" if $ENV{DEBUG} }
sub p { print STDERR Dumper(@_) }


1;

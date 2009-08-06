package F4;
use Any::Moose;
with any_moose('X::Getopt');
our $VERSION = '0.01';
use HTTP::Engine;
use MIME::Base64 qw/decode_base64/;;
use F4::Registrar;
use Digest::HMAC_SHA1;
use F4::Util;
use Data::Model::Driver::DBI;
use YAML;

has host => (
    is => 'ro',
    isa => 'Str',
    default => '127.0.0.1',
);

has port => (
    is => 'ro',
    isa => 'Int',
    default => 4002,
);

has basename => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub run {
    my $self = shift;

    if ($ENV{DEBUG}) {
        *Data::Model::Driver::DBI::start_query = sub {
            my ( $c, $sql, @binds ) = @_;
            print STDERR YAML::Dump( { query => $sql, binds => \@binds } );
        };
    }

    HTTP::Engine->new(
        interface => {
            module => 'ServerSimple',
            args => {
                host => $self->host,
                port => $self->port,
            },
            request_handler => sub { handler($self, $_[0]) },
        },
    )->run;
}

sub handler {
    my ($self, $req) = @_;
    # p($req);

    set_context($self);

    my $user = $self->authorize($req);
    return res(status => 401, body => 'authorization required') unless $user;

    if ($req->uri->path eq '/' && $req->method eq 'PUT') {
        return controller('Bucket')->create($req, $user);
    } elsif ($req->uri->path eq '/' && $req->method eq 'DELETE') {
        return controller('Bucket')->delete($req, $user);
    } elsif ($req->method eq 'PUT') {
        return controller('Key')->add($req, $user);
    } elsif ($req->method eq 'GET') {
        return controller('Key')->get($req, $user);
    } elsif ($req->method eq 'DELETE') {
        return controller('Key')->delete($req, $user);
    } else {
        p($req);
        dbg("404 not found");
        return HTTP::Engine::Response->new( body => '404 not found',
            status => 40 );
    }
}

sub res { HTTP::Engine::Response->new(@_) }

sub path {
    my ($self, $req) = @_;
    if ($req->uri->host ne $self->basename) {
        (my $prefix = $req->uri->host) =~ s/\Q.@{[ $self->basename ]}\E$//;
        return bucket_name($req) . $req->uri->path;
    } else {
        return $req->uri->path;
    }
}

sub authorize {
    my ($self, $req) = @_;
    my $auth = $req->headers->authorization || '';
    if ($auth =~ /^AWS (\S+):(\S+)$/) {
        my ($keyid, $got_encoded_canonical) = ($1, $2);
        my $account = model('Account')->get($keyid);
        unless ($account) {
            dbg("invalid key_id");
            return;
        }

        # XXX should not call the private method! I KNOW!
        use Amazon::S3;
        my $canonical = Amazon::S3->_canonical_string($req->method, $self->path($req), $req->headers);
        my $encoded = Amazon::S3->_encode($account->secret_access_key, $canonical);
        if ($got_encoded_canonical eq $encoded) {
            dbg("authentication succeeded");
            return $account;
        } else {
            dbg("authentication failure");
            return;
        }
    } else {
        dbg("Bad authentication header: $auth");
        return;
    }
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

F4 -

=head1 SYNOPSIS

    ./bin/f4

=head1 DESCRIPTION

F4 is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom  slkjfd gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

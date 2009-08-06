package F4::Controller::Key;
use F4::Controller;

sub add {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    unless ($bucket) {
        return res(status => 400, body => 'unknown bucket');
    }

    model('Key')->add(
        $bucket,
        $req->uri->path,
        $req->headers->content_type,
        $req->raw_body,
    );
    return res(status => 200, body => 'ok');
}

sub get {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    unless ($bucket) {
        return res(status => 400, body => 'unknown bucket');
    }

    my $key = model('Key')->get(
        $bucket,
        $req->uri->path,
    );
    if ($key) {
        return res(
            status  => 200,
            body    => $key->content,
            headers => { content_type => $key->content_type, }
        );
    } else {
        return res(status => 404, body => 'unknown key');
    }
}

sub delete {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    unless ($bucket) {
        return res(status => 400, body => 'unknown bucket');
    }

    my $key = model('Key')->delete(
        $bucket,
        $req->uri->path,
    );
    return res(
        status  => 200,
        body    => 'ok',
    );
}

1;

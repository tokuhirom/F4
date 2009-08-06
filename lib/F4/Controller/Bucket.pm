package F4::Controller::Bucket;
use F4::Controller;

sub create {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    if ($bucket) {
        if ($bucket->owner_access_key_id ne $user->access_key_id) {
            # TODO: support acl..
            dbg "another user already used this bucket name";
            return res(status => 403, body => 'BucketAlready');
        } else {
            dbg "re-get the bucket";
            return res(status => 200, body => 'ok');
        }
    } else {
        my $bucket = model('Bucket')->create(F4::Util::bucket_name($req));
        return res(status => 200, body => 'ok');
    }
}

sub add_key {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    unless ($bucket) {
        return res(status => 400, body => 'unknown bucket');
    }

    model('Bucket')->add_key(
        $bucket,
        $req->uri->path,
        $req->headers->content_type,
        $req->raw_body,
    );
    return res(status => 200, body => 'ok');
}

sub get_key {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    unless ($bucket) {
        return res(status => 400, body => 'unknown bucket');
    }

    my $key = model('Bucket')->get_key(
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

sub delete_key {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    unless ($bucket) {
        return res(status => 400, body => 'unknown bucket');
    }

    my $key = model('Bucket')->delete_key(
        $bucket,
        $req->uri->path,
    );
    return res(
        status  => 200,
        body    => 'ok',
    );
}

1;

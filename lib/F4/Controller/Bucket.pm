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
        my $bucket = model('Bucket')->create(
            F4::Util::bucket_name($req),
            $user->access_key_id,
        );
        return res(status => 200, body => 'ok');
    }
}

sub delete {
    my ($class, $req, $user) = @_;
    assert $user;

    my $bucket = model('Bucket')->get(F4::Util::bucket_name($req));
    if ($bucket) {
        assert $bucket->owner_access_key_id;
        if ($bucket->owner_access_key_id ne $user->access_key_id) {
            # TODO: support acl..
            dbg "do not remove another user's bucket!";
            return res(status => 403, body => 'Forbidden');
        } else {
            dbg "removing bucket";
            $bucket->delete();
            return res(status => 200, body => 'removed');
        }
    } else {
        return res(status => 404, body => 'not found');
    }
}

1;

use strict;
use warnings;
use Test::TCP;
use Test::More;
use F4;
plan skip_all => 'this test requires $ENV{TEST_F4_AWS_HOST}' unless $ENV{TEST_F4_AWS_HOST};
use Test::Requires qw/
    Amazon::S3
/;
use File::Temp;
use F4::Registrar;

plan skip_all => "not worked yet";

my $db = File::Temp->new(UNLINK => 0);
my $s3;

test_tcp(
    client => sub {
        my $port = shift;
        config('Model::DB')->{db} = {
            dsn => "dbi:SQLite:dbname=$db",
        };
        my $account = model('Account')->create();
        diag $account->access_key_id;
        diag $account->secret_access_key;
        my $host = "$ENV{TEST_F4_AWS_HOST}:$port";
        main($account->access_key_id, $account->secret_access_key, $host);
    },
    server => sub {
        my $port = shift;
        config('Model::DB')->{db} = {
            dsn => "dbi:SQLite:dbname=$db",
        };
        model('DB')->setup_schema();
        F4->new(
            port     => $port,
            host     => '0.0.0.0',
            basename => $ENV{TEST_F4_AWS_HOST}
        )->run;
    },
);

use vars qw/$OWNER_ID $OWNER_DISPLAYNAME/;

sub main {
    my ($aws_access_key_id, $aws_secret_access_key, $host) = @_;
    $s3 = Amazon::S3->new(
        {
            aws_access_key_id     => $aws_access_key_id,
            aws_secret_access_key => $aws_secret_access_key,
            host                  => $host,
        }
    );

    # list all buckets that i own
    my $response = $s3->buckets;

    $OWNER_ID          = $response->{owner_id};
    $OWNER_DISPLAYNAME = $response->{owner_displayname};

    for my $location (undef, 'EU') {

        # create a bucket
        # make sure it's a valid hostname for EU testing
        # we use the same bucket name for both in order to force one or the other to
        # have stale DNS
        my $bucketname = 'net-amazon-s3-test-' . lc $aws_access_key_id;
        my $bucket_obj =
        $s3->add_bucket(
                        {
                        bucket              => $bucketname,
                        acl_short           => 'public-read',
                        location_constraint => $location
                        }
        )
        or die $s3->err . ": " . $s3->errstr;
        is(ref $bucket_obj, "Amazon::S3::Bucket");
        is($bucket_obj->get_location_constraint, $location);

        like_acl_allusers_read($bucket_obj);
        ok($bucket_obj->set_acl({acl_short => 'private'}));
        unlike_acl_allusers_read($bucket_obj);

        # another way to get a bucket object (does no network I/O,
        # assumes it already exists).  Read Amazon::S3::Bucket.
        $bucket_obj = $s3->bucket($bucketname);
        is(ref $bucket_obj, "Amazon::S3::Bucket");

        # fetch contents of the bucket
        # note prefix, marker, max_keys options can be passed in
        $response = $bucket_obj->list
        or die $s3->err . ": " . $s3->errstr;
        is($response->{bucket},       $bucketname);
        is($response->{prefix},       '');
        is($response->{marker},       '');
        is($response->{max_keys},     1_000);
        is($response->{is_truncated}, 0);
        is_deeply($response->{keys}, []);

        is(undef, $bucket_obj->get_key("non-existing-key"));

        my $keyname = 'testing.txt';

        {

            # Create a publicly readable key, then turn it private with a short acl.
            # This key will persist past the end of the block.
            my $value = 'T';
            $bucket_obj->add_key(
                                $keyname, $value,
                                {
                                content_type        => 'text/plain',
                                'x-amz-meta-colour' => 'orange',
                                acl_short           => 'public-read',
                                }
            );

            is_request_response_code("http://$bucketname.s3.amazonaws.com/$keyname",
                                    200, "can access the publicly readable key");

            like_acl_allusers_read($bucket_obj, $keyname);

            ok($bucket_obj->set_acl({key => $keyname, acl_short => 'private'}));

            is_request_response_code("http://$bucketname.s3.amazonaws.com/$keyname",
                                    403, "cannot access the private key");

            unlike_acl_allusers_read($bucket_obj, $keyname);

            ok(
                $bucket_obj->set_acl(
                                {
                                    key     => $keyname,
                                    acl_xml => acl_xml_from_acl_short('public-read')
                                }
                )
            );

            is_request_response_code("http://$bucketname.s3.amazonaws.com/$keyname",
                        200,
                        "can access the publicly readable key after acl_xml set");

            like_acl_allusers_read($bucket_obj, $keyname);

            ok(
                $bucket_obj->set_acl(
                                    {
                                    key     => $keyname,
                                    acl_xml => acl_xml_from_acl_short('private')
                                    }
                )
            );

            is_request_response_code(
                                "http://$bucketname.s3.amazonaws.com/$keyname",
                                403,
                                "cannot access the private key after acl_xml set"
            );

            unlike_acl_allusers_read($bucket_obj, $keyname);

        }

        {

            # Create a private key, then make it publicly readable with a short
            # acl.  Delete it at the end so we're back to having a single key in
            # the bucket.

            my $keyname2 = 'testing2.txt';
            my $value    = 'T2';
            $bucket_obj->add_key(
                                $keyname2,
                                $value,
                                {
                                content_type        => 'text/plain',
                                'x-amz-meta-colour' => 'blue',
                                acl_short           => 'private',
                                }
            );

            is_request_response_code(
                                    "http://$bucketname.s3.amazonaws.com/$keyname2",
                                    403, "cannot access the private key");

            unlike_acl_allusers_read($bucket_obj, $keyname2);

            ok(
                $bucket_obj->set_acl(
                                    {key => $keyname2, acl_short => 'public-read'}
                )
            );

            is_request_response_code(
                                    "http://$bucketname.s3.amazonaws.com/$keyname2",
                                    200, "can access the publicly readable key");

            like_acl_allusers_read($bucket_obj, $keyname2);

            $bucket_obj->delete_key($keyname2);

        }

        # list keys in the bucket
        $response = $bucket_obj->list
        or die $s3->err . ": " . $s3->errstr;
        is($response->{bucket},       $bucketname);
        is($response->{prefix},       '');
        is($response->{marker},       '');
        is($response->{max_keys},     1_000);
        is($response->{is_truncated}, 0);
        my @keys = @{$response->{keys}};
        is(@keys, 1);
        my $key = $keys[0];
        is($key->{key}, $keyname);

        # the etag is the MD5 of the value
        is($key->{etag}, 'b9ece18c950afbfa6b0fdbfa4ff731d3');
        is($key->{size}, 1);

        is($key->{owner_id},          $OWNER_ID);
        is($key->{owner_displayname}, $OWNER_DISPLAYNAME);

        # You can't delete a bucket with things in it
        ok(!$bucket_obj->delete_bucket());

        $bucket_obj->delete_key($keyname);

        # now play with the file methods
        my $readme_md5  = file_md5_hex('README');
        my $readme_size = -s 'README';
        $keyname .= "2";
        $bucket_obj->add_key_filename(
                                    $keyname, 'README',
                                    {
                                    content_type        => 'text/plain',
                                    'x-amz-meta-colour' => 'orangy',
                                    }
        );
        $response = $bucket_obj->get_key($keyname);
        is($response->{content_type}, 'text/plain');
        like($response->{value}, qr/Testing S3 is a tricky thing/);
        is($response->{etag},                $readme_md5);
        is($response->{'x-amz-meta-colour'}, 'orangy');
        is($response->{content_length},      $readme_size);

        unlink('t/README');
        $response = $bucket_obj->get_key_filename($keyname, undef, 't/README');
        is($response->{content_type},        'text/plain');
        is($response->{value},               '');
        is($response->{etag},                $readme_md5);
        is(file_md5_hex('t/README'),         $readme_md5);
        is($response->{'x-amz-meta-colour'}, 'orangy');
        is($response->{content_length},      $readme_size);

        $bucket_obj->delete_key($keyname);

        # try empty files
        $keyname .= "3";
        $bucket_obj->add_key($keyname, '');
        $response = $bucket_obj->get_key($keyname);
        is($response->{value},          '');
        is($response->{etag},           'd41d8cd98f00b204e9800998ecf8427e');
        is($response->{content_type},   'binary/octet-stream');
        is($response->{content_length}, 0);
        $bucket_obj->delete_key($keyname);

        # fetch contents of the bucket
        # note prefix, marker, max_keys options can be passed in
        $response = $bucket_obj->list
        or die $s3->err . ": " . $s3->errstr;
        is($response->{bucket},       $bucketname);
        is($response->{prefix},       '');
        is($response->{marker},       '');
        is($response->{max_keys},     1_000);
        is($response->{is_truncated}, 0);
        is_deeply($response->{keys}, []);

        ok($bucket_obj->delete_bucket());
    }
}

# see more docs in Amazon::S3::Bucket

# local test methods
sub is_request_response_code {
    my ($url, $code, $message) = @_;
    my $request = HTTP::Request->new('GET', $url);

    #warn $request->as_string();
    my $response = $s3->ua->request($request);
    is($response->code, $code, $message);
}

sub like_acl_allusers_read {
    my ($bucketobj, $keyname) = @_;
    my $message = acl_allusers_read_message('like', @_);
    like($bucketobj->get_acl($keyname), qr(AllUsers.+READ), $message);
}

sub unlike_acl_allusers_read {
    my ($bucketobj, $keyname) = @_;
    my $message = acl_allusers_read_message('unlike', @_);
    unlike($bucketobj->get_acl($keyname), qr(AllUsers.+READ), $message);
}

sub acl_allusers_read_message {
    my ($like_or_unlike, $bucketobj, $keyname) = @_;
    my $message = $like_or_unlike . "_acl_allusers_read: " . $bucketobj->bucket;
    $message .= " - $keyname" if $keyname;
    return $message;
}

sub acl_xml_from_acl_short {
    my $acl_short = shift || 'private';

    my $public_read = '';
    if ($acl_short eq 'public-read') {
        $public_read = qq~
            <Grant>
                <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:type="Group">
                    <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
                </Grantee>
                <Permission>READ</Permission>
            </Grant>
        ~;
    }

    return qq~<?xml version="1.0" encoding="UTF-8"?>
    <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <Owner>
            <ID>$OWNER_ID</ID>
            <DisplayName>$OWNER_DISPLAYNAME</DisplayName>
        </Owner>
        <AccessControlList>
            <Grant>
                <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:type="CanonicalUser">
                    <ID>$OWNER_ID</ID>
                    <DisplayName>$OWNER_DISPLAYNAME</DisplayName>
                </Grantee>
                <Permission>FULL_CONTROL</Permission>
            </Grant>
            $public_read
        </AccessControlList>
    </AccessControlPolicy>~;
}

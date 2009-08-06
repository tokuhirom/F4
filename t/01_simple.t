use strict;
use warnings;
use Test::TCP;
use Test::More;
use F4;
plan skip_all => 'this test requires $ENV{TEST_F4_AWS_HOST}' unless $ENV{TEST_F4_AWS_HOST};
use Test::Requires qw/
    Amazon::S3
/;
plan tests => 5;
use File::Temp;
use F4::Registrar;

my $db = File::Temp->new(UNLINK => 0);

test_tcp(
    client => sub {
        my $port = shift;
        config('Model::DB')->{db} = {
            dsn => "dbi:SQLite:dbname=$db",
        };
        my $account = model('Account')->create();
        diag $account->access_key_id;
        diag $account->secret_access_key;
        my $s3 = Amazon::S3->new({
            aws_access_key_id     => $account->access_key_id,
            aws_secret_access_key => $account->secret_access_key,
            host                  => "$ENV{TEST_F4_AWS_HOST}:$port",
        });
        my $bucket = $s3->add_bucket({ bucket => 'foo' });
        ok $bucket, $s3->err || 'ok';
        $bucket->add_key(
            'test.txt', 'foo', {
                content_type => 'text/plain',
            },
        );
        my $res = $bucket->get_key('test.txt');
        is $res->{content_type}, 'text/plain';
        is $res->{value}, 'foo';
        is $res->{content_length}, 3;
        ok $bucket->delete_key('test.txt');
        diag $s3->err if $s3->err;
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


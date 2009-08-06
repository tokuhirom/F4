package F4::Model::Account;
use F4::Model;
use String::Random qw/random_regex/;

sub create {
    my ($class, ) = @_;
    model('DB')->set(
        'account' => {
            access_key_id     => random_regex('[a-z0-9A-Z]{20}'),
            secret_access_key => random_regex('[a-z0-9A-Z]{40}'),
        }
    );
}

sub get {
    my ($class, $access_key_id) = @_;
    my $row = model('DB')->lookup(
        'account' => $access_key_id,
    );
    $row;
}

1;

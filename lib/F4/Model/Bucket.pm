package F4::Model::Bucket;
use F4::Model;

sub get {
    my ($class, $name) = @_;
    model('DB')->lookup(
        'bucket' => $name
    );
}

sub create {
    my ($class, $name, $owner_access_key_id) = @_;
    model('DB')->set(
        'bucket' => {
            name                => $name,
            owner_access_key_id => $owner_access_key_id,
        }
    );
}

1;

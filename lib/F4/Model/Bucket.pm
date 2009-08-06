package F4::Model::Bucket;
use F4::Model;

sub get {
    my ($class, $name) = @_;
    model('DB')->lookup(
        'bucket' => $name
    );
}

sub create {
    my ($class, $name) = @_;
    model('DB')->set(
        'bucket' => { name => $name }
    );
}

sub add_key {
    my ($class, $bucket, $key, $content_type, $content) = @_;
    model('DB')->set(
        'key' => {
            key          => $key,
            content_type => $content_type,
            content      => $content,
            bucket_name  => $bucket->name,
        }
    );
}

sub get_key {
    my ($class, $bucket, $key) = @_;
    my ($key) = model('DB')->get(
        key => {
            index => {
                bucket_key => [
                    $bucket->name, $key
                ]
            }
        }
    );
    return $key;
}

sub delete_key {
    my ($class, $bucket, $key) = @_;
    return model('DB')->delete(
        key => {
            index => {
                bucket_key => [
                    $bucket->name, $key
                ],
            }
        }
    );
}

1;

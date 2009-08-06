package F4::Model::Key;
use F4::Model;

sub add {
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

sub get {
    my ($class, $bucket, $key) = @_;
    my ($key_row) = model('DB')->get(
        key => {
            index => {
                bucket_key => [
                    $bucket->name, $key
                ]
            }
        }
    );
    return $key_row;
}

sub delete {
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

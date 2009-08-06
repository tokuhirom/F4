package F4::Model::DB;
use strict;
use warnings;
use base qw/Data::Model/;
use Data::Model::Schema;
use F4::Registrar;
use Data::Model::Driver::DBI;

sub init {
    my $self = shift;
    my $conf = config('Model::DB')->{'db'};
    my $driver = Data::Model::Driver::DBI->new(
        %{ config('Model::DB')->{'db'} }
    );
    $self->set_base_driver($driver);
}

sub setup_schema {
    my $self = shift;
    for my $target ( $self->schema_names ) {
        for my $sql ( $self->as_sqls($target) ) {
            $self->get_driver($target)->r_handle->do($sql);
        }
    }
}

install_model account => schema {
    key 'access_key_id';

    column 'access_key_id' => char => { binary => 1, size => 20 };
    column 'secret_access_key' => char => { binary => 1, size => 40 };
};

install_model bucket => schema {
    key 'name';
    index owner_access_key_id => ['owner_access_key_id'];

    column 'owner_access_key_id' => char => { binary => 1, size => 20 };
    column 'name' => varchar => { binary => 1, size => 255 };
};

install_model key => schema {
    key 'key';
    index bucket_key => ['bucket_name', 'key'];

    column 'key' => varchar => { binary => 1, size => 255 };
    column 'content' => blob => { required => 1 };
    column 'content_type' => varchar => { binary => 1, size => 255 };
    column 'bucket_name' => varchar => {binary => 1, size => 255};
};

1;

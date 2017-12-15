package Job::Async::Job;

use strict;
use warnings;

sub id { shift->{id} }
sub data {
    my ($self, $key) = @_;
    return $self->{data} unless defined $key;
    return $self->{data}{$key};
}
sub future { shift->{future} }
sub done {
    my ($self, @args) = @_;
    $self->future->done(@args);
}
sub fail {
    my ($self, @args) = @_;
    $self->future->fail(@args);
}

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}


1;

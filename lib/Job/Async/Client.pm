package Job::Async::Client;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

use Job::Async::Job;

sub submit {
    my ($self, %args) = @_;
    ...
}

1;


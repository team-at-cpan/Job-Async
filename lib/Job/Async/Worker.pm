package Job::Async::Worker;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

use Ryu::Async;

use Job::Async::Job;

sub jobs {
    my ($self) = @_;
    $self->{jobs} ||= do {
        $self->ryu->source(
            label => 'jobs'
        )
    };
}

sub stop {
    my ($self) = @_;
    my $f = $self->jobs->completed;
    $f->done unless $f->is_ready;
}

sub ryu {
    my ($self) = @_;
    $self->{ryu} ||= do {
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu;
    };
}

1;


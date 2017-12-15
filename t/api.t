use strict;
use warnings;

use Test::More;
use IO::Async::Loop;

my @pending_jobs;
{
    package Job::Async::Worker::Memory;
    use parent qw(Job::Async::Worker);
    use Future::Utils qw(repeat);
    sub start {
        my ($self) = @_;
    }
    sub trigger {
        my ($self) = @_;
        $self->{active} ||= (repeat {
            my $loop = $self->loop;
            my $f = $loop->new_future;
            $self->loop->later(sub {
                if(my $job = shift @pending_jobs) {
                    $self->process($job);
                }
                $f->done;
            });
            $f;
        } while => sub { 0+@pending_jobs })->on_ready(sub {
            delete $self->{active}
        })
    }
    sub process {
        my ($self, $job) = @_;
        $self->jobs->emit($job);
    }
}
{
    package Job::Async::Client::Memory;
    use parent qw(Job::Async::Client);
    sub start {
        my ($self) = @_;
    }
    sub submit {
        my ($self, %args) = @_;
        push @pending_jobs, my $job = Job::Async::Job->new(
            data => $args{data},
            id => rand(1e9),
            future => $self->loop->new_future,
        );
        $job->future
    }
}

subtest api => sub {
    my $loop = IO::Async::Loop->new;
    $loop->add(
        my $worker = new_ok('Job::Async::Worker::Memory')
    );
    $loop->add(
        my $client = new_ok('Job::Async::Client::Memory')
    );
    my $seen = 0;
    $worker->jobs->each(sub {
        ++$seen;
        $_->done(
            $_->data('x') + $_->data('y')
        );
    });
    is($seen, 0, 'no jobs yet');
    ok(my $job = $client->submit(
        data => {
            x => 1,
            y => 2
        }
    ), 'can submit a job');
    isa_ok($job, 'Future');
    is($seen, 0, 'worker has not yet been triggered');
    ok(!$job->is_ready, '... and the job is still pending');
    $worker->trigger;
    Future->needs_any(
        $job,
        $loop->timeout_future(after => 1)
    )->get;
    is($seen, 1, 'worker saw the job');
    ok($job->is_done, 'job is now done') or note explain $job->state;
    die 'job not ready' unless $job->is_ready;
    is($job->get, 3, 'result was correct') or note explain $job->state;
    $worker->stop;
    Future->needs_all(
        $worker->jobs->completed
    )->get;
};

done_testing;



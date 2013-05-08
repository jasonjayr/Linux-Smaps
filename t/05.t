use strict;
use Test::More;
use Linux::Smaps ();            # avoid import()

# this test checks the behaviour of Linux::Smaps with
# kernel threads.

# first: find one
my $pid;
if(opendir my $d, '/proc') {
  while( defined(my $e=readdir $d) ) {
    next unless $e=~/^\d+$/;
    my $statm=do{ local @ARGV=("/proc/$e/statm"); readline };
    next unless $statm=~/^(0 )+0$/;
    open my $f, '<', "/proc/$e/smaps" or next;
    my $n=sysread $f, my $buf, 0;
    defined $n or next;
    $n==0 or next;

    $pid=$e;
    last;
  }
}

unless( defined $pid ) {
  plan skip_all => 'No kernel thread found';
  exit 0;
}

#plan tests => 4;

note "Found kernel thread with PID $pid";

my $s=eval { Linux::Smaps->new($pid) };
ok $s, "Object constructed";

eval {$s->size};
like $@, qr{Can't locate object method "size" via package "Linux::Smaps"},
  q{Can't locate object method "size" via package "Linux::Smaps"};

Linux::Smaps->import(procdir=>'/proc');

is eval {$s->size}, 0, "methods are initialized after ->import";

done_testing;

# Local Variables:
# mode: perl
# End:

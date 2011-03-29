use Test::More tests => 10;
use POSIX ();
use Linux::Smaps;

POSIX::setlocale( &POSIX::LC_ALL, "C" );
my ($s, $old);

my $fn=$0;
$fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
$fn='.' unless( length $fn );

SKIP: {
  skip "Your kernel lacks /proc/PID/smaps support", 8
    unless( -r '/proc/self/smaps' );

  $s=Linux::Smaps->new;

  $old=Linux::Smaps->new;

  ok $s, 'constructor';

  ok scalar grep( {$_->file_name=~/perl/} $s->vmas), 'perl found';

  my ($newlist, $difflist, $oldlist)=$s->diff( $s );

  ok @$newlist==0 && @$difflist==0 && @$oldlist==0, 'no diff';

  my $dirty=$s->private_dirty;
  {
    no warnings qw{void};
    "a"x(1024*1024);
  }
  $s->update;
  print "# dirty grows from $dirty to ".$s->private_dirty."\n";
  ok $s->private_dirty>$dirty+1024, 'dirty has grown';

  ($newlist, $difflist, $oldlist)=$s->diff( $old );
  my ($newlist2, $difflist2, $oldlist2)=$old->diff( $s );

  ok eq_set($newlist, $oldlist2), 'newlist=oldlist2';
  ok eq_set($difflist, [map {[@{$_}[1,0]]} @$difflist2]), 'difflist=difflist2';
  ok eq_set($oldlist, $newlist2), 'oldlist=newlist2';

  my $pid; sleep 1 until defined( $pid=fork );
  unless( $pid ) {
    exec $^X, '-MPOSIX', '-e', 'sleep 10';
    die;
  }
  select undef, undef, undef, .2;  # let the child start up
  $s->pid=$pid; $s->update;
  ok scalar( grep {$_->file_name=~/POSIX\.so$/} $s->vmas ), 'other process';
  kill 'KILL', $pid;
}

eval {Linux::Smaps->new(0)};
ok $@ eq "Linux::Smaps: Cannot open /proc/0/smaps: No such file or directory\n",
  'error1';

$s=Linux::Smaps->new(uninitialized=>1);
$s->pid=-1; $s->update;
ok $s->lasterror eq "Cannot open /proc/-1/smaps: No such file or directory",
  'error2';

# Local Variables:
# mode: perl
# End:

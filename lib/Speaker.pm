use strict;
use warnings;

package Speaker;

sub new { my ($class, $PID) = @_;
    my $this = {};
    bless ($this, $class);
    $this->{PID} = $PID;
    print "\n\n+++PID #$this->{PID} was created !\n\n";
    return $this;
}

sub DESTROY {
    my ($this) = @_;
    print "\n\n---PID #$this->{PID} was destroyed !\n\n";
}

1;

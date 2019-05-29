use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

use Forker;

sub traitement {
    sleep int(rand(10));
}

my $compute = \&traitement;
my $buffer = {};
my $forker = Forker->new($buffer);
my $scal = [];

print ref $compute;


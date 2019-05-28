use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

use Forker;

my $buffer = {};
my $forker = Forker->new($buffer);
my $scal = [];
print ref $scal;

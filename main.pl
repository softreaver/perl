use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

use Forker;

sub traitement1 {
    my ($buffer, $arg1, $arg2) = @_;
    print "début du traitement 1 ...\n";
    print "arg1 = $arg1 -- arg2 = $arg2\n\n\n";
    sleep 2;
    print "fin traitement 1\n\n\n";
}

sub traitement2 {
    my ($buffer, $arg1, $arg2) = @_;
    print "début du traitement 2 ...\n";
    print "arg1 = $arg1 -- arg2 = $arg2\n\n\n";
    sleep 5;
    print "fin traitement 2\n\n\n";
}

sub callback {
    print "==== CALLBACK ====\n\n\n";
}

my $buffer = {};
my $forker = Forker->new($buffer);

# Démarrage des traitements 
$forker->exec(\&traitement1, '\&callback', 't1-arg1', 't1-arg2');
$forker->exec(\&traitement2, '\&callback', 't2-arg1', 't2-arg2');

sleep 10;

print "\n\n================= Fin du programme !===================";

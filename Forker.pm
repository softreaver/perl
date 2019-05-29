use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
 
use IPC::Shareable;
use Speaker;

package Forker;

# Variables statiques privées permettant le bon fonctionnement du module.
my $glue = 'fork';
my $buffGlue = 'buff';
my %options = (
    create    => 'yes',
    exclusive => 0,
    destroy   => 'yes',
);

my $self;               # Références vers l'instance singleton de la classe.
my $mainPID;            # ID du process servant de process pères aux différents Forks fils.
my @forkChilds = ();    # Liste permettant le ressencement de tous les forks fils.
my @taskQueu = ();      # 
my $buffer;             # Référence vers une table de hash partagée.

# Ajout des variables partagées au segment de mémoire partagé.
tie @forkChilds, 'IPC::Shareable', $glue, { %options } or die "tie failed\n";
tie $buffer, 'IPC::Shareable', $buffGlue, { %options } or die "tie failed\n";  


=head1 CONSTRUCTEUR
=cut
sub new { my ($class, $buffer) = @_;
    my $this = {};
    #make it singleton
    #if not defined $self {
    #    bless ($this, $class);
    #    $self = $this;
    #    return $this;
    #} else {
    #    return $self;
    #}
    bless ($this, $class);
    $this->{buffer} = $buffer || {};
    return $this;
}

=head1 NAME
    EXEC

=head1 SYNOPSIS
    $forker->exec(\&myFunction);

=head1 DESCRIPTION
    Method that will execute a fork

=over
=item ARG1 - Reference to the function containing all computing
=back

=cut
sub exec { my ($this, $function, @args) = @_;
    if (not defined $mainPID) {
        $mainPID = fork() or die($!);
        _startProcess($function, @args) if not $mainPID;
    } else {
        _addFork($function, @args);
    }
}

sub DESTROY {
    # Tuer le processus père et tous les processus fils
    kill -$mainPID if (defined $mainPID);
}

# Méthode utils privée
sub _startProcess { my ($function, @args) = @_;
    # Vérifie si le premier paramètre est bien une référence sur fonction
    die "ERREUR -> le premier paramètre de la fonction doit être une reference sur fonction !" if (ref $function != 'CODE');

    # Démarrage du traitement dans un nouveau fork
    my $mainPID = fork or die($!);
    if (not $mainPID) {
        # Ajout du traitement
        _addFork($function, @args);
    } else {
        # Ecoute la fin 
        while (1) {

        }
    }
}

sub _addFork { my ($function, @args) = @_;
    # Vérifie si le premier paramètre est bien une référence sur fonction
    die "ERREUR -> le premier paramètre de la fonction doit être une reference sur fonction !" if (ref $function != 'CODE');

    # Démarrage du traitement dans un nouveau fork
    my $PID = fork or die($!);
    if (not $PID) {
        # Child process
        $function->(@args);
    } else {
        # Parent process
        push (@forkChilds, $PID);
    }
}

1;

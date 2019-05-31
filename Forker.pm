use strict;
use warnings;
use POSIX ":sys_wait_h";
use FindBin;
use lib "$FindBin::Bin";
 
use IPC::Shareable;
use Speaker;

package Forker;

#use English;
# eval {

# };
# if ($EVAL_ERROR) {

# }


# # Variables statiques privées permettant le bon fonctionnement du module.
# my $glue = 'fork';
# my $buffGlue = 'buff';
# my %options = (
#     create    => 'yes',
#     exclusive => 0,
#     destroy   => 0,
# );
# my %retrievalOptions = (
#     create    => 0,
#     exclusive => 0,
#     destroy   => 0,
# );

=head1 CONSTRUCTEUR
=cut
sub new { my ($class, $buffer, $keepSharedMemAlive) = @_;
    my $this = {};
    bless ($this, $class);

    $this->{mainPID} = undef;                                   # ID du process servant de process pères aux différents Forks fils.
    $this->{forkChilds} = ();                                        # Table de hash permettant de ressencer tous les forks fils.
    $this->{buffer} = {};                                       # Référence vers une table de hash partagée.
    $this->{keepSharedMemAlive} = $keepSharedMemAlive || 0;     # Définit si le segment de mémoire partagé doit être gardé ou non une fois l'instance de classe détruite. Par défaut = false.
    $this->{tasksQueue} = ();                                   # Liste des traitement en attente d'être forké.

    # Ajout des variables partagées au segment de mémoire partagé.
    tie $this->{forkChilds}, 'IPC::Shareable', $glue, { %options } or die "tie failed\n";
    tie $this->{buffer}, 'IPC::Shareable', $buffGlue, { %options } or die "tie failed\n";
    tie $this->{tasksQueue}, 'IPC::Shareable', $buffGlue, { %options } or die "tie failed\n";

    return $this;
}

=head1 NOM
    exec
=head1 SYNOPSIS
    $forker->exec( \&myFunction, \&callback [, arg1[, arg2, ...]] );
=head1 DESCRIPTION
    Méthode permettant de lancer un traitement dans un fork
=head1 PARAMETRES
=over
=item \&function - Référence vers la fonction effectuant le traitement
=item \&callback - Référence vers la fonction servant de callback
=item @args - Une liste d'arguments à passer au traitement
=back

=head2 Paramètres envoyés à function
=over
=item $buffer - Une référence vers la table de hash contenant les données partagées.
=item @args - La liste des arguments transmise via la méthode exec.
=back

=head2 Paramètres envoyés à callback
=over

=back

=cut
sub exec { my ($this, $function, $callback, @args) = @_;
    # Récupère et bind les variables appartenant à la mémoire partagée
    tie $this->{forkChilds}, 'IPC::Shareable', $glue, { %retrievalOptions } or die "tie failed\n";
    tie $this->{buffer}, 'IPC::Shareable', $buffGlue, { %retrievalOptions } or die "tie failed\n";
    tie $this->{tasksQueue}, 'IPC::Shareable', $buffGlue, { %retrievalOptions } or die "tie failed\n";

    if (not defined $this->{mainPID}) {
        $this->{mainPID} = fork();
        die($!) if (not defined $this->{mainPID});

        if (not $this->{mainPID}) {
            _daemonProcessHandling($this);
        } else {
        return _addFork($this, $function, $callback, @args);
        }
    } else {
        return _addFork($this, $function, $callback, @args);
    }
    return undef;
}

sub DESTROY {
    my $this = shift;
    # Tuer le processus père et tous les processus fils
    kill -$this->{mainPID} if (defined $this->{mainPID});

    # Supprimer le segment mémoire partagé s'il y en a un et si demandé
    IPC::Shareable->clean_up() if (not $this->{keepSharedMemAlive});
}

# ======================================================
#               Méthode utiles privée
# ======================================================

sub _addFork { my ($this, $function, $callback, @args) = @_;
    # Ajoute le traitement dans la liste d'attente. Celui-ci sera démarré par le procéssus principale.
    my $size = push(@{$this->{tasksQueue}}, [$function, $callback, @args]);
    return $size - 1;
}

sub _daemonProcessHandling { my $this = shift;
    # Boucle jusqu'à ce que le processus soit terminé (KILL)
    while (1) {
        while ( ( my $pid = waitpid( -1, POSIX::WNOHANG ) ) > 0 ) {
            # appel la callback si elle existe
            $this->{forkChilds}{$pid}->() if (exists($this->{forkChilds}{$pid}) && ref($this->{forkChilds}{$pid}) == 'CODE');

            # Supprime le processus fils de la liste
            delete($this->{forkChilds}{$pid});
        }

        # Lance les traitement en attente
        print 'prout';
        foreach my $task (@{$this->{tasksQueue}}) {
            # Récupération de la fonction de traitement et des arguments
            my ($function, $callback, @args) = @$task;

            my $pid = fork() or die ($!);

            if (not $pid) {
                # -- Processus fils --
                # Démarrage du traitement
                $function->($this->{buffer}, @args);
            } else {
                # -- Processus père --
                # Ajout du PID du processus fils à la liste
                $this->{forkChilds}{$pid} = $callback;
            }
            
        }
        sleep 1;
    }
}

1;

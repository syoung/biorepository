use MooseX::Declare;
class apps extends Agua::Ops {

use Data::Dumper;

has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'repotype'	=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);

####///}}}}

method install {
	my $selectedversion	=	$self->version();
	my $installdir		=	$self->installdir();
	my $credentials 	= 	$self->credentials();
	#print "agua.pm    credentials: $credentials\n" if defined $credentials;
	
	#### SET USER AND REPO NAMES
	my $reponame = "bioapps";
	my $login = "syoung";
	$self->repotype("github");
	
	#### CHECK VERSION IS VALID IF SUPPLIED
	my $tags = $self->getRemoteTags($login, $reponame);
	my $validversion = 0;
	#print "agua.pm    selectedversion: $selectedversion\n" if defined $selectedversion;
	foreach my $tag ( @$tags ) {
		$validversion = 1 if defined $selectedversion and $tag->{name} eq $selectedversion;
	}
	if ( defined $selectedversion ) {
		print "Version validated: $selectedversion\n" if $validversion;
		print "Version NOT FOUND: $selectedversion\n" if not $validversion;
		undef $selectedversion if not $validversion;
	}
	
	#### CLONE REPO IF NOT EXISTS
	my $subdir = "$installdir/$reponame";
	if( not $self->dirFound($subdir) ) {
		$self->changeDir($installdir);
		$self->cloneRemoteRepo($login, $reponame);
	}
	#### OTHERWISE, MOVE TO REPO AND PULL
	else {
		$self->changeDir($subdir);
		print "Pulling repo $reponame (owner: $login)\n";
		$self->pullRemoteRepo($login, $reponame);
	}

	##### CHECKOUT SPECIFIC VERSION
	$self->changeDir($subdir);
	$self->checkoutTag($selectedversion) if defined $selectedversion;
	print "Completed installation.\n";

	my $installedversion;
	$installedversion = $selectedversion if defined $selectedversion;
	my ($currenttag) = $self->currentLocalTag();
	$installedversion = $currenttag if not defined $selectedversion;
	my ($iterations) = $self->currentIteration();
	print "Installed version: $currenttag, build: $iterations\n";

	#### UPDATE DATABASE
	$self->updatePackage($login, $reponame, $installedversion);
}




}

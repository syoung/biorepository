package agua;
use Moose::Role;
use Method::Signatures::Simple;

use Data::Dumper;

has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/agua'	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempconffile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

####///}}}}

#### PRE-INSTALL
method preInstall {
	$self->logDebug("");

	#### SET VARIABLES
    $self->owner("agua");
	$self->repository("agua");
	$self->package("agua");
	$self->repotype("github");
	$self->private(0);

	#### CHECK INPUTS
	$self->checkInputs();

	#### MOVE CONF FILE
	$self->moveConf();

	#### REPORT PROGRESSS
	$self->updateReport(["Doing preInstall"]);
	my 	$aguaversion 	= $self->conf()->getKey('agua', 'VERSION');
	$self->updateReport(["Current version: $aguaversion"]);
	
	return "Completed preInstall";
}

#### POST-INSTALL
method postInstall {
	$self->logDebug("");

	#### UPDATE CONFIG FILE	
	my $conffile 	=	$self->setConfFile();
	my $tempconf	=	$self->setTempConfFile();
	$self->updateConfig($conffile, $tempconf);

	#### RESTORE CONFIG FILE
	$self->restoreConf();
	
	#### UPDATE CONFIG WITH NEW ENTRIES IF NOT PRESENT
	my $installdir = $self->installdir();
	my $distroconfig = "$installdir/bin/scripts/resources/agua/conf/default.conf";
	$self->updateConfig($distroconfig, $conffile);

	#### UPDATE AGUA VERSION IN CONFIG
	my $version = $self->version();
	$self->logDebug("version", $version);
	$self->conf()->setKey("agua", "VERSION", $version);

	#### RUN INSTALL TO SET PERMISSIONS, ETC.
	$self->runUpgrade();

	return "Completed postInstall";
}
#### UTILS
method runUpgrade {
	my $installdir	=	$self->installdir();
	$installdir = "/agua" if not defined $installdir;
	$self->logDebug("installdir", $installdir);

##### DEBUG 
##### DEBUG 
##### DEBUG 
#	my $permsfile = "$installdir/bin/scripts/resources/agua/permissions.txt";
#	`mv $permsfile $permsfile.safe`;
#	`echo "#### DEBUG EMPTY PERMISSIONS" > $permsfile`;
##### DEBUG 
##### DEBUG 
##### DEBUG 

	my $logfile = $self->logfile();
	$self->changeDir("$installdir/bin/scripts");
	my $command = qq{$installdir/bin/scripts/install.pl \\
--mode upgrade \\
--installdir $installdir \\
--logfile $logfile
};
	$self->logDebug("command", $command);

	$self->runCommand($command);
}

method checkInputs {
	my 	$pwd 			= $self->pwd();
	my 	$username 		= $self->username();
	my 	$version 		= $self->version();
	my  $package 		= $self->package();
	my  $repotype 		= $self->repotype();
	my 	$owner 			= $self->owner();
	my 	$private 		= $self->private();
	my  $repository 	= $self->repository();	
	my 	$aguaversion 	= $self->conf()->getKey('agua', 'VERSION');

	$self->logError("owner not defined") and exit if not defined $owner;
	$self->logError("version not defined") and exit if not defined $version;
	$self->logError("package not defined") and exit if not defined $package;
	$self->logError("username not defined") and exit if not defined $username;
	$self->logError("repotype not defined") and exit if not defined $repotype;
	$self->logError("repository not defined") and exit if not defined $repository;
	$self->logError("aguaversion not defined") and exit if not defined $aguaversion;
	
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);
	$self->logDebug("username", $username);
	$self->logDebug("repotype", $repotype);
	$self->logDebug("repository", $repository);
	$self->logDebug("aguaversion", $aguaversion);
	$self->logDebug("private", $private);
	$self->logDebug("version", $version);
}

method moveConf () {
	my $conffile 	=	$self->setConfFile();
	my $tempconf	=	$self->setTempConfFile();
	my $command = "mv -f $conffile $tempconf; chmod 600 $tempconf";
	$self->logDebug("command", $command);
	
	$self->runCommand($command);
}

method restoreConf {
	my $conffile 	=	$self->setConfFile();
	my $tempconf	=	$self->setTempConfFile();
	my $apacheuser	=	$self->conf()->getKey("agua", "APACHEUSER");
	my $command 	= "mv $tempconf $conffile; chown root:$apacheuser $conffile; chmod 660 $conffile";
	$self->logDebug("command", $command);

	$self->runCommand($command);
}

method setConfFile {
	return $self->conffile() if defined $self->conffile();
	my $installdir 	= 	$self->installdir();
	my $conffile 	=	"$installdir/conf/default.conf";
	$self->conffile($conffile);
	
	return $conffile;
}

method setTempConfFile {
	return $self->tempconffile() if defined $self->tempconffile();
	my $tempdir = "/tempconf";
	`mkdir $tempdir` if not -d $tempdir;
	my $tempconffile 	=	"$tempdir/agua-default.conf";
	$self->tempconffile($tempconffile);
	
	return $tempconffile;
}

1;

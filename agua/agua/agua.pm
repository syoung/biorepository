package agua;
use Moose::Role;
use Method::Signatures::Simple;

use Data::Dumper;

has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/agua'	);
has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'bitbucket'	);
has 'repo'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'github'	);

####///}}}}
method preInstall {
	$self->logDebug("");
	#$self->checkInputs();

	my $pwd = $self->pwd();

	my 	$username 		= $self->username();
	my 	$version 		= $self->version();
	my  $package 		= $self->package();
	my  $repotype 		= $self->repotype();
	my 	$owner 			= $self->owner();
	my 	$private 		= $self->private();
	my  $repository 	= $self->repository();
	
	my $aguaversion = $self->conf()->getKey('agua', 'VERSION');

	$self->logError("owner not defined") and exit if not defined $owner;
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
	$self->logDebug("private", $private) if defined $private;
	$self->logDebug("version", $version) if defined $version;

	#### SEND STATUD
	print "{ status: 'installing', version: '$version' }";

	#### FAKE TERMINATION
	$self->fakeTermination(5);
	$self->logDebug("AFTER fakeTermination");

	#### START LOGGING TO HTML FILE
	my $logfile = $self->setLogfile($package);
	$self->logDebug("logfile", $logfile);
	$self->startHtmlLog($package, $version, $logfile);

	$self->updateReport(["Doing preInstall"]);
	$self->updateReport(["Current version: $aguaversion"]);

	$self->logDebug("repository", $repository);
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);

	#### SET VARIABLES
    $self->owner("agua");
	$self->repository("agua");
	$self->version(undef);
	$self->package("agua");
	$self->repotype("github");
	$self->private(0);
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->branch("master");
	$self->installdir("$pwd/outputs/agua");	
	$self->opsdir("$pwd/../../../../../repos/public/biorepository/syoung/agua");
	
	return "Completed preInstall";
}

method setLogfile ($package) {
	my $htmldir = $self->conf()->getKey('agua', 'HTMLDIR');
	return "$htmldir/$package-upgradelog.html";
}

method startHtmlLog ($package, $version, $logfile) {
	$self->logDebug("");
	my $datetime = `date`;
	my $page = qq{
<html>
<head>
	<title>$package upgrade log</title>
</head>
<body>
<center>
<div class="message"> Upgrading $package to version $version...</div>
$datetime<br>
</center>
<hr>
<pre>};

	#### CREATE LOGFILE
	$self->SHOWLOG(2);
	$self->PRINTLOG(3);
	$self->logDebug("starting logfile: $logfile");
	$self->startLog($logfile);
	$self->logReport($page);
}

method postInstall {
	$self->logDebug("");
	
	#### UPDATE AGUA VERSION IN CONFIG
	my $installdir	=	$self->installdir();
	$installdir = "/agua" if not defined $installdir;
	$self->logDebug("installdir", $installdir);

	#### RUN INSTALL TO SET PERMISSIONS, ETC.
	$self->changeDir("$installdir/bin/scripts");
	my $command = "$installdir/bin/scripts/install.pl --installdir $installdir";
	$self->logDebug("command", $command);
	$self->runInstaller($command);

	return "Completed postInstall";
}


1;

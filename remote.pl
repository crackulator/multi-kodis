
use Term::ReadKey;
use Time::HiRes "usleep";

$debug = 0;

my $ok = 1;
if (!(`xdotool -v` =~ /xdotool version/)) { print "xdotool does not appear to be installed.\n"; $ok=0; }
#todo: detect whether wmctrl is installed
if (!$ok) { exit; }

my @kodis = FindKodis ();
$kodisfound = scalar(@kodis);
print "Found $kodisfound kodi";
if ($kodisfound != 1) { print "s"; }
print ".\n";

if ($kodisfound == 0) {
	print "Nothing to do here.\n";
	exit
}

my $num_args = $#ARGV + 1;
if ($num_args == 1) {
	$scriptname = $ARGV[0];
	open(my $fh, '<:encoding(UTF-8)', "keyscripts/".$scriptname)
		or die "Could not open keyscript file '$scriptname': $!\n";
	print "Executing script '".$scriptname.".keyscript'\n";
	while (my $row = <$fh>) {
		chomp $row;
		if ($row =~ /^(.*)#/) { $row = $1; }
		if ($row =~ /^>\s*(.*)/) {
			print "Found shell command: '$1'.\n";
			print `$1`;
		}
		elsif ($row =~ /^\s*(\d+|wait)\s+([A-Za-z0-9.]+)/) {
			my $which = $1;
			my $key = $2;
			if ($which eq "wait") {
				$secs = $key * 1000000;
				print "Waiting ".$key." second";
				if ($key ne "1") { print "s"; }
				print "\n";
				usleep ($secs);
			} else {
				for my $kodi (@kodis) {
					my $window = @$kodi[0];
					my $number = @$kodi[1];
					if ($number == $which) {
						print "Sending '$key' to Kodi $number.\n";
						SendKey ($window,$key);
						usleep (100000);
					}
				}
			}
		}
	}
	exit;
}

print "Implementation: cursors, enter, backspace, home.\n";
print ",/. = volume up and down, m for mute\n";
print "1-9 to toggle windows, a=all, n=none\n";
print "x to stop, space to pause\n";
print "'q' to quit.\n";

my %mask;

for my $kodi (@kodis) {
	my $number = @$kodi[1];
	$mask{$number} = "on";
}

PrintMask ();

$done = 0; 

ReadMode 4; # Turn off controls keys
while (!$done) {
	($type,$hex,$key) = GetKeySequence ();
	debug_print ($type." ".$hex." ".$key."\n");
	if ($key eq "q") {$done = 1; }
	else {
		$send = "";
		if ($hex eq "1b5b41") { $send = "Up"; }
		elsif ($hex eq "1b5b42") { $send = "Down"; }
		elsif ($hex eq "1b5b44") { $send = "Left"; }
		elsif ($hex eq "1b5b43") { $send = "Right"; }
		elsif ($hex eq "1b4f48") { $send = "Home"; }
		#elsif ($hex eq "1b5b317e") { $send = "Home"; }
		elsif ($hex eq "7f") { $send = "BackSpace"; }
		elsif ($hex eq "a") { $send = "Return"; }
		elsif ($hex eq "2c") { $send = "minus"; }
		elsif ($hex eq "2e") { $send = "plus"; }
		elsif ($hex eq "6d") { $send = "F8"; }
		elsif ($hex eq "78") { $send = "x"; }
		elsif ($hex eq "20") { $send = "space"; }
		elsif ($hex eq "61") { 
			while (my ($i, $value) = each(%mask) ) {
				$mask{$i} = "on";
			}
			PrintMask ();
		}
		elsif ($hex eq "6e") { 
			while (my ($i, $value) = each(%mask) ) {
				$mask{$i} = "off";
			}
			PrintMask ();
		}
		elsif (($hex >= 31) && ($hex <= 39)) {
			my $n = $hex - 30;
			if (exists($mask{$n})) {
				if ($mask{$n} eq "on") { $mask{$n} = "off"; }
				else { $mask{$n} = "on"; }
			}
			PrintMask ();
		} else {
			print "No action for '$hex'.\n";
		}
		if ($send ne "") {
			for my $kodi (@kodis) {
				my $window = @$kodi[0];
				my $number = @$kodi[1];
				if ($mask{$number} eq "on") {
					SendKey ($window,$send);
				}
			}
		}
	}
}

ReadMode 0; # Reset tty mode before exiting

sub SendKey {
	($window,$send) = @_;
	RunCommand ("xdotool key --window $window $send");
}	

sub GetKeySequence {
	my $key = GetKey();
	my $hex = sprintf ("%x",ord($key));
	if ($hex eq "1b") {
		my $retval = $hex;
		$retval .= sprintf ("%x",ord(GetKey()));
		$retval .= sprintf ("%x",ord(GetKey()));
		#if ($retval == "1b5b31") {
		#	$retval .= sprintf ("%x",ord(GetKey()));
		#}
		return ("ctrl",$retval,"");
	} else {
		return ("ascii",$hex,$key);
	}
}

sub GetKey {
    while (not defined ($key = ReadKey(-1))) {   usleep (5000); };
    # debug_print ("Get key (".sprintf ("%x",ord($key)).")\n");
	return $key;
}
	
sub FindKodis {
	my @kodis = ();
	$output = RunCommand ("wmctrl -l");
	my @lines   = split /\n/ => $output;
	for my $line (@lines) {
		#print $line . "\n";
		if ($line =~ /^([x0-9a-f]+).*\sKodi(\s(\d+))?/) { push(@kodis,[$1,int($3)]); }
	}
	return @kodis;
}

sub RunCommand {
	my ($c) = @_;
	debug_print ($c . "\n");
	my $output = `$c`;
	debug_print ($output);
	return $output;
}

sub debug_print {
	if ($debug) { print @_; }
}

sub PrintMask {
	print "Controlling windows: ";
	foreach my $i (sort keys %mask) {
		if ($mask{$i} eq "on") { print $i; }
		else { print "."; }
		print " ";
	}
	print "\n";
}

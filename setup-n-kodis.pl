
use POSIX;
use Data::Dumper qw(Dumper);

# todo: add 'kill' by number and 'kill all'
# todo: finger each window after swap (to fix pip problem)
# todo: arrange windows according to new arrangement, not present arrangement (as they are being assembled)

my $debug = 0;

#default
my $num_kodis;

my %kodis;

my $special = 0;
my $arrangement = "";
my @spec;
my @specials_sort;
my %specials_desc;

my $space_width;
my $space_height;
my $offset_width;
my $offset_height;

my %specials;
my %settings;

ReadSettings ("settings");

my $margin_ratio = $settings{"margin_ratio"};
my $window_ratio = $settings{"window_ratio"};
my $titlebar_height = $settings{"titlebar_height"};

my $reserve_top = $settings{"reserve_top"};
my $reserve_bottom = $settings{"reserve_bottom"};
my $reserve_left = $settings{"reserve_left"};
my $reserve_right = $settings{"reserve_right"};

debug_print ("Settings values:\n");
while (($key, $value) = each %settings) {
	debug_print ("$key: $value\n");
}

my $efficiency;

if (($ENV{'DISPLAY'} eq "") || ($ENV{'XAUTHORITY'} eq "")) {
	print "The 'DISPLAY' and/or 'XAUTHORITY' environment variables are not set.\n";
	print "These variables are needed by wmctrl, and may be set automatically\n";
	print "  or you may need to set them manually.\n";
	print "You may be able to swag them in your .bashrc, thus:\n";
	print " if [ -z \"\$DISPLAY\" ]; then DISPLAY=:0; export DISPLAY; fi\n";
	print " if [ -z \"\$XAUTHORITY\" ]; then XAUTHORITY=/home/[user]/.Xauthority; export XAUTHORITY; fi\n";
	print "(for nominal single-display cases)\n";
	exit;
}

my $list_arrs = 0;

$num_args = $#ARGV + 1;
if ($num_args >= 1) {
	$arg = $ARGV[0];
	if ($arg eq "setup") {
		$arg2 = $ARGV[1];
		if (exists ($specials{$arg2})) {
			# specify a window arrangement
			$special = 1;
			$arrangement = $arg2;
			@spec = @{$specials{$arrangement}};
			# first element in the array is the grid; the rest are the windows
			$num_kodis = scalar (@spec)-1;
		} elsif ($arg2 =~ /^(\d+)$/) {
			# specify just the number of windows, arranged in grid
			$num_kodis = $arg2;
		} elsif ($arg2 =~ /^([+-])(\d+)$/) {
			# increment or decrement number of kodis with +1, -2, etc
			%kodis = FindKodis();
			$num_kodis = keys %kodis;
			if ($1 eq "+") { $num_kodis = $num_kodis + $2; }
			if ($1 eq "-") { $num_kodis = $num_kodis - $2; }
		} else {
			print "Couldn't interpret what to set up.\n";
			print "Should be a known window arrangement, +/-number, or just a number.\n";
			$list_arrs = 1;
		}
	} elsif ($arg eq "swap") {
		# swap the positions and titles of two windows
		if (($num_args == 3) && ($ARGV[1] =~ /^\d+$/) && ($ARGV[2] =~ /^\d+$/)) {
			SwapWindows ($ARGV[1],$ARGV[2]);
			exit;
		} else {
			print "Need 2 arguments, the numbers of the kodis to swap (like 'swap 1 2').\n";
			exit;
		}
	} elsif (($arg eq "list") && ($num_args == 1)) {
		# list the available window arrangements
		$list_arrs = 1;
	} elsif (($arg eq "select") && ($ARGV[1] =~ /^\d+$/)) {
		# select a certain window
		$number = $ARGV[1];
		%kodis = FindKodis();
		if (exists($kodis{$number})) {
			RunCommand ("wmctrl -i -a ".$kodis{$number});
		} else {
			print "No such window found.\n";
		}
		exit;
	} elsif (($arg eq "name") && ($num_args > 2)) {
		%kodis = FindKodis();
		$number = $ARGV[1];
		if (exists($kodis{$number})) {
			my $window = $kodis{$number};
			my $name = "Kodi $number - ";
			for (my $i = 2; $i< $num_args; $i++) { 
				if ($i != 2) { $name = $name . " "; }
				$name = $name . $ARGV[$i];
			}
			print "Renamed kodi $number to '$name'.\n";
			RunCommand ("wmctrl -i -r $window -T \"$name\"");
		} else {
			print "Can't find Kodi $number.\n";
		}
		exit;
	} else {
		print "Couldn't interpret arguments.\n";
		$list_arrs = 1;
	}
} else {
	print "Nothing to do.";
	exit;
}

if ($list_arrs) {
	print "Available window arrangements:\n";
	foreach my $name (@specials_sort) {
		print $name." - ".$specials_desc{$name}."\n";
	}
	print "You can also use any plain number, for a default grid arrangement.\n";
	exit;
}

print "Setting up $num_kodis kodi";
if ($num_kodis > 1) { print "s"; }
if ($special) { print " using special arrangement '$arrangement'"; }
else { print " in default arrangement"; }
print ".\n";

my $output = `wmctrl -d`;

if ($output =~ /(\d+)x(\d+).*\s(\d+),(\d+)*\s(\d+)x(\d+).*/) {
	$space_width = $5;
	$space_height = $6;
	$offset_width = $3 + ($reserve_left * $space_width);
	$offset_height = $4 + ($reserve_top * $space_height);
	$space_width = $space_width * (1 - $reserve_left - $reserve_right);
	$space_height = $space_height * (1 - $reserve_top - $reserve_bottom);
	debug_print ("space width: $space_width\n");
	debug_print ("space height: $space_height\n");
} else {
	print "Couldn't interpret output from 'wmctrl -d'.\n";
	print "Most likely, it is not installed, so you might need to do something like:\n";
	print "  sudo apt-get install wmctrl\n";
	exit ();
}

my $output = `xdotool getwindowfocus`;
my $startingwindow;

if ($output =~ /^(\d+)$/) {
	$startingwindow = $1;
} else {
	print "Couldn't interpret output from 'xdotool getwindowfocus'.\n";
	print "Most likely, it is not installed, so you might need to do something like:\n";
	print "  sudo apt-get install xdotool\n";
	exit ();
}

%kodis = FindKodis ();
$kodisfound = keys %kodis;
print "Found $kodisfound kodi";
if ($kodisfound > 1) { print "s"; }

if ($kodisfound == $num_kodis) {
	print ".\n";
	PositionKodis();
}

if ($kodisfound < $num_kodis) {
	print ", need ".($num_kodis-$kodisfound)." more.\n";
	PositionKodis ();
	for (my $i=0;$i<($num_kodis-$kodisfound);$i++) {
		print "Starting a kodi...\n";
		# enforce between-kodis wait, but not on first one
		if ($i != 0) { sleep ($settings{"delay_between_kodi_opens"}); }
		system ("kodi &");
		sleep ($settings{"delay_between_open_and_positioning"});
		PositionKodis ();
		# don't wait the final startup if this is the last one
		# it's only for between opening one kodi and the next
	}
}

if ($kodisfound > $num_kodis) {
	print ", need to remove ".($kodisfound-$num_kodis)."\n";
	for (my $i=$kodisfound;$i>$num_kodis;$i=$i-1) {
		print "Removing a kodi...\n";
		RunCommand ("wmctrl -i -c ".$kodis{$i});
		sleep ($settings{"delay_between_kodi_closes"});
	}
	PositionKodis ();
}

printf ("Space utilization: %.1f\%\n",$efficiency*100);
print "Done.\n";


sub PositionKodis {

	my %kodis = FindKodis();
	my $current_kodis = keys %kodis;
	
	if ($current_kodis > 0) {
		
		print "Positioning...\n";
		
		my $rows;
		my $cols;

		if ($special) {
			if ($spec[0] =~ /(\d+)x(\d+)/) {
				$cols = $1;
				$rows = $2;
			} else {
				print "Couldn't interpret special dimension: ".$spec[0]."\n";
				exit;
			}
		} else {
			my $sq = ceil(sqrt($current_kodis));
			$cols = $sq;
			$rows = ceil($current_kodis/$cols);
		}
		
		my $xmargin = $space_width * $margin_ratio;
		my $ymargin = $space_height * $margin_ratio;
		my $xstep = ($space_width - $xmargin) / $cols;
		my $ystep = ($space_height - $ymargin) / $rows;
		my $xorigin = $xmargin + $offset_width;
		my $yorigin = $ymargin + $offset_height;
		
		debug_print ( "xmargin: $xmargin\n");
		debug_print ( "ymargin: $ymargin\n");
		debug_print ( "xstep: $xstep\n");
		debug_print ( "ystep: $ystep\n");
		debug_print ( "xorigin: $xorigin\n");
		debug_print ( "yorigin: $yorigin\n");
		
		debug_print ( "cell width: ".($xstep-$xmargin)."\n");
		debug_print ( "cell height: ".($ystep-$ymargin)."\n");

		my $single_width = $xstep - $xmargin;
		my $single_height = $ystep - $ymargin - $titlebar_height;
		
		# This next thing is to center up the cells. If we just centered each window in evenly divided cells, we end up with more space between cells than
		#  on the edges, on whichever axis isn't completely full. So here we figure out which is full, figure out what the other will be,
		#  and adjust the margins so that they take into account the extra space.

		my $adj_height = $single_height / $window_ratio;
		if ($single_width > $adj_height) {
			# if scaled width is greater, use height
			debug_print ("Limited by height.\n");
			$xmargin = ($space_width - ($adj_height * $cols)) / ($cols + 1);
			$xstep = $adj_height + $xmargin;
			$xorigin = $xmargin + $offset_width;
		} else {
			# if scaled height is greater, use width
			debug_print ("Limited by width.\n");
			my $eff_height = ($single_width * $window_ratio) + $titlebar_height;
			debug_print ("Effective height: ".$eff_height."\n");
			$ymargin = ($space_height - ($eff_height * $rows)) / ($rows + 1);
			$ystep = $eff_height + $ymargin;
			$yorigin = $ymargin + $offset_height;
			debug_print ("ymargin: $ymargin\n");
			debug_print ("ystep: $ystep\n");
			debug_print ("yorigin: $yorigin\n");
		}

		my $i=0;
		my $col=0;
		my $row=0;
		my $pixels=0;
		
		my @maxed;

		foreach my $number (sort keys %kodis) {

			$window = $kodis{$number};
					
			my $type,$cell_row,$cell_col,$cell_width,$cell_height;

			if ($special) {
				my $s = $i+1;
				debug_print ("s:".$s."\n");
				debug_print ("spec: ".$spec[$s]."\n");
				if ($spec[$s] =~ /^([0-9.]+),([0-9.]+),([0-9.]+),([0-9.]+)$/) {
					$type = "Norm";
					$cell_col = $1;
					$cell_row = $2;
					$cell_width = $3;
					$cell_height = $4;
				} elsif ((lc($spec[$s]) eq "full") || (lc($spec[$s]) eq "max")) {
					$type = $spec[$s];
					if (lc($spec[$s]) eq "max") {
						push (@maxed,$window);
					}
				} else {
					print "Couldn't interpret window dimensions: ".$spec[$s]."\n";
					exit;
				}
			} else {
				$type = "Norm";
				$cell_col = $col;
				$cell_row = $row;
				$cell_width = 1;
				$cell_height = 1;
			}

			my $avail_width = ($xstep * $cell_width) - $xmargin;
			my $avail_height = ($ystep * $cell_height) - $ymargin - $titlebar_height;
			
			my $x = $xorigin + $xstep * $cell_col;
			my $y = $yorigin + $ystep * $cell_row;
			my $w = $avail_width;
			my $h = $avail_height;
			
			if ($type eq "Norm") {
				
				debug_print ( "cell width: $w\n");
				debug_print ( "cell height: $h\n");
				debug_print ( "cell x: $x\n");
				debug_print ( "cell y: $y\n");
				
				if (($cell_width > 1) || ($cell_height > 1)) {
					# we only have to do this for the large windows created in special cases
					# for a normal grid of 1-cell windows, they are already taken care of by the global centering above
					my $adj_height = $h / $window_ratio;
					if ($w > $adj_height) {
						# if scaled width is greater, use height
						$w = $adj_height;
						$x = $x + ($avail_width-$w)/2;
						debug_print ("Limited by height.\n");
					} else {
						# if scaled height is greater, use width
						$h = ($w * $window_ratio);
						$y = $y + ($avail_height-$h)/2;
						debug_print ("Limited by width.\n");
					}
				}
				
				debug_print ("selected width: $w\n");
				debug_print ("selected height: $h\n");
				debug_print ("selected x: $x\n");
				debug_print ("selected y: $y\n");

				if (!$special && ($row == $rows-1)) {
					if ($current_kodis % $cols != 0) {
						$x = $x + $xstep*($cols-($current_kodis%$cols))/2;
					}
				}
			}

			PositionWindow ("Kodi ".($i+1),$window,$type,$x,$y,$w,$h);
			$pixels = $pixels + ($w * $h);
					
			$i = $i + 1;
			$col = $col + 1;
			if ($col == $cols) {
				$row = $row + 1;
				$col = 0;
			}
		}
		
		# set focus to where it was before we started, unless said window is maximized
		# in which case, we want it to stay on the bottom, where it already is
		my $ismax = 0;
		foreach my $m (@maxed) {
			if ($startingwindow eq hex($m)) { $ismax = 1; }
		}
		if (!$ismax) {
			RunCommand ("wmctrl -i -a ".$startingwindow);
		}
			
		$efficiency = $pixels / ($space_width * $space_height);

	}
}

sub PositionWindow {
	my ($name,$window, $type, $x, $y, $width, $height) = @_;
	if (lc($type) eq "full") {
		RunCommand ("wmctrl -i -r $window -b add,fullscreen");
		RunCommand ("wmctrl -i -r $window -b remove,maximized_vert");
		RunCommand ("wmctrl -i -r $window -b remove,maximized_horz");	
	} elsif (lc($type) eq "max") {
		RunCommand ("wmctrl -i -r $window -b remove,fullscreen");
		RunCommand ("wmctrl -i -r $window -b add,maximized_vert");
		RunCommand ("wmctrl -i -r $window -b add,maximized_horz");
	} elsif (lc($type) eq "norm") {
		my $coords = int($x).",".int($y).",".int($width).",".int($height);
		debug_print ("Positioning $window\n");
		RunCommand ("wmctrl -i -r $window -b remove,fullscreen");
		RunCommand ("wmctrl -i -r $window -b remove,maximized_vert");
		RunCommand ("wmctrl -i -r $window -b remove,maximized_horz");
		RunCommand ("wmctrl -i -r $window -e 0,$coords");
	}
	RunCommand ("wmctrl -i -r $window -b remove,shaded");
	RunCommand ("wmctrl -i -r $window -b remove,hidden");
	RunCommand ("wmctrl -i -a $window");
	$name = MakeNewName (GetWindowName ($window),$name);
	RunCommand ("wmctrl -i -r $window -T \"$name\"");
}

sub MakeNewName {
	my ($oldname,$newname) = @_;
	if ($oldname =~ /Kodi \d+\s-\s(.+)/) {
		return $newname . " - " . $1;
	}
	return $newname;
}

sub RunCommand {
	my ($c) = @_;
	debug_print ($c . "\n");
	my $output = `$c`;
	debug_print ($output);
	return $output;
}

sub FindKodis {
	my %kodis = ();
	$output = RunCommand ("wmctrl -l");
	my @lines   = split /\n/ => $output;
	for my $line (@lines) {
		#print $line . "\n";
		if ($line =~ /^([x0-9a-f]+).*\sKodi(\s(\d+))?/) { 
			$key = int($3);
			# the possibility exists that Kodis are open that we didn't start, so they have no number
			# they are probably just called 'Kodi', so the $key at this point would be zero
			# we need them to still have a place in the hash, so we need to find a number for them
			# chances are, they will have higher window id's, so they will come after any ones that we've already numbered
			#   - which would be ideal, because then they will be the first to be removed
			# but the possibility also exists that they will end up interleaving in among ours, since the window numbers aren't guaranteed
			if ($key == 0) { $key = 1; }
			while (exists ($kodis{$key})) { $key = $key + 1; }
			$kodis{$key} = $1; 
		}
	}
	return %kodis;
}

sub GetWindowName {
	my ($window) = @_;
	$output = RunCommand ("wmctrl -l");
	my @lines   = split /\n/ => $output;
	for my $line (@lines) {
		if ($line =~ /^$window\s+\d+\s+\S+\s+(.*)/) {
			return $1;
		}
	}
	return "";
}

sub debug_print {
	if ($debug) { print @_; }
}

sub SwapWindows {
	my ($swapA,$swapB) = @_;
	print "Swapping $swapA and $swapB.\n";
	my %kodis = ();
	$output = RunCommand ("wmctrl -l -G");
	my @lines   = split /\n/ => $output;
	my $windowA, $xA, $yA, $wA, $hA;
	my $windowB, $xB, $yB, $wB, $hB;
	my $foundA = 0;
	my $foundB = 0;
	for my $line (@lines) {
		if ($line =~ /^([x0-9a-f]+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+.*Kodi\s(\d+)/) { 
			if ($6 == $swapA) {
				($foundA, $windowA, $xA, $yA, $wA, $hA) = (1, $1, $2, $3, $4, $5);
			}
			if ($6 == $swapB) {
				($foundB, $windowB, $xB, $yB, $wB, $hB) = (1, $1, $2, $3, $4, $5);
			}
		}
	}
	if (!$foundA) { print "Couldn't find window called 'Kodi $swapA'.\n";}
	if (!$foundB) { print "Couldn't find window called 'Kodi $swapB'.\n";}
	if (!$foundA || !$foundB) { exit; }
	
	PositionWindow ("Kodi ".$swapA, $windowB, "norm", $xA, $yA-$titlebar_height, $wA, $hA);
	PositionWindow ("Kodi ".$swapB, $windowA, "norm", $xB, $yB-$titlebar_height, $wB, $hB);
	
	return %kodis;
	
}

sub ReadSettings {
	my $lastcomment;
	my ($filename) = @_;
	open(my $fh, '<:encoding(UTF-8)', $filename)
		or die "Could not open settings file '$filename' $!";
 
	while (my $row = <$fh>) {
		chomp $row;
		if ($row =~ /^\s*#\s*(.*)/) {
			$lastcomment = $1;
		} elsif ($row =~ /^\s*set\s+(\S+)\s+(.*)/) {
			my @arr = split(/\s+/,$2);
			AddSpecial ($1,\@arr,$lastcomment);
			$lastcomment = "";
		} elsif ($row =~ /^\s*(.*?)\s*=\s*(.*?)$/) {
			$settings{$1} = $2;
		}
	}
}

sub AddSpecial {
	my $name = $_[0];
	my @arr = @{$_[1]};
	my $description = $_[2];
	push (@specials_sort,$name);
	$specials {$name} = [@arr];
	$specials_desc {$name} = $description;
}

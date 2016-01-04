
use POSIX;
use Data::Dumper qw(Dumper);

my $debug = 0;

my $num_kodis;
my %kodis;

my $arrangement = "";
my @specs;
my @specials_sort;
my %specials_desc;
my @displays;

my $space_width;
my $space_height;
my $offset_width;
my $offset_height;

my %specials;
my %settings;

ReadSettings ("settings");
ReadSettings ("arrangements");

my $margin_ratio = $settings{"margin_ratio"};
my $window_ratio = $settings{"window_ratio"};
my $titlebar_height = $settings{"titlebar_height"};

my $reserve_top = $settings{"reserve_top"};
my $reserve_bottom = $settings{"reserve_bottom"};
my $reserve_left = $settings{"reserve_left"};
my $reserve_right = $settings{"reserve_right"};

my @arr = (1,2,3,4);
debug_print (Dumper \@arr);

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

my $output = `wmctrl -d`;

if ($output =~ /(\d+)x(\d+).*\s(\d+),(\d+)*\s(\d+)x(\d+).*/) {
	$space_width = $5;
	$space_height = $6;
	$offset_width = $3 + ($reserve_left * $space_width);
	$offset_height = $4 + ($reserve_top * $space_height);
	$space_width = $space_width * (1 - $reserve_left - $reserve_right);
	$space_height = $space_height * (1 - $reserve_top - $reserve_bottom);
	$displays[0] = [($offset_width, $offset_height, $space_width, $space_height)];
} else {
	print "Couldn't interpret output from 'wmctrl -d'.\n";
	print "Most likely, it is not installed, so you might need to do something like:\n";
	print "  sudo apt-get install wmctrl\n";
	exit ();
}

for ($i=0;$i<10;$i++) {
	if (exists $settings{"display ".($i+1)}) {
		if ($settings{"display ".($i+1)} =~ /^([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)$/) {
			$displays[$i] = [($1,$2,$3,$4)];
		} else {
			print "Can't interpret dimensions of display ".($i+1)." in settings file.";
		}
	}
}

debug_print ("Displays:");
debug_print (Dumper \@displays);

my $list_arrs = 0;

$num_args = $#ARGV + 1;
if ($num_args >= 1) {
	$arg = $ARGV[0];
	if ($arg eq "setup") {
		if (($num_args == 2) && ($ARGV[1] =~ /^([+-])(\d+)$/)) {
			# increment or decrement number of kodis with +1, -2, etc
			%kodis = FindKodis();
			$num_kodis = keys %kodis;
			if ($1 eq "+") { $num_kodis = $num_kodis + $2; }
			if ($1 eq "-") { $num_kodis = $num_kodis - $2; }
		} else {
			$num_kodis = 0;
			$display = 0;
			for ($i=1;$i<$num_args;$i++) {
				if (!exists($displays[$display])) {
					print "Display ".($display+1)." not defined in settings file. Extra arrangement ignored.\n";
				} else {
					$arg = $ARGV[$i];
					$arrangement = $arg;
					if ($arrangement =~ /^(\d+)$/) {
						$num_kodis = $num_kodis + $1;
						$specs[$display] = $1;
					} elsif (exists ($specials{$arrangement})) {
						$specs[$display] = [@{$specials{$arrangement}}];
						$num_kodis = $num_kodis + scalar (@{$specials{$arrangement}})-1;
					} else {
						print "No special arrangement called '$arrangement'.\n";
						print "Use argument 'list' to show the arrangements available.\n";
						exit;
					}
					$display = $display + 1;
				}
			}
			debug_print ("num kodis: $num_kodis\n");
			debug_print ("specs:");
			debug_print (Dumper \@specs);
			#exit;
		}
	} elsif ($arg eq "swap") {
		# swap the positions and titles of two windows
		if (($num_args == 3) && ($ARGV[1] =~ /^\d+$/) && ($ARGV[2] =~ /^\d+$/)) {
			SwapWindows ($ARGV[1],$ARGV[2]);
			# Go through and touch each window in order; this is a particular bandaid to address a problem with pip
			#   (or other overlapping configurations) where the swapping causes the z-axis to get mixed up and the
			#   later-numbered windows being under the earlier-number ones (so underneath the full screen one)
			# Note that unlike a regular setup, it doesn't restore the previously-selected window (which is done in
			#   case the user is using a terminal on the window system). It can't, because it can't do the same job
			#   of avoiding restoring a maximized window, because it doesn't know which ones are maximized. It doesn't
			#   have any way to know (that I have been able to find) because it doesn't know the setup.
			# (Which I don't want it to have to know anyway, because then it won't be able to swap windows if users
			#   have self-positioned them, which is a nice feature to have)
			# So the result is... it just leaves the highest-numbered window selected.
			%kodis = FindKodis ();
			foreach my $number (sort keys %kodis) {
				$window = $kodis{$number};
				RunCommand ("wmctrl -i -a ".$window);
			}
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
print ".\n";

	if (0) {
		# Bandaid: if you use wmctrl to take a kodi out of fullscreen, it doesn't rescale the contents
		# But if you send a backslash, so that it brings itself out of fullscreen, it changes the window number
		#   which plays havoc on my code which expects this to be a solid identifier.
		# So here, if any are fullscreen, we just make them not, before rescanning for the window numbers
		# It causes an ugly glitch, but it's better than the bug
		# NOT ACTIVE: destroys the information about what the state of the windows were, which is important for swap
		# This bug was addressed by setting maximized_vert and maximized_horz when using fullscreen (and perhaps the order in which they were set)
		%kodis = FindKodis ();
		foreach my $number (sort keys %kodis) {
			my $window = $kodis{$number};
			debug_print ("Fullscreen check: $window\n");
			if (GetWindowState($window) eq "full") {
				debug_print ("Full screen, sending backslash.\n");
				# I don't know why just a keyup seems to work better than a full keypress or a keydown
				# But the empirical results cannot be denied
				# One factor may be that a keyup/keydown pair sends two operations, and the window number can change in between due to the keystroke's actions
				RunCommand ("xdotool keyup --window $window backslash");
			} else {
				debug_print ("Not full screen.\n");
			}
		}
	}

my $output = `xdotool getwindowfocus`;
my $startingwindow;

if ($output =~ /^(\d+)$/) {
	# Figure out which window is in focus, so we can restore it at the end
	# BUT not if it's a Kodi window; these are focused based on the arrangement, and restoring the original one messes it up
	# This is mainly for if the user is interacting through an onscreen terminal, so it doesn't get covered up by kodis every time
	$startingwindow = sprintf("0x%x",$1);
	debug_print ("Starting window: $startingwindow\n");
	my $output = RunCommand ("wmctrl -l -G");
	my @lines   = split /\n/ => $output;
	my $found = 0;
	for my $line (@lines) {
		if ($line =~ /^([x0-9a-f]+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\S+\s+(.*)$/) { 
			my $name = $6;
			my $window = $1;
			# have to use 'hex' to make it a numerical comparison here
			# because one comes from a string, and the other from the sprintf, so leading zeroes can be different
			if ((hex($window) == hex($startingwindow)) && ($name =~ /Kodi/)) {
				debug_print ("Starting window is a Kodi; won't be restored.\n");
				$startingwindow = "false";
			}
		}
	}
} else {
	print "Couldn't interpret output from 'xdotool getwindowfocus'.\n";
	print "Most likely, xdotool is not installed, so you might need to do something like:\n";
	print "  sudo apt-get install xdotool\n";
	exit ();
}

%kodis = FindKodis ();
$kodisfound = keys %kodis;
print "Found $kodisfound kodi";
if ($kodisfound != 1) { print "s"; }

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
		
		my $pixels=0;		
		my @maxed;

		foreach my $number (sort keys %kodis) {
		
			debug_print ("Kodi number: $number\n");

			my $window = $kodis{$number};
			
			my $display=0;
			my $accum=0;
			while ($accum+GetWindowsInSpec($display) < $number) {
				$accum = $accum + GetWindowsInSpec($display);
				$display = $display + 1;
			}
			# $index is the number of this window within its display
			my $index = $number - $accum;
			
			# $windows_in_display is how many windows there are on the current display
			my $windows_in_display = GetWindowsInSpec($display);
			
			debug_print ("Display: $display\n");
			debug_print ("Index: $index\n");
			debug_print ("Windows in display: $windows_in_display\n");

			my @spec = @{$specs[$display]};
			debug_print ("display spec:");
			debug_print (Dumper \@spec);

			$special = 0;
			if (ref ($specs[$display]) eq "ARRAY") { $special = 1; }
			debug_print ("special: $special\n");
			debug_print ("ref display:".ref($specs[$display])."\n");
			debug_print ("ref spec:".ref($spec)."\n");

			$offset_width = $displays[$display][0];
			$offset_height = $displays[$display][1];
			$space_width = $displays[$display][2];
			$space_height = $displays[$display][3];
			debug_print ("offset width: $offset_width\n");
			debug_print ("offset height: $offset_height\n");
			debug_print ("space width: $space_width\n");
			debug_print ("space height: $space_height\n");
		
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
				my $sq = ceil(sqrt($windows_in_display));
				$cols = $sq;
				$rows = ceil($windows_in_display/$cols);
			}
			
			debug_print ("cols: $cols\n");
			debug_print ("rows: $rows\n");
			
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
				debug_print ("xmargin: $xmargin\n");
				debug_print ("xstep: $xstep\n");
				debug_print ("xorigin: $xorigin\n");
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
				
			my $type,$cell_row,$cell_col,$cell_width,$cell_height;

			if ($special) {
				debug_print ("window spec: ".$spec[$index]."\n");
				if ($spec[$index] =~ /^([0-9.]+),([0-9.]+),([0-9.]+),([0-9.]+)$/) {
					$type = "Norm";
					$cell_col = $1;
					$cell_row = $2;
					$cell_width = $3;
					$cell_height = $4;
				} elsif ((lc($spec[$index]) eq "full") || (lc($spec[$index]) eq "max")) {
					$type = $spec[$index];
					if (lc($spec[$index]) eq "max") {
						push (@maxed,$window);
					}
				} else {
					print "Couldn't interpret window dimensions: ".$spec[$index]."\n";
					exit;
				}
			} else {
				$type = "Norm";
				$cell_col = ($index - 1) % $cols;
				$cell_row = int (($index - 1) / $cols);
				$cell_width = 1;
				$cell_height = 1;
			}

			my $avail_width = ($xstep * $cell_width) - $xmargin;
			my $avail_height = ($ystep * $cell_height) - $ymargin - $titlebar_height;
			
			my $x = $xorigin + $xstep * $cell_col;
			my $y = $yorigin + $ystep * $cell_row;
			my $w = $avail_width;
			my $h = $avail_height;
	
			if ($type ne "Norm") {
				$x = $offset_width;
				$y = $offset_height;
				$w = $space_width;
				$h = $space_height;
			}
		
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

				if (!$special && ($cell_row == $rows-1)) {
					if ($windows_in_display % $cols != 0) {
						$x = $x + $xstep*($cols-($windows_in_display%$cols))/2;
					}
				}
			}

			PositionWindow ("Kodi ".($number),$window,$type,$x,$y,$w,$h);
			$pixels = $pixels + ($w * $h);
					
		}
		
		# set focus to where it was before we started, unless said window is maximized
		# in which case, we want it to stay on the bottom, where it already is
		my $ismax = 0;
		foreach my $m (@maxed) {
			if ($startingwindow eq hex($m)) { $ismax = 1; }
		}
		if ((!$ismax) && ($startingwindow ne "false")) {
			debug_print ("Touching starting window $startingwindow\n");
			RunCommand ("wmctrl -i -a ".$startingwindow);
		}
			
		$efficiency = $pixels / ($space_width * $space_height);

	}
}

sub GetWindowsInSpec {
	my ($spec) = @_;
	if (ref ($specs[$spec]) eq "ARRAY") { return (scalar(@{$specs[$spec]})-1); }
	else { return $specs[$spec]; }
}

sub PositionWindow {
	my ($name,$window, $type, $x, $y, $width, $height) = @_;
	my $coords = int($x).",".int($y).",".int($width).",".int($height);
	debug_print ("Positioning $window\n");
	if (lc($type) eq "full") {
		RunCommand ("wmctrl -i -r $window -b add,maximized_vert");
		RunCommand ("wmctrl -i -r $window -b add,maximized_horz");	
		RunCommand ("wmctrl -i -r $window -e 0,$coords");
		RunCommand ("wmctrl -i -r $window -b add,fullscreen");
		# invalidate the starting window, so it won't attempt to restore it later
		# and mess up our full screening
		$startingwindow = "false";
	} elsif (lc($type) eq "max") {
		RunCommand ("wmctrl -i -r $window -b add,maximized_vert");
		RunCommand ("wmctrl -i -r $window -b add,maximized_horz");
		RunCommand ("wmctrl -i -r $window -b remove,fullscreen");
		RunCommand ("wmctrl -i -r $window -e 0,$coords");
	} elsif (lc($type) eq "norm") {
		if (0) {
			# NOT ACTIVE, caused big errors because the window numbers change when you backslash
			# Kodi seems to have a bug wherein if we just remove the fullscreen attribute using wmctrl
			#  it doesn't rescale itself properly. So here is a workaround, if it needs to be de-fullscreened
			#  we let Kodi do it; it seems to prefer it that way.
			# This bug was addressed by setting maximized_vert and maximized_horz when using fullscreen (and perhaps the order in which they were set)
			if (GetWindowState($window) eq "full") {
				debug_print ("Window $window is fullscreen, sending backslash.\n");
				RunCommand ("xdotool keydown --window $window backslash");
				# For some reason when we do that, it changes to a new window number, so now we have to find that...
				sleep (5);
				my $output = RunCommand ("wmctrl -l -G");
				my @lines   = split /\n/ => $output;
				my $found = 0;
				for my $line (@lines) {
					if ($line =~ /^([x0-9a-f]+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\S+\s+(.*)$/) { 
						if (($6 eq $name) || ($6 eq "Kodi")) {
							debug_print ("Found it: $1\n");
							$window = $1;
							$found = 1;
						}
					}
				}
				if (!$found) {
					print "Couldn't relocate window '$name' after backslash operation.\n";
					exit;
				}
			}
		}
		RunCommand ("wmctrl -i -r $window -b remove,fullscreen");
		RunCommand ("wmctrl -i -r $window -e 0,$coords");
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

sub SendKey {
	($window,$send) = @_;
	RunCommand ("xdotool key --window $window $send");
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

sub FindUnnumberedKodi {
	debug_print ("Find unnumbered kodi.\n");
	my $output = RunCommand ("wmctrl -l -G");
	my @lines   = split /\n/ => $output;
	for my $line (@lines) {
		if ($line =~ /^([x0-9a-f]+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+.*Kodi$/) { 
			debug_print ("Found it: $1\n");
			return $1;
		}
	}
	debug_print ("Didn't find it.\n");
	return 0;
}

sub SwapWindows {
	my ($swapA,$swapB) = @_;
	print "Swapping $swapA and $swapB.\n";
	my %kodis = ();
	my $output = RunCommand ("wmctrl -l -G");
	my @lines   = split /\n/ => $output;
	my $windowA, $xA, $yA, $wA, $hA;
	my $windowB, $xB, $yB, $wB, $hB;
	my $windowZ, $xZ, $yZ, $wZ, $hZ;
	my $foundA = 0;
	my $foundB = 0;
	my $foundZ = 0;
	for my $line (@lines) {
		if ($line =~ /^([x0-9a-f]+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+.*Kodi\s(\d+)/) { 
			if ($6 == $swapA) {
				($foundA, $windowA, $xA, $yA, $wA, $hA) = (1, $1, $2, $3, $4, $5);
			}
			if ($6 == $swapB) {
				($foundB, $windowB, $xB, $yB, $wB, $hB) = (1, $1, $2, $3, $4, $5);
			}
		}
		# workaround: when you full-size a window, from Kodi itself, it seems to lose its programmed name, reverting to "Kodi"
		# so we look for those, and if we find one, store it away as Z
		if ($line =~ /^([x0-9a-f]+)\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+.*Kodi$/) { 
			($foundZ, $windowZ, $xZ, $yZ, $wZ, $hZ) = (1, $1, $2, $3, $4, $5);		
		}
	}
	
	# workaround: see above
	# if we didn't find one of the windows we were looking for, but we found one with just the name "Kodi", assume that is it
	if ($foundA && !$foundB && $foundZ) { ($foundB, $windowB, $xB, $yB, $wB, $hB) = ($foundZ, $windowZ, $xZ, $yZ, $wZ, $hZ); }
	if (!$foundA && $foundB && $foundZ) { ($foundA, $windowA, $xA, $yA, $wA, $hA) = ($foundZ, $windowZ, $xZ, $yZ, $wZ, $hZ); }
	
	if (!$foundA) { print "Couldn't find window called 'Kodi $swapA'.\n";}
	if (!$foundB) { print "Couldn't find window called 'Kodi $swapB'.\n";}
	if (!$foundA || !$foundB) { exit; }
	
	my $stA = GetWindowState ($windowA);
	my $stB = GetWindowState ($windowB);
	
	PositionWindow ("Kodi ".$swapB, $windowA, $stB, $xB, $yB-$titlebar_height, $wB, $hB);
	PositionWindow ("Kodi ".$swapA, $windowB, $stA, $xA, $yA-$titlebar_height, $wA, $hA);
	
	return %kodis;
	
}

sub GetWindowState {
	my ($windowID) = @_;
	my $output = RunCommand ("xprop -id $windowID _NET_WM_STATE");
	if ($output =~ / _NET_WM_STATE_FULLSCREEN/) { return "full"; }
	if (($output =~ /_NET_WM_STATE_MAXIMIZED_VERT/) && ($output =~ /_NET_WM_STATE_MAXIMIZED_HORZ/)) { return "max"; }
	return "norm";
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
	debug_print ("Settings:\n");
	debug_print (Dumper \%settings);
}

sub AddSpecial {
	my $name = $_[0];
	my @arr = @{$_[1]};
	my $description = $_[2];
	push (@specials_sort,$name);
	$specials {$name} = [@arr];
	$specials_desc {$name} = $description;
}

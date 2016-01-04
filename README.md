# multi-kodis
Command-line tools for managing multiple Kodi windows on an Ubuntu/Linux desktop

### Supports the following features:

1. Automatically arranges Kodi windows on one or multiple monitors, either in a simple grid, or in programmable arrangements.
2. Opens, closes, and resizes Kodi windows as necessary to create the desired arrangement, and move from one arrangement to another.
3. Quickly selects any window for control input.
4. Supports swapping of windows to move content to where you want it.
5. Provides a remote-control tool to send keystrokes to all of them, or whichever ones you want, in bulk.
6. Remote commands can be automated with scripts.

### Provided scripts

All the work is done by a couple of perl programs, but the following shell scripts are used to simplify operation.

1. **setup** - arrange the Kodi windows as specified, or rearrange them, adding or removing kodi windows. Each of them is assigned a number in the title bar, like "Kodi 2".

	Examples:
	
		`setup 6` - set up 6 Kodi windows in a default grid
		`setup 5s` - set up 5 Kodi windows in a predefined arrangement

		`setup 2 5s` - set up 5 Kodi windows on one display, and a 5s arrangement on the other

2. **list** - list the set of programmed window arrangements (specified in settings file)

	No arguments; provides a list of the programmed window arrangements

3. **sel** - select one of your Kodi windows by number, highlighting it for remote control input

	Example:
	
		`sel 3` - select and highlight the window 'Kodi 3'

	(note: this is different from the 'remote' command, which is its own remote control. Use this command when you have your own remote, to select which window it commands)

4. **swap** - swap the contents of two Kodi windows

	Example:
	
		`swap 1 5` - swap the contents of windows 'Kodi 1' and 'Kodi 5'

	(Note: It actually just moves/resizes the windows, and renumbers them, so you can swap even with live content running. If the window contents are the same, nothing will seem to change. Swaps are 'sticky'; you can do more swaps all you want.)

5. **remote** - remote-control all or some of your Kodi windows from the keyboard

	When used with no arguments, controls any or all of your Kodi windows. Use number keys (1-9) to select which windows to control, cursor keys and others to send controls to those windows. Only certain keystrokes are supported, but more could be added.

### Requirements

To run these scripts, you'll need a few tools installed on your Linux box. You can just try running it; it should exit gracefully and tell you if something is not installed.

1. wmctrl

	`sudo apt-get install wmctrl
	
2. xdotool

	`sudo apt-get install xdotool
	
3. perl Term::ReadKey (to use the remote tool)

	`sudo apt-get install libterm-readkey-perl

4. Environment variables

	The $DISPLAY and $XAUTHORITY variables need to be set; if you are opening up a terminal directly on your Ubuntu desktop, they will be set automatically. However, if you are using an ssh terminal to do you work (which I suggest that you do), they need to be explicitly set.
	
	I don't know all the details, but I was able to make it work fine by adding the following to my **.bashrc** file:
	
	`if [ -z "$DISPLAY" ]; then DISPLAY=:0; export DISPLAY; fi
	`if [ -z "$XAUTHORITY" ]; then XAUTHORITY=/home/fritz/.Xauthority; export XAUTHORITY; fi

### Limitations and Caveats



# multi-kodis
Command-line tools for managing multiple Kodi windows on an Ubuntu/Linux desktop

### Supports the following features:

1. Automatically arranges Kodi windows on your desktop, either in a simple grid, or in programmable arrangements.
2. Opens, closes, and resizes Kodi windows as necessary to create the desired arrangement, and move from one arrangement to another.
3. Quickly selects any window for control input.
4. Supports swapping of windows to move content to where you want it.
5. Provides a remote-control tool to control all of them, or whichever ones you want, in bulk.

### Provided scripts

All the work is done by a couple of perl programs, but the following shell scripts are used to simplify operation.

1. **setup** - arrange the Kodi windows as specified, or rearrange them, adding or removing kodi windows. Each of them is assigned a number in the title bar, like "Kodi 2".

	Examples:
	
		`setup 6` - set up 6 Kodi windows in a default grid
		`setup 5s` - set up 5 Kodi windows in a predefined arrangement

2. **list** - list the set of programmed window arrangements (specified in settings file)

	No arguments; provides a list of the programmed window arrangements

3. **sel** - select one of your Kodi windows by number, highlighting it for control input

	Example:
	
		`sel 3` - select and highlight the window 'Kodi 3'

4. **swap** - swap the contents of two Kodi windows

	Example:
	
		`swap 1 5` - swap the contents of windows 'Kodi 1' and 'Kodi 5'

	(Note: It actually just moves/resizes the windows, and renumbers them, so you can swap even with live content running. If the window contents are the same, nothing will seem to change. Swaps are 'sticky'; you can do more swaps all you want.)

5. **remote** - remote-control all or some of your Kodi windows from the keyboard

	No arguments; by default controls all of your Kodi windows. Use number keys (1-9) to select which windows to control, cursor keys and others to send controls to those windows. Further details provided in prompts.

### Requirements

(todo, honest I will... offhand, you'll need wmctrl, xdotool, and perl Term::ReadKey, and you may have to do something about $DISPLAY and $XAUTHORITY environment variables, details forthcoming)

### Limitations and Caveats

(todo... only one desktop supported, only tested in recent ubuntu)


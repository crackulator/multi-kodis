# multi.kodis
Command-line tools for managing multiple Kodi windows on an Ubuntu/Linux desktop

### Supports the following features:

1. Automatically arranges kodi windows on your desktop, either in a simple grid, or in programmable arrangements.
2. Opens, closes, and resizes kodi windows as necessary to create the desired arrangement, and move from one arrangement to another.
3. Quickly selects any window for control input.
4. Supports swapping of windows to move content to where you want it.
5. Provides a remote-control tool to control all of them, or whichever ones you want, in bulk.

### Provided scripts

All the work is done by a couple of perl programs, but the following shell scripts are used to simplify operation.

1. **setup** - arrange the kodi windows as specified, or rearrange them, adding or removing kodi windows

	Examples:
	
		`setup 6` - set up 6 kodi windows in a default grid
		`setup 5s` - set up 5 kodi windows in a predefined arrangement

2. **list** - list the set of programmed window arrangements (specified in settings file)

	No arguments; provides a list of the programmed window arrangements

3. **sel** - select one of your kodi windows by number, highlighting it for control input

	Example:
	
		`sel 3` - select and highlight the window 'Kodi 3'

4. **swap** - swap the positions of two windows

	Example:
	
		`swap 1 5` - swap the positions of 'Kodi 1' and 'Kodi 5'

5. **remote** - remote-control all or some of your kodi windows from the keyboard

	No arguments; by default controls all of your kodi windows. Use number keys (1-9) to select which windows to control, cursor keys and others to send controls to those windows. Further details provided in prompts.

### Requirements

(todo, honest I will... offhand, you'll need wmctrl, xdotool, and perl Term::ReadKey)

### Limitations and Caveats

(todo... only one desktop supported, only tested in recent ubuntu)


# multi-kodis
Command-line tools for managing multiple Kodi windows on an Ubuntu/Linux desktop

### Supports the following features:

1. Automatically arranges Kodi windows on one or multiple monitors, either in a simple grid, or in programmable arrangements.
2. Opens, closes, and resizes Kodi windows as necessary to create the desired arrangement, and move from one arrangement to another.
3. Quickly selects any window for control input.
4. Supports swapping of windows to move content to where you want it.
5. Provides a remote-control tool to send keystrokes to all of them, or whichever ones you want, in bulk.
6. Remote commands can be automated with scripts.

It works best if you terminal in from some other device using ssh or the like; that way your terminal window isn't getting in the way of your Kodis.

### Provided scripts

All the work is done by a couple of perl programs, but the following shell scripts are used to simplify operation.

1. **setup** - arrange the Kodi windows as specified, or rearrange them, adding or removing kodi windows. Each of them is assigned a number in the title bar, like "Kodi 2".

	Examples:
	
		`setup 6` - set up 6 Kodi windows in a default grid
		`setup 5s` - set up 5 Kodi windows in a predefined arrangement

		`setup 2 5s` - set up 5 Kodi windows on display 1, and a 5s arrangement on display 2

	When you use multiple displays, wmctrl views your whole desktop as one rectangle, so you need to define where each of your displays resides within the rectangle. See the settings file, the 'display' keyword, for details.

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
	
	You can also supply an argument, which is a script to be run from the 'keyscripts' folder, to automate multi-kodi operations that you do repeatedly, such as swapping windows along with their audio. See the files in 'keyscripts' for examples. You can send commands to any of your Kodis by number, and also execute shell commands from those scripts to do things like swapping or changing window arrangements.

### Requirements

To run these scripts, you'll need a few tools installed on your Linux box. You can just try running it; it should exit gracefully and tell you if something is not installed. But you will usually need to do the following.

1. wmctrl

	`sudo apt-get install wmctrl`
	
2. xdotool

	`sudo apt-get install xdotool`
	
3. perl Term::ReadKey (to use the remote tool)

	`sudo apt-get install libterm-readkey-perl`

4. Environment variables

	The $DISPLAY and $XAUTHORITY variables need to be set; if you are opening up a terminal directly on your Ubuntu desktop, they will be set automatically. However, if you are using an ssh terminal to do you work (which I suggest that you do), they need to be explicitly set.
	
	I don't know how all this is supposed to work, but I was able to make it work for ssh by adding the following to my **.bashrc** file (note you must fill in your own user name for [user]):
	
	```
	if [ -z "$DISPLAY" ]; then DISPLAY=:0; export DISPLAY; fi
	if [ -z "$XAUTHORITY" ]; then XAUTHORITY=/home/[user]/.Xauthority; export XAUTHORITY; fi
	```

### User-configurable files

1. settings

	This file provides a number of different options for the user. You can try it without editing this file; most of the defaults are good for a single-display system.
	
	Things you can control in this file:
	
	* Amount of space (margins) enforced between your Kodi windows
	* Aspect ratio of newly-created Kodis (usually 16:9)
	* A 'reserve area' to be applied around any or all edges of the screen.
	* Declare the height of the window's title bar in pixels (depends on your interface configuration). This setting doesn't change the height of the title bars; it is an offset that needs to be applied to some of the calculations, so newly-created Kodi windows may have incorrect heights. You may need to do this if you are using non-default gui parameters.
	* The delays between certain actions, such as between opening a Kodi and moving it.
		
	The settings file has documentation for each setting; view it for details.
	
2. arrangements

	This file contains all the preprogrammed window arrangements, expressed in a fairly simple format. Many are provided, but you can also make your own. See file for details.
	
3. keyscripts folder

	In this folder are some scripts to be used with the remote tool, to automate tasks for quick execution. A few examples are provided, but you may want to make your own for your own situations. The remote tool will only look for keyscripts in this folder.
	
	The format of the scripts is pretty simple; usually each line of the file has a number indicating which Kodi to send to, and then a keystroke to send, like:
	
	`1 space` - send a space to Kodi 1
	
	The keystroke names are determined by xdotool, but I have captured the list of valid key names in keyscripts/keyscripts.txt
	
	You can also use the scripts to send shell commands, by starting the line with a greater-than symbol:
	
	`> swap 1 2` - send a shell command to swap Kodi 1 with Kodi 2

### Limitations and Caveats

Synchronization between the video source and the display doesn't always work correctly for multiple windows or multiple displays; it might actually be impossible for it to work correctly in all cases. The result can be a picture that doesn't run as smoothly, or has glitches or horizontal lines.

The math assumes that the aspect ratio of your display (usually 16:9) matches the aspect ratio of the Kodi windows (usually 16:9) when arranging them in a grid. Usually that's fine, but when they don't match, the arrangement may not make the best use of space. I hope to address this and fix the math at some point.


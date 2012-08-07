#! /bin/bash

# TODO
#	- Build a 'base function' "abs" (a.k.a Awesome Bash Scripts) to utilise the extra functions that we'll provide
#	- Provide additional functions as 'stand alone' as possible (and as separate bash files)
#	- Define a set of 'standard' "abs" variables to use to pass data between functions without the need (since we're unable to) to use 'return' value(s)


# ######################### #
# List of propsed functions #
# ######################### #

# General Funcitons:
# ------------------
# 'getoptions'	-- To get both long and short options from a command's arguments string


# Debuging Functions:
# -------------------
# 'log'		-- Log an output, error or variable name/value to a log variable or file


# Functon to get long AND short options from a command arguments string
function getoptions {
	if [ $@ == *"--"* ]; then
		read -a OPTS <<< "$@";
	else
		OPTS="$@";
	fi
	
	OPT_STRING="";
	
	if [ -n $OPTS ]; then
		i=0;
		while $OPTS[$i]; do
			OPT=$OPTS[$i];
			i=$i+1;
			OPTARG=$OPTS[$i];
			
			if [ $OPT == *"--"* ]; then
				OPT=`sed $OPT "//"`;
			fi
			
			i=$i+1;
		done
	fi
}


# Function to prompt the user with a choice of actions
function prompt_action {
	if [ $# -lt 3 ]; then
		cat <<- EOF
			ERROR: The requested function 'prompt_action' has required parameters, $# given in!
			
			Usage: prompt_action -m \"message to prompt user\" -s [subject] -x [actions required]
			
			Actions:
			\ta (abort)		>> Exit the program and returns the user to a command prompt.
			\tb (backup)	>> Make a backup copy of a file (only applies to files). [note: implies overwrite]
			\tc (cancel)	>> Cancel the current action but returns the user to the previous application state.
			\td (delete)	>> Move a file/directory to the waste basket (note: not permitted on system files/folders even when using root/sudo privileges!)
			\te (edit)		>> Open a file in it's default editor.
			\to (open)		>> Open a specified file, directory path or program application.
			\tv	(overwrite)	>> Overwrite a file if it already exists.
			
			Example: prompt_action -m "File Exists! Please select action required:" -x abcv
		EOF
		return 1;
	fi
	
	OPTS=0;
	MSG="";
	SBJ="";
	ACTS="";
	
	if [ -n $ACTS ]; then
		case $ACTS in
			a) # abort
				echo "Abort!";
				exit 0;
			;;
			b) # backup
			;;
			c) # cancel
			;;
			d) # delete
			;;
			e) # edit
			;;
			o) # open
			;;
			v) # overwrite
			;;
			*) # unknown
			;;
		esac
	fi 
}

#! /bin/bash

# apitofme@github >> BASH >> ABS >> xtract -- v0.1-alpha


# show usage function
show_usage() {
	T="$(printf '\t')" # tab spaces for heredoc
	cat <<- EOF
		Usage: xtract -f [file] -d [directory]
		
		Parameters:
		$T-f [file]	>> specifies the archive file to extract
		$T-d [directory]	>> (optional) specified the target or destination directory for output
		
		Note: If -d is omitted the archive file is extracted to the current working path in the terminal
		
		Example: 'extract archive.zip /folder/for/archive'
		Result: 'unzip' command used to extract the contents of the archive in to path: '/folder/for/archive/{archive_contents_here}'
	EOF
}


# define variables
FILE=""
DIR="$PWD"


# xtract_options function
# @desc Detects options and option arguments and stores their values for use in the `xtract` function
xtract_options() {
	PREV="" # create var to store the option switch (allows for options with arguments in FOR loop)
	
	# process user parameters / options
	for OPT in $@
	do
		# catch '--help' long option first
		if [ "$OPT" = "--help" ]
			then OPT="-h"
		fi
		
		# check for an option (i.e. hyphenated) argument
		if [ "$OPT" = "-"* ]
			then PREV="$OPT"
			echo "O: $OPT"; exit 0
		else
			# if option does NOT start with a hyphen treat it as an option argument!
			OPTARG="$OPT"
			OPT="$PREV"
		fi
	
		# match an option to a function / output
		case $OPT in
			# help -- show usage info
			-h)
				show_usage
				exit 0
			;;
			
			# archive file to extract
			-f) FILE="$OPTARG" ;;
			
			# directory path for output
			-d) DIR="$OPTARG" ;;
			
			# catch unknown options
			\?)
				echo "Unknown option: -$OPT"
				echo "Run: 'xtract -h' for help"
			;;
		esac
	done
}


# (e)xtract function
# @desc Test FILE for different archive file extensions and selects appropriate method(s) for archive extraction
xtract() {		
	echo "Extracting file '$FILE'..."
	
	case "$FILE" in
		*.tar.bz2)
			echo "...as a bzip2 compressed TAR archive:"
			tar xvjf "$FILE" -C "$DIR"
		;;
		
		*.tar.gz)
			echo "...as a gzip compressed TAR archive:"
			tar xvzf "$FILE" -C "$DIR"
		;;
		
		*.7z)
			echo "...as a compressed 7zip archive:"
			7z x -so "$FILE" > "$DIR" # uses stdout
		;;
		
		*.bz2)
			echo "...as a compressed bzip2 archive:"
			bzcat "$FILE" > "$DIR" # uses stdout
		;;
		
		*.rar)
			echo "...as a compressed RAR archive:"
			unrar x "$FILE" "$DIR"
		;;
		
		*.gz)
			echo "...as a compressed gzip archive:"
			gunzip -c "$FILE" > "$OD" # uses stdout
		;;
		
		*.tar)
			echo "...as an uncompressed TAR archive:"
			tar xvf "$FILE" -C "$DIR"
		;;
		
		*.tbz2)
			echo "...as a bzip2 compressed TAR archive:"
			tar xvjf "$FILE" -C "$DIR"
		;;
		
		*.tgz)
			echo "...as a gzip compressed TAR archive:"
			tar xvzf "$FILE" -C "$DIR"
		;;
		
		*.zip)
			echo "...as a compressed zip archive:"
			unzip "$FILE" -d "$DIR"
		;;
		
		*.Z)
			echo "...as a compressed archive:"
			uncompress -c "$FILE" > "$DIR" # uses stdout
		;;
		
		*)
			echo "ERROR: '$FILE' is not a recognized archive format!"
			echo "Unable to extract archive file!"
			exit 1
		;;
	esac
}


# check for user parameters
if [ $# = 0 ]
	then echo -e "ERROR: insufficient number of parameters (min. 1 expected)!\nPlease type 'xtract -h' for help"
	exit 1
else
	# loop through the arguments by positional counter
	for (( C=1; C<=$#; C++ ))
	do
		case $C in
			# we'll check each option to see if it's hyphenated or not!
			1) # First / FILE option
				if [ "$1" != "-"* ]
					then FILE="$1" # store the first param in FILE
				else
					xtract_options "$1"
				fi
			;;
			2) # Second / DIR option
				if [ "$2" != "-"* ]
					then DIR="$2" # store the first param in FILE
				else
					xtract_options "$2"
				fi
			;;
			*) # too many options !
				echo "Unknown option paramter(s) present!"
				echo "Ignoring unknown parameters..."
				break
			;;
		esac
	done
fi


# check the file exists and is a standard file
if [ ! -f "$FILE" ]
	then echo "ERROR: '$FILE' does not exist or is not a standard file!"
	exit 1
fi


# check that the output directory...
if [ ! -e "$DIR" ] # ...exists
	
	then echo "Warning: The output directory does not exist!"
	echo "Do you want to create it now? [y / n]"
	read R
	
	if [ "$R" != "y"* ]
		then echo "No -- Aborting file extract!"
		exit 1
	fi
	
	mkdir -pv "$DIR"
	
elif [ ! -d "$DIR" ] # ...is a valid, standard directory
	
	then echo "ERROR: '$DIR' is not a standard directory!"
	exit 1
	
elif [ ! -w "$DIR" ] # ...is available for write access
	
	then echo "ERROR: Unable to write to directory: '$DIR'!"
	echo "Please ensure that output folder is correct and that you have sufficient privileges"
	echo "-- or type 'sudo !!' to re-run script as ROOT (Note: you will need to enter the administrator password!)"
	exit 1
	
fi


# check if the archive directory already exists
FDIR="${FILE%%.*}" # get filename without file extension (greedy match)
if [ -d "$DIR/$FDIR" ]
	then echo "Warning: Archive output path already exists!"
	echo "Overwrite? [ y / n ]"
	read R
	
	if [ $R != "y"* ]
		then echo "Aborted by user"
		exit 0
	fi
fi


# everything's checked out so call the 'xtract' function
xtract

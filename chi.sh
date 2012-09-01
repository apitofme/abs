#!/bin/bash

# apitofme@github >> BASH >> ABS >> chi -- v0.2-alpha


# check that we're runing as root/sudo
if [ $EUID != 0 ]
	then echo -e "This script must be run with (effective) root privileges!\nType 'sudo !!' to run the last script with sudo elevated privileges."
	exit 1;
fi


# show usage
show_usage() {
	T="$(printf '\t')" # tab character for heredoc
	cat <<- EOF
		Usage: 'chi [-R] path {options...}'
		
		Options:
		$T	-R recursion	$T	>> Note: if used this *must* be the first parameter!
		$T	-o username
		$T	-g group
		$T	-m permissions
		
		Example: [sudo] chi -R /var/www -o myusername -g www-data -m 775
	EOF
}


# check for sufficient arguments
if [ $# -lt 2 ]
	then echo "ERROR: insufficient parameters passed (expecting 2)!"
	show_usage
	exit 1
fi


# check for recursion and/or set path
if [ $1 = "-R" ]
	then RECURSIVE=true
	PATH="$2"
else
	RECURSIVE=false
	PATH="$1"
fi


# check path is a valid file or directory
if [ ! -f "$PATH" ] && [ ! -d "$PATH" ]
	then echo "ERROR: '$PATH' -- not found or is not a standard file or directory!"
	exit 1;
fi


# process command parameters
while [ "$1" != "" ]
do
	case $1 in
		-h | --help )
			show_usage
			exit 0
		;;
		-o | --owner ) # uses 'chown ...'
			shift
			OPTARG="$1"
			if [ $RECURSIVE ]
				then /bin/chown -R "$OPTARG" "$PATH"
			else
				/bin/chown "$OPTARG" "$PATH"
			fi
		;;
		-g | --group ) # uses 'chgrp ...'
			shift
			OPTARG="$1"
			if [ $RECURSIVE ]
				then /bin/chgrp -R "$OPTARG" "$PATH"
			else
				/bin/chgrp "$OPTARG" "$PATH"
			fi
		;;
		-m | --mod | --permissions ) # uses 'chmod ...'
			shift
			OPTARG="$1"
			if [ $RECURSIVE ]
				then /bin/chmod -R "$OPTARG" "$PATH"
			else
				/bin/chmod "$OPTARG" "$PATH"
			fi
		;;
		\?) # unknown option
			show_usage
			exit 1
		;;
	esac
	shift
done


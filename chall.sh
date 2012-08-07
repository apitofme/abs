#! /bin/bash

# Awesome Bash Scripts
# ====================

# chall -- chown, chgrp and chmod all rolled in to one!
# @desc This script allows a user to easily specify a complete change of permissions for a file or directory
#+ (i.e. Owner, Group and Access Permissions). This makes it easy to perform bulk operations,
#+ as are frequently required when working with web directories (/var/www/...), allowing for quick configuration of
#+ a standard set of permissions.

# show usage
show_usage() {
	T="$(printf '\t')"
	cat <<- EOF
		Usage: 'chall [-R] path {options...}'
		
		Options:
			$T-R recursion	$T>> Note: if used this *must* be the first parameter!
			$T-o username
			$T-g group
			$T-m permissions
		
		Example: (sudo) chall -R /var/www -o myusername -g www-data -m 775
	EOF
}

# check that we're run as root/sudo
if [ $EUID != 0 ]
	then echo -e "This script must be run with (effective) root privileges!\nType 'sudo !!' to run the last script with sudo elevated privileges."
	exit 1;
fi

# check for sufficient arguments
if [ $# -lt 2 ]
	then show_usage
	exit 1
fi

# check for recursion and/or set path
if [ $1 = "-R" ]
	then RECURSIVE=true
	PATH="$2"
else
	PATH="$1"
	RECURSIVE=false
fi

# check path is a valid file or directory
if [ ! -f "$PATH" ] && [ ! -d "$PATH" ]
	then echo "ERROR: Selected path not found or is not a valid file or directory!"
	exit 1;
fi

# process command parameters
while getopts ":o:g:m:" OPT
do
	case $OPT in
		o) # Owner -- 'chown ...'
			if [ $RECURSIVE ]
				then `chown -R "$OPTARG" "$PATH"`
			else
				`chown "$OPTARG" "$PATH"`
			fi
		;;
		g) # Group -- 'chgrp ...'
			if [ $RECURSIVE ]
				then `chgrp -R "$OPTARG" "$PATH"`
			else
				`chgrp "$OPTARG" "$PATH"`
			fi
		;;
		m) # Mod -- 'chmod ...'
			if [ $RECURSIVE ]
				then `chmod -R "$OPTARG" "$PATH"`
			else
				`chmod "$OPTARG" "$PATH"`
			fi
		;;
		\?) # unknown
			show_usage
			exit 1
		;;
	esac
done

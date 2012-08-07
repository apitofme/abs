#! /bin/bash

# This is a simple script function to extract various different archive formats.
# - option to a specify a custom output directory (defaults to current working directory)
# - optionally create the output directory if it does not already exist

extract() {
	if [ -f "$F" ]; then
		
		# check that the output directory exists (and is a directory)
		if [ ! -d "$D" ]; then
			echo "The output directory does not exist!";
			echo "Do you want to create it? [y / n]";
			read RSP;
			
			if [[ $RSP == "y"* ]]; then
				echo "Creating directory for archive: '$D'";
				mkdir -p "$D";
			else
				echo "Abort";
				exit 1;
			fi
		fi
		
		# check that the output directory is writable
		if [ -w $D ]; then
			
			echo "Extracting file '$F'...";
			
			case $F in
				*.tar.bz2)
					echo "...as a bzip2 compressed TAR archive:";
					tar xvjf $F -C $D;
				;;
				
				*.tar.gz)
					echo "...as a gzip compressed TAR archive:";
					tar xvzf $F -C $D;
				;;
				
				*.7z)
					echo "...as a compressed 7zip archive:";
					7z x -so $F > $D; # uses stdout
				;;
				
				*.bz2)
					echo "...as a compressed bzip2 archive:";
					bzcat $F > $D; # uses stdout
				;;
				
				*.rar)
					echo "...as a compressed RAR archive:";
					unrar x $F $D;
				;;
				
				*.gz)
					echo "...as a compressed gzip archive:";
					gunzip -c "$F" > "$OD"; # uses stdout
				;;
				
				*.tar)
					echo "...as an uncompressed TAR archive:";
					tar xvf $F -C $D;
				;;
				
				*.tbz2)
					echo "...as a bzip2 compressed TAR archive:";
					tar xvjf $F -C $D;
				;;
				
				*.tgz)
					echo "...as a gzip compressed TAR archive:";
					tar xvzf $F -C $D;
				;;
				
				*.zip)
					echo "...as a compressed zip archive:";
					unzip $F -d $D;
				;;
				
				*.Z)
					echo "...as a deflate compressed archive:";
					uncompress -c $F > $D; # uses stdout
				;;
				
				*)
					echo "File '$F' is an unrecognized archive format!";
					echo "Unable to extract archive file!";
					exit 1;
				;;
			esac
			
		else
			echo "You do not have sufficient privileges to write to the selected output directory '$D'!";
			echo "Try running the script again using 'sudo' (i.e. sudo extract ...)";
			echo " - you will need to enter the administrator password!";
			exit 1;
		fi
				 
  else
      echo "'$F' is not a valid file!"
  fi
}


# Show usage (a.k.a help function)
usage() {
	echo "Extracts various archive formats";
	echo " - option to a specify a custom output directory (defaults to current working directory)";
	echo " - optionally create the output directory if it does not already exist";
	echo "Example: 'extract archive.zip /folder/for/archive'";
	echo " - would use the unzip command to extract the contents of the archive in to '/folder/for/archive/{archive_content_here}'";
	exit 0;
}


# process user input
if [ $# -gt 0 ]; then
	
	case $1 in
		-h)	usage ;;
		--help) usage ;;
		*)
			F=$1; # archive file to extract
			D=pwd; # directory path for output (default is current working directory)
			
			# allow the user to specify a custom output directory
			if [ $# -gt 1 ]; then
				D=$2;
			fi
			
			extract; # call the extract function
		;;
	esac
	
fi

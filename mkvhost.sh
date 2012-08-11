#! /bin/bash

# apitofme@github >> BASH >> ABS >> mkvhost -- v0.1-alpha


# Define variables
CONF_DIR="/etc/apache2/sites-available";
LOG_DIR="/var/log/apache2"
WEB_ROOT="/var/www";
VHOST_PREFIX="local";
VHOST_PORT="80";
VHOST_NAME="`basename $PWD`";
VHOST_PATH="$PWD";
VHOST_LOGLEVEL="warn";
TEMPLATE_FILE=0;

# Help function to show usage
function show_usage {
	cat <<- EOF
			Usage: mkvhost [options]
			
			Description:
				This script allows the automated creation of vhost configs for Apache Web Server under Ubuntu/Debian based linux.
				It will also create log files for the vhost in Apache's log directory as well as adding an entry to the system's "hosts" file.
			
			Short Options:
				-w WEB_ROOT			>> Allows the user to set the base 'web root' path for the VHost [Default: '/var/www']
				-p VHOST_PREFIX		>> Used to set the domain prefix for the VHost [Default: 'local']
				-r VHOST_PORT		>> Used to set the port to use for the VHost [Default: '80']
				-n VHOST_NAME		>> The domain name for the VHost server [Required!]
				-d VHOST_PATH		>> The filesystem path for the VHost relative to the WEB_ROOT [Default: current directory]
				-l VHOST_LOGLEVEL	>> Set Apache's loglevel output for vhost [Default: 'warn']
				-t TEMPLATE_FILE	>> Allows the user to specify a custom template file to use for the VHOST config
				
				Example: mkvhost -p my -n example -t /path/to/vhost-template-file
				Results:
					- file 'my.example.conf' created in '/etc/apache2/sites-available' (from template file provided by user)
					- directory 'example' created in '/var/log/apache2'
					- files 'error.log' and 'access.log' created in '/var/log/apache2/example/'
					- VHost entry added to '/etc/hosts' as '127.0.0.1  my.example  # example'
			
			Long Options:
				--add-host [args]	>> This allows a user to call the 'add_host' function directly, thus enabling them to add just the entry to
									   the '/etc/hosts' file (Requires ROOT privileges!).
					
					- [args] allows for two parameters to be passed to the function: [HOST_NAME] and [HOST_IP] (both optional)
						
						>> [HOST_NAME] is the FULL domain name for the VHost (e.g. 'my.example')
						   If omitted the value defaults to the current working directory's title and the [HOST_IP] **must** also be omitted!
						
						>> [HOST_IP] is the IP address for the VHost, default value is '127.0.0.1'
						
				Example: [sudo] mkvhost --add-host my.host 192.168.1.2
				Results: A line reading '192.168.1.2  my.host  # host' is appended to '/etc/hosts'
	EOF
}


# Available short options
# =======================
# -h				>> display usage information
# -w WEB_ROOT		>> over-rides the default path ['/var/www']
# -p VHOST_PREFIX	>> e.g. 'my' for my.vhost [default is 'local']
# -r VHOST_PORT		>> port to use for vhost [default is '80']
# -n VHOST_NAME		>> name for the virtual host server
# -d VHOST_PATH		>> vhost filesystem path relative to the WEB_ROOT
# -l VHOST_LOGLEVEL	>> apache loglevel for vhost [default is 'warn']
# -t TEMPLATE_FILE	>> user defined template file for VHOST config

# Process short options
while getopts ":h w: p: r: n: d: l: t:" OPT; do
	case $OPT in
		h) show_usage; exit 0 ;;
		w) WEB_ROOT=$OPTARG ;;
		p) VHOST_PREFIX=$OPTARG ;;
		r) VHOST_PORT=$OPTARG ;;
		n) VHOST_NAME=$OPTARG ;;
		d) VHOST_PATH=$OPTARG ;;
		l) VHOST_LOGLEVEL=$OPTARG ;;
		t) TEMPLATE_FILE=$OPTARG ;;
		\?)
			echo "Invalid option: -$OPTARG";
			show_usage;
			exit 1;
		;;
	esac
done

# Available long options
# ======================
# --add-host [HOST_NAME] [HOST_IP]	>> Adds an entry to the hosts file (MUST HAVE ROOT PRIVILEGES!)
# 									 - The parameters are optional:
# 									 -- HOST_NAME defaults to 'local.{CURRENT_FOLDER_NAME}'
# 									 -- HOST_IP defaults to '127.0.0.1'
# 
# TODO add --help	>> show usage and support sub-function helps (e.g. 'mkvhost --add-hosts --help')

# TODO Process long options




# Function to create the VHOST config file
function make_vhost {
	T="$(printf '\t')"
	cat <<- EOF
			# Apache VHOST config file for $VHOST_NAME
			<VirtualHost $VHOST_PREFIX.$VHOST_NAME:$VHOST_PORT>
			$T	NameVirtualHost $VHOST_PREFIX.$VHOST_NAME:$VHOST_PORT
			$T	ServerAlias *.$VHOST_PREFIX.$VHOST_NAME
			#$T	ServerAdmin username@domain
			$T	
			$T	DocumentRoot $VHOST_PATH
			$T	
			$T	<Directory $VHOST_PATH/>
			$T$T		Options -Indexes +FollowSymLinks
			$T$T		AllowOverride All
			$T$T		Order deny,allow
			$T$T		Deny from all
			$T$T		Allow from 127.0.0.1
			$T	</Directory>
			$T
			$T	# Define custom log level
			$T	LogLevel $VHOST_LOGLEVEL
			$T	
			$T	# Set up custom log files
			$T	ErrorLog $LOG_DIR/$VHOST_NAME/error.log
			$T	CustomLog $LOG_DIR/$VHOST_NAME/access.log combined
			</VirtualHost>
	EOF
}

# Function to create the VHOST's log files
function make_logs {
	# check if log files already exist
	if [ -d "$LOG_DIR/$VHOST_NAME" ] && [ -f "$LOG_DIR/$VHOST_NAME/error.log" ] && [ -f "$LOG_DIR/$VHOST_NAME/access.log" ]
		then echo "Log files already exist >> skipping log file creation!"
	else
		echo "Creating log files for $VHOST_NAME"
		mkdir -v "$LOG_DIR/$VHOST_NAME"
		touch "$LOG_DIR/$VHOST_NAME/error.log"
		touch "$LOG_DIR/$VHOST_NAME/access.log"
	fi
}


# Function to add entry to hosts file
function add_host {
	# Make sure the user has root privileges
	if [ $EUID != 0 ]
		then echo -e "ERROR: You need ROOT privileges to edit the hosts file!\n"
		cat <<- EOF
			Re-run 'mkvhost' as ROOT and use the '--add-hosts' switch...
			
			Example: [sudo] 'mkvhost --add-host my.vhost'
			
			This allows you to add the 'hosts' file entry without having to create the Apache VHOST config and associated log files!
			(This can also be used to add 'hosts' entries for other existing VHOST configs)
			
			Note:
			It is possible to omit the vhost name: e.g. 'mkvhost --add-host'
			In which case the basename of the current working directory is used and is given the default vhost prefix of 'local.'
			(i.e. If the working directory was '/var/www/wordpress' this would give you the vhost name 'local.wordpress')
		EOF
		exit 1;
	fi
	
	# Set default vhost values
	HOST_IP="127.0.0.1"
	if [ -n $VHOST_NAME ]
		then HOST_NAME="$VHOST_PREFIX.$VHOST_NAME"
	else
		HOST_NAME="$VHOST_PREFIX.`basename $PWD`" # uses current working directory's title
	fi
	
	# allow user to override default values
	if [ $# -gt 0 ]; then HOST_NAME="$1"; fi
	if [ $# -gt 1 ]; then HOST_IP="$2"; fi
	
	# add entry to the hosts file
	echo -e "$HOST_IP\t$HOST_NAME" >> /etc/hosts;
}


# Check if a config file already exists
if [ -f "$CONF_DIR/$VHOST_NAME" ]
	then echo "The VHost config file '$CONF_DIR/$VHOST_NAME' already exists!"
	echo "Please select action: v (overwrite) | b (backup then overwrite) | c (cancel)"
	read A
	case $A in
		c) # cancel (i.e. just quit!)
			echo "Cancelled by user"
			exit 0
		;;
		b) # backup
			cp "$CONF_DIR/$VHOST_NAME" "$CONF_DIR/$VHOST_NAME.bak"
			echo "Bakup file created: $CONF_DIR/$VHOST_NAME.bak"
		;;
		v) # overwrite
			echo "File will be overwritten!"
		;;
		*) # unknown
			echo "ERROR: Unknown option '$A'!"
			echo "Proceeding with safe option..."
			cp "$CONF_DIR/$VHOST_NAME" "$CONF_DIR/$VHOST_NAME.bak"
			echo "Bakup file created!"
		;;
	esac
fi


# Check if user has supplied a vhost template file
if [ -f "$TEMPLATE_FILE" ]
	# TODO figure out how to parse the values in to template file's placholder variables
	then cat "$TEMPLATE_FILE" > "$CONF_DIR/$VHOST_NAME"
else
	make_vhost > "$CONF_DIR/$VHOST_NAME"
fi

make_logs
add_host "$VHOST_PREFIX.$VHOST_NAME"

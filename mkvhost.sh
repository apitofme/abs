#! /bin/bash

# Define variables
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available";
WEB_ROOT="/var/www";
VHOST_PREFIX="local";
VHOST_PORT="80";
VHOST_NAME="";
VHOST_PATH="";
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

# Function to create the VHOST config file
function make_vhost {
	cat <<- EOF
			# Virtual host config for $VHOST_NAME
			<VirtualHost $VHOST_PREFIX.$VHOST_NAME:$VHOST_PORT>
				NameVirtualHost $VHOST_PREFIX.$VHOST_NAME:$VHOST_PORT
				ServerAlias *.$VHOST_PREFIX.$VHOST_NAME
			#	ServerAdmin username@domain
		
				DocumentRoot $WEB_ROOT/$VHOST_PATH
		
				<Directory $WEB_ROOT/$VHOST_PATH/>
					Options -Indexes +FollowSymLinks
					AllowOverride All
					Order deny,allow
					Deny from all
					Allow from 127.0.0.1
				</Directory>
		
				# Define custom log level
				LogLevel $VHOST_LOGLEVEL
		
				# Set up custom log files
				ErrorLog $APACHE_LOG_DIR/$VHOST_NAME/error.log
				CustomLog $APACHE_LOG_DIR/$VHOST_NAME/access.log combined
			</VirtualHost>
	EOF
}

# Function to create the VHOST's log files
function make_logs {
	echo "Creating log files for vhost: $VHOST_NAME";
	mkdir -pv ${APACHE_LOG_DIR}/$VHOST_NAME;
	echo "Log directory created: ${APACHE_LOG_DIR}/$VHOST_NAME";
	touch ${APACHE_LOG_DIR}/$VHOST_NAME/error.log
	echo "Error log file created: ${APACHE_LOG_DIR}/$VHOST_NAME/error.log";
	touch ${APACHE_LOG_DIR}/$VHOST_NAME/access.log
	echo "Access log file created: ${APACHE_LOG_DIR}/$VHOST_NAME/access.log";
}


# Function to add entry to hosts file
function add_host {
	# Make sure the user has root privileges
	if [ $UID != 0 ]; then
		echo "ERROR: You must have Root privileges to edit the hosts file!";
		echo "You can re-run just this part of the setup by using the switch '--add-host' together with the vhost name";
		echo "e.g. (root/sudo) 'mkvhost --add-host my.vhost'";
		echo "Please note that if you omit the host name then the current working directory's title is used with the default prefix 'local'";
		exit 1;
	fi
	
	# Set default vhost values
	HOST_IP="127.0.0.1";
#	HOST_NAME="local.`basename $PWD`"; # uses current working directory's title
	
	if [ $# -gt 0 ]; then HOST_NAME="$1"; fi;
	if [ $# -gt 1 ]; then HOST_IP="$2"; fi;
	
	echo -e "\n$HOST_IP\t$HOST_NAME\t# $HOST_NAME" >> /etc/hosts;
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

# Process long options

# Check if a config file already exists
if [ -f "$APACHE_SITES_AVAILABLE/$VHOST_NAME" ]; then
	echo "The VHost config file '$APACHE_SITES_AVAILABLE/$VHOST_NAME' already exists!";
	read -p "Please select action: v (overwrite existing file) | b (backup existing file and write new config) | c (cancel)" A;
	case $A in
		c) # cancel (i.e. just quit!)
			echo "operation cancelled";
			exit 0;
		;;
		b) # backup
			cp "$APACHE_SITES_AVAILABLE/$VHOST_NAME" "$APACHE_SITES_AVAILABLE/$VHOST_NAME.bak"
			break
		;;
		v) # overwrite
			break
		;;
		\?) # unknown
			echo "Unknown option '$A'"
	esac
fi

# Check if user has supplied a vhost template file
if [ $TEMPLATE_FILE = 0 ]; then
	make_vhost;
# Check if user template is a valid file
elif [ -f "$TEMPLATE_FILE" ]; then
	# TODO parse variables in to template file's placholders
	cat "$TEMPLATE_FILE";
fi

make_logs;
add_host;

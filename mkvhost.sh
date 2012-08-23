#! /bin/bash

# apitofme@github >> BASH >> ABS >> mkvhost -- v0.2-alpha

# =================
# Define Variables
# =================
# Apache's vhost conf path:
CONF_DIR="/etc/apache2/sites-available"

# Apache's log directory:
LOG_DIR="/var/log/apache2"

# Vhost settings:
VHOST_PREFIX="local"
VHOST_PORT="80"

# -- Note: --
# 'PWD' (i.e. ' Print Working Directory') returns the currently active path from the host terminal
# Also BASH contains some built in string processing features which are useful for working on paths without
# having to resort to calling an external function such as 'dirname' or 'basename'.

# So '${PWD##*}' will return the trailing folder name from the PWD path (e.g. /path/to/my/vhost ==> "vhost")
VHOST_NAME="${PWD##*}"

# Whereas ${PWD%/*} returns the path up to, but not including, the trailing folder name (e.g. /path/to/my/vhost ==> "/path/to/my")
VHOST_PATH="${PWD%/*}"

# Value for Apache's log level
VHOST_LOGLEVEL="warn"

# Variable to store a reference for a user specified vhost.conf template file
# -- this **must** be formatted in a specific way to allow for variable substitution when parsing the file
# -- (please see the 'vhost_example_template.tpl' file as a guide)
TEMPLATE_FILE=0


# =================
# Define Functions
# =================
# Basic 'show usage' help function
show_usage() {
	T="$(printf '\t')"
	cat <<- EOF
		Usage: mkvhost {options...}
		
		Description:
			This script allows the automated creation of vhost configs for Apache Web Server under Ubuntu/Debian based linux.
			It will also create the necessary log files in Apache's log directory and add an entry to the system's "hosts" file.
		
		Options:
		$T-h | --help		>> Displays this message
		$T--more		>> Display more help/usage information for additional options
		$T-p | --prefix		>> Set the domain prefix for the VHost [Default: 'local'] (e.g. 'local.vhost')
		$T-r | --port		>> Used to set the port to use for the VHost [Default: '80']
		$T-d | --dir		>> The absolute filesystem path for the VHost [Default: current working directory]
		$T-n | --name		>> The domain name for the VHost server [Default: current folder's name]
		$T-l | --log-level		>> Specify Apache's log-level output for the vhost [Default: 'warn']
		$T-t | --template		>> Use a custom template file for the VHOST config
		
		Example:$T mkvhost -p my -n example -t /path/to/vhost-template-file
		Results:
		$T- file 'my.example.conf' created in '/etc/apache2/sites-available' using the template file given
		$T- log directory 'example' created in '/var/log/apache2'
		$T- files 'error.log' and 'access.log' created in '/var/log/apache2/example/'
		$T- VHost entry added to '/etc/hosts' as '127.0.0.1  my.example  # example'
		
		Use '--more' for additional information and options!
	EOF
}


# Additional help/information
show_more() {
	T="$(printf '\t')"
	cat <<- EOF
		Additional Information:
			Users may call any of the component functions independently, allowing them to perform only those operations which they require.
		
		Additional Options:
		--add-host [args]
		$T$T- [args] allows for two possible parameters to be passed to the function: [HOST_NAME] and [HOST_IP] (both optional)
		$T$T$T	>> [HOST_NAME] is the **FULL** domain name for the VHost (e.g. 'my.example')
		$T$T$T	-- If omitted the value defaults to the current working directory's title and the [HOST_IP] **must** also be omitted!
		$T$T$T	>> [HOST_IP] is the IP address for the VHost, default value is '127.0.0.1'
		
		Example: [sudo] mkvhost --add-host my.host 192.168.1.2
		Result: A line is appended to the system's "hosts" file, that reads: " 192.168.1.2  my.host  # host-name "
	EOF
}


# Add an entry to hosts file
add_host() {
	# check that the user has the required privileges (i.e. sudo/root), if not...
	if [ $EUID != 0 ]
		# echo an error message
		then echo -e "ERROR: You need ROOT privileges to edit the hosts file!\n"
		
		# print a helpful heredoc
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
		
		# then just quit!
		exit 1
	fi
	
# ... Otherwise...
	
	# set the vhost IP to a default value
	HOST_IP="127.0.0.1"
	
	# check if we have a vhost name
	if [ -n $VHOST_NAME ]
		then HOST_NAME="$VHOST_PREFIX.$VHOST_NAME"
	else
		# if not we'll set it to the current working director's title
		HOST_NAME="$VHOST_PREFIX." + "${PWD##*}"
	fi
	
	# allow parameter options to over-ride the default values
	if [ $# -gt 0 ]; then HOST_NAME="$1"; fi
	if [ $# -gt 1 ]; then HOST_IP="$2"; fi
	
	echo "Appending vhost entry to hosts file..."
	
	# add entry to the hosts file
	echo -e "$HOST_IP\t$HOST_NAME" >> /etc/hosts
	
	echo "...Done!"
}


# Create the VHOST's log files
make_logs() {
	# check for user parameters
	while [ $1 != "" ]
	do
		case $1 in
			-l | --log-dir )
				LOG_DIR="$1"
			;;
			-n | --vhost-name )
				VHOST_NAME="$1"
			;;
		esac
		
		shift # offest the parameter option index
	done
	
	# check for vhost log directory
	if [ ! -d "$LOG_DIR/$VHOST_NAME" ]
		then echo "Creating log files for $VHOST_NAME..."
		mkdir -v "$LOG_DIR/$VHOST_NAME"
		touch "$LOG_DIR/$VHOST_NAME/error.log"
		touch "$LOG_DIR/$VHOST_NAME/access.log"
	else
		echo "Log directory for '$VHOST_NAME' already exists...skipping"
		
		# check for error log file
		if [ ! -f "$LOG_DIR/$VHOST_NAME/error.log" ]
			then echo "Creating 'error.log'..."
			touch "$LOG_DIR/$VHOST_NAME/error.log"
		else
			echo "'error.log' already exist...skipping"
		fi
		
		# check for access log file
		if [ ! -f "$LOG_DIR/$VHOST_NAME/access.log" ]
			then echo "Creating 'access.log'..."
			touch "$LOG_DIR/$VHOST_NAME/access.log"
		else
			echo "'access.log' already exist...skipping"
		fi
	fi
	
	echo "...Done!"
}


# Create the VHOST config file (using 'heredoc' method)
make_vhost() {
	T="$(printf '\t')"
	cat <<- EOF
		# Apache VHOST config file for ${VHOST_NAME^}
		<VirtualHost $VHOST_PREFIX.$VHOST_NAME:$VHOST_PORT>
		$T	NameVirtualHost $VHOST_PREFIX.$VHOST_NAME:$VHOST_PORT
		$T	ServerAlias *.$VHOST_PREFIX.$VHOST_NAME
		#$T	ServerAdmin username@domain
		$T
		$T	DocumentRoot $VHOST_PATH
		$T
		$T	<Directory $VHOST_PATH/>
		$T$T	Options FollowSymLinks
		$T$T	AllowOverride All
		$T$T	Order deny,allow
		$T$T	Deny from all
		$T$T	Allow from 127.0.0.1
		$T	</Directory>
		$T
		$T	# Define custom log level
		$T	LogLevel $VHOST_LOGLEVEL
		$T
		$T	# Set up custom log files
		$T	ErrorLog \${APACHE_LOG_DIR}/$VHOST_NAME/error.log
		$T	CustomLog \${APACHE_LOG_DIR}/$VHOST_NAME/access.log combined
		</VirtualHost>
	EOF
}


# Available config options
# =========================
# -h | --help			> display usage information
# --more				> display usage info for additional options
# --add-host {args}		> call the 'add_host' function independently (with optional parameters passed in {args})
# --make-logs {args}	> call the 'make_logs' function independently (again parameters can be passed to over-ride 'defaults')
# --make-vhost			> call the 'make_vhost' function independently
# -p | --prefix			> e.g. 'my' for my.vhost [default is 'local']
# -r | --port			> port to use for vhost [default is '80']
# -d | --dir			> vhost's absolute filesystem path
# -n | --name			> name for the virtual host server
# -l | --log-level		> apache log-level for vhost [default is 'warn']
# -t | --template		> user defined template file for VHOST config

# Process options
while [ "$1" != "" ]
do
	# get the first paramter and store it's value as the first option
	OPT="$1"
	
	# shift the parameter offset position to the right (as we've just stored the value) so $2 is now $1
	shift
	
	# check the 'new' $1 exists and **doesn't** start with a hyphen (i.e. make sure it's NOT another option parameter)
	if [ "$1" != "" ] && [ "$1" != "-"* ]
		# if it's not an option parameter then it must be an argument value, so we store it in OPTARG, like so...
		then OPTARG="$1"
		shift # and we can shift param offset position again ready for the next time round the loop
	else
		OPTARG=""
	fi
	
	# check OPT for required action(s)
	case $OPT in
		-h | --help | --more )
			# call the function to show the usage/help
			show_usage
			
			# check for the 'more help' switch (remember we've shifted the param offset)
			if [ $1 = "--more" ]
				then show_more
			fi
			
			# that's it we're done, they asked for help and they got it, we can exit with everything A-Okay!
			exit 0
		;;
		--add-host ) # calls the 'add_host' function
			add_host $@
			exit
		;;
		--make-logs ) # calls the 'make_logs' function
			make_logs $@
			exit
		;;
		--make-vhost )
			# TODO make the 'make_vhost' function callable individually
			make_vhost $@
			exit
		;;
		-p | --prefix )
			# store the value for the vhost prefix
			VHOST_PREFIX="$OPTARG"
		;;
		-r | --port )
			# store the vhost's port value
			VHOST_PORT="$OPTARG"
		;;
		-d | --dir )
			# set the absolute path for the vhost's document root
			VHOST_PATH="$OPTARG"
		;;
		-n | --name )
			# get the name for the vhost
			VHOST_NAME="$OPTARG"
		;;
		-l | --log-level )
			# get the log-level value for Apache
			VHOST_LOGLEVEL="$OPTARG"
		;;
		-t | --template )
			# if the user has specified a template file to use, store the reference to it
			TEMPLATE_FILE="$OPTARG"
		;;
		\?) # unknown parameter/option !!
			# print a notice message
			echo "Invalid option: -$OPT"
			# show the usage info
			show_usage
			# exit with an error status
			exit 1
		;;
	esac
done


# Check if a config file already exists
if [ -f "$CONF_DIR/$VHOST_NAME" ]
	then echo "The vhost config file '$CONF_DIR/$VHOST_NAME' already exists!"
	echo "Please enter your required action: v (overwrite) | b (backup then overwrite) | c (cancel)"
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
			echo "Proceeding with safest option..."
			cp "$CONF_DIR/$VHOST_NAME" "$CONF_DIR/$VHOST_NAME.bak"
			echo "Bakup file created!"
		;;
	esac
fi


# Check if user has supplied a vhost template file
if [ -f "$TEMPLATE_FILE" ]
	# if so use this to create the vhost's config file
	# TODO figure out how to parse the values in to template file's placholder variables
	then cat "$TEMPLATE_FILE" > "$CONF_DIR/$VHOST_NAME"
else
	# otherwise we'll use our built-in template using the 'heredoc' method
	make_vhost > "$CONF_DIR/$VHOST_NAME"
fi

# now we create the log directory and files
make_logs

# let's add the new vhost to our 'hosts' file
add_host "$VHOST_PREFIX.$VHOST_NAME"

# now we can enable the new config
a2ensite "$VHOST_NAME"

# and restart Apache
service apache2 reload

# !! Job Done !!

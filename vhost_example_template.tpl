# Virtual host config for ${VHOST_NAME}
<VirtualHost ${VHOST_PREFIX}.${VHOST_NAME}:${VHOST_PORT}>
	NameVirtualHost ${VHOST_PREFIX}.${VHOST_NAME}:${VHOST_PORT}
	ServerAlias *.${VHOST_PREFIX}.${VHOST_NAME}
	
	DocumentRoot ${WEB_ROOT}/${VHOST_PATH}
	
	<Directory ${WEB_ROOT}/${VHOST_PATH}/>
		Options -Indexes +FollowSymLinks
		AllowOverride All
		Order deny,allow
		Deny from all
		Allow from 127.0.0.1
	</Directory>
	
	# Define custom log level
	LogLevel ${VHOST_LOGLEVEL}
	
	# Set up custom log files
	ErrorLog ${APACHE_LOG_DIR}/${VHOST_NAME}/error.log
	CustomLog ${APACHE_LOG_DIR}/${VHOST_NAME}/access.log combined
</VirtualHost>

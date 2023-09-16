#!/bin/sh
GLPI_TARBALL="/root/glpi-10.0.6.tgz"
FUSION_TARBALL="/root/fusioninventory-10.0.6+1.1.tar.bz2"
NORMAL='\e[39m'
RED='\e[31m'
GREEN='\e[32m'

msglog() {
	case "${1}" in
                green)
                        TEXT_COLOR="${GREEN}"
                        ;;
                red)
                        TEXT_COLOR="${RED}"
                        ;;
                normal)
                        TEXT_COLOR="${NORMAL}"
                        ;;
        esac
	DATE=$(date '+%Y %b %d %H:%M:%S')
	echo ${DATE} ${TEXT_COLOR}${2}${NORMAL}
}

waiting_for_db() {
while ! mysqlshow -h db -uroot -p${MYSQL_ROOT_PASSWORD} 2>&1 | grep "^| ${MYSQL_DATABASE}" > /dev/null 2>&1 ; do
	msglog red "Waiting for mysql database initilization..."
	sleep 5
done
}


if [ -z "$(ls -A /var/www/html)" ] ; then
	waiting_for_db
	msglog red "Initialazing ${GLPI_TARBALL}..."
	cd /root
	tar xf ${GLPI_TARBALL}
	cp -r /root/glpi/config/. /etc/glpi/.
	cp -r /root/glpi/files/. /var/lib/glpi/.
	rm -r /root/glpi/config /root/glpi/files
	cp -r /root/glpi/. /var/www/html/.
	cd /var/www/html/plugins
	tar xf ${FUSION_TARBALL}
	rm -r /root/glpi
	mysql --host=db --user=root --password=${MYSQL_ROOT_PASSWORD} << EOF
use mysql;
GRANT SELECT ON time_zone_name TO '${MYSQL_USER}'@'%';
EOF
	cd /var/www/html
	php bin/console db:install --config-dir=${GLPI_CONFIG_DIR} -L fr_FR -H db -d ${MYSQL_DATABASE} -u ${MYSQL_USER} -p ${MYSQL_PASSWORD} -n
	php bin/console glpi:plugin:install -u glpi fusioninventory -n
	php bin/console glpi:plugin:activate fusioninventory -n
	rm install/install.php
	chown -R www-data:www-data /var/www/html /etc/glpi /var/lib/glpi /var/log/glpi
	msglog green "Initialazing complete..."
else
	msglog green "GLPI is already initialized"
	cd /var/www/html
	GLPI_ACTUAL_VERSION=$(awk -F", '" '/^define\(.GLPI_VERSION/ { print $2 }' inc/define.php | sed 's/\([0-9\.]*\).*/\1/')
	FUSIONINVENTORY_ACTUAL_VERSION=$(awk -F', "' '/^define \(.PLUGIN_FUSIONINVENTORY_VERSION/ { print $2 }' plugins/fusioninventory/setup.php | sed 's/\([0-9\.+]*\).*/\1/')
	if [ "${GLPI_ACTUAL_VERSION}" = "${GLPI_VERSION}" -a "${FUSIONINVENTORY_ACTUAL_VERSION}" = "${FUSIONINVENTORY_VERSION}" ] ; then
		msglog green "GLPI already up2date"
		exit
	fi
	msglog red "Updating GLPI from ${GLPI_ACTUAL_VERSION} to ${GLPI_VERSION}"
	waiting_for_db
	php bin/console glpi:maintenance:enable -n
	php bin/console glpi:plugin:deactivate fusioninventory -n
	cd /root
	tar xf ${GLPI_TARBALL}
	rm -r glpi/config glpi/files /var/www/html
	mv glpi /var/www/html
	cd /var/www/html/plugins
	tar xf ${FUSION_TARBALL}
	rm /var/www/html/install/install.php
	cd /var/www/html
	php bin/console db:update --config-dir=${GLPI_CONFIG_DIR} -n
	php bin/console glpi:maintenance:disable -n
	chown -R www-data:www-data /var/www/html /etc/glpi /var/lib/glpi /var/log/glpi
fi

#!/bin/bash

if [ $USER != "root" ]; then
	echo "Execute as user root"
	exit 1
fi

if [ "$1" == "" ]; then
	echo "Please provide name of environment"
	echo
	./list_dev_environments.sh
	exit 2
fi
name=$1

echo
echo "Drop Odoo development environment -> $name"
echo

if [ "$(grep "^$name" /etc/passwd | wc -l)" != "1" ]; then
	echo "No system user with this name"
else
	echo "Delete system user $name"
	deluser $name
fi

echo
if [ ! -d "/opt/odoo/dev_environments/$name" ]; then
	echo "No directory with this name"
else
	echo "Delete directory $name"
	rm -Rf "/opt/odoo/dev_environments/$name"
fi

echo
db_name="FENECON_${name#odoo_}"
if [ "$(sudo -u postgres psql -l | cut -d' ' -f 2 | grep $db_name | wc -l)" != "1" ]; then
	echo "No database with this name"
else
	echo "Drop database $db_name"
	sudo -u postgres dropdb $db_name
fi

echo
if [ "$(sudo -u postgres psql -c '\du' | grep "^ $name" | wc -l)" != "1" ]; then
	echo "No database user with this name"
else
	echo "Drop user $name from database"
	sudo -u postgres dropuser $name
fi


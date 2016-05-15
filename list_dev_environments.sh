#!/bin/bash

if [ $USER != "root" ]; then
	echo "Execute as user root"
	exit 1
fi
echo
echo "List Odoo development environments"
echo

echo "System users"
grep '^odoo_' /etc/passwd | cut -d':' -f1

echo
echo "Directories"
ls -1 /opt/odoo/dev_environments/

echo
echo "Databases"
db_src=$(grep db_name /opt/odoo/.openerp_serverrc | cut -d" " -f3)
sudo -u postgres psql -l | cut -d" " -f 2 | grep "${db_src}_"

echo
echo "Database users"
sudo -u postgres psql -c '\du' | grep '^ odoo_' | cut -d ' ' -f2


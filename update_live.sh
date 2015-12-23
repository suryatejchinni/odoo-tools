#!/bin/bash
if [ $UID -ne 0 ]; then
	echo "Please run as root!"
	exit 1
fi
if [ $# -eq 0 ]; then
	echo "Which packages to update?"
	exit 1
fi
db_src=$(grep db_name /opt/odoo/.openerp_serverrc | cut -d" " -f3)
echo
echo "Updating Odoo live for ${db_src}"
echo "Packages: $@"
echo
echo "Stopping Odoo service"
systemctl stop odoo
echo "Starting Update"
sudo -u odoo /opt/odoo/ocb/odoo.py -d ${db_src} --db-filter '^${db_src}$' -u $@ --stop-after-init --i18n-overwrite
echo "Starting Odoo service"
systemctl start odoo
echo "Finished"
echo

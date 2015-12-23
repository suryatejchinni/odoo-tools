#!/bin/bash
if [ $USER != "odoo" ]; then
	SUDO="sudo -u odoo";
fi
echo
echo "Deleting old Odoo development environments"
db_src=$(grep db_name /opt/odoo/.openerp_serverrc | cut -d" " -f3)
dbs=$(${SUDO} psql -l | cut -d" " -f 2 | grep "${db_src}_")
echo
echo "List current databases"
echo $dbs
for db in $dbs; do
	echo "Drop $db"
	${SUDO} dropdb $db
done
echo "Delete local files"
rm -fR /opt/odoo/.local/share/Odoo/filestore/${db_src}_*
echo "Finished"

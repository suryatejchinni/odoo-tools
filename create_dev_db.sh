#!/bin/bash
if [ $USER != "odoo" ]; then
	echo "Execute as user odoo"
	exit 1
fi
now=$(date +"%Y%m%d_%H%M")
T="$(date +%s)"
db_src=$(grep db_name /opt/odoo/.openerp_serverrc | cut -d" " -f3)
db_dst=${db_src}_${now}
echo
echo "Creating Odoo development environment"
echo "Timestamp: $now"
echo
echo "Disconnect users"
psql -d ${db_src} -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='${db_src}' AND pid <> pg_backend_pid();" >/dev/null || {
	echo "-> failed!"
	exit 1
}
# drop target db: dropdb $DB_DST --if-exists || { echo "drop failed"; exit 1; }
echo "Create new database: ${db_dst}"
createdb ${db_dst} || {
	echo "-> failed!"
	exit 1
}
echo "Copy database (${db_src} -> ${db_dst})"
pg_dump -Fc ${db_src} | pg_restore -d ${db_dst} || {
	echo "-> failed!"
	exit 1
}
echo "Apply database hooks"
echo " Disable outgoing mailserver"
psql -d ${db_dst} -c "UPDATE fetchmail_server SET password = '';"
echo " Disable incoming mailserver"
psql -d ${db_dst} -c "UPDATE ir_mail_server SET smtp_port = '80';"

echo "Copy local files (-> .local/share/Odoo/filestore/${db_dst})"
cp -R /opt/odoo/.local/share/Odoo/filestore/${db_src} /opt/odoo/.local/share/Odoo/filestore/${db_dst}
T="$(($(date +%s)-T))"

echo "Finished after ${T} seconds"
echo
echo "List current databases"
psql -l | cut -d" " -f 2 | grep "${db_src}_"
echo
echo "Use with command: ./ocb/odoo.py -d ${db_dst} --db-filter '^${db_dst}$' --xmlrpc-port=8070 --i18n-overwrite"

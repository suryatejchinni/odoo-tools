#!/bin/bash

addon_folders_to_copy="fenecon"

if [ $USER != "root" ]; then
	echo "Execute as user root"
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
echo "Create user: odoo_$now"
adduser odoo_$now --gecos "" --home "/opt/odoo/dev_environments/odoo_$now" --ingroup "odoo" --disabled-login --disabled-password --shell "/bin/bash"
#UNDO with deluser odoo_20160515_1637

echo "Copy/link files to /opt/odoo/dev_environments/odoo_$now"
echo "  Base      -> ocb"
ln -s "/opt/odoo/ocb" "/opt/odoo/dev_environments/odoo_$now/ocb"
echo "  Configfile-> . (including fixes)"
cp ".openerp_serverrc" "/opt/odoo/dev_environments/odoo_$now/"
addons=$(cat .openerp_serverrc | grep 'addons_path' | cut -d' ' -f 3 | tr ',' ' ')
new_addons_path=
for path_src in $addons; do
	path_dst=${path_src#/opt/odoo/}
	# ignore paths starting with "ocb/", already copied
	if [[ $path_dst != ocb/* ]]; then
		if [[ " $addon_folders_to_copy " =~ " $path_dst " ]]; then
			echo "  Addon (cp)-> $path_dst"
			cp -R "$path_src" "/opt/odoo/dev_environments/odoo_$now/$path_dst/"
		else
			echo "  Addon (ln)-> $path_dst"
			ln -s "$path_src" "/opt/odoo/dev_environments/odoo_$now/$path_dst"
		fi
	fi
	new_addons_path="$new_addons_path,/opt/odoo/dev_environments/odoo_$now/$path_dst"
done
new_addons_path=${new_addons_path#,} # remove first comma
sed --in-place 's|^\(addons_path = \).*$|\1'"$new_addons_path"'|' "/opt/odoo/dev_environments/odoo_$now/.openerp_serverrc"
sed --in-place 's|^\(db_user = \).*$|\1'"odoo_$now"'|' "/opt/odoo/dev_environments/odoo_$now/.openerp_serverrc"
sed --in-place 's|^\(data_dir = \).*$|\1'"/opt/odoo/dev_environments/odoo_$now/.local/share/Odoo"'|' "/opt/odoo/dev_environments/odoo_$now/.openerp_serverrc"

echo "  Filestore -> .local/share/Odoo/filestore/${db_dst}"
mkdir -p "/opt/odoo/dev_environments/odoo_$now/.local/share/Odoo/filestore/"
cp -R "/opt/odoo/.local/share/Odoo/filestore/${db_src}" "/opt/odoo/dev_environments/odoo_$now/.local/share/Odoo/filestore/${db_dst}"
echo "  Fix permissions"
chown odoo:odoo "/opt/odoo/dev_environments/odoo_$now" -R
chmod g+rw "/opt/odoo/dev_environments/odoo_$now" -R

echo "Disconnect users"
sudo -u odoo psql -d ${db_src} -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='${db_src}' AND pid <> pg_backend_pid();" >/dev/null || {
	echo "-> failed!"
	exit 1
}
echo "Create database user odoo_$now"
sudo -u postgres createuser --createdb --superuser "odoo_$now"
echo "Create new database: ${db_dst}"
sudo -u "odoo_$now" createdb ${db_dst} || {
	echo "-> failed!"
	exit 1
}
echo "Copy database (${db_src} -> ${db_dst})"
sudo -u odoo pg_dump -Fc ${db_src} | sudo -u "odoo_$now" pg_restore --no-owner --role="odoo_$now" -d ${db_dst} || {
	echo "-> failed!"
	exit 1
}

echo "Apply database hooks"
echo " Disable outgoing mailserver"
sudo -u "odoo_$now" psql -d ${db_dst} -c "UPDATE fetchmail_server SET password = '';"
echo " Disable incoming mailserver"
sudo -u "odoo_$now" psql -d ${db_dst} -c "UPDATE ir_mail_server SET smtp_port = '80';"

T="$(($(date +%s)-T))"

echo "Finished after ${T} seconds"
echo
echo "Change current user: su - odoo_$now"
echo "Use with command:    ./ocb/odoo.py -d ${db_dst} --db-filter '^${db_dst}$' --xmlrpc-port=8070"

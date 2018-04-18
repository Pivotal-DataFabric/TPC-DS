#!/bin/bash
set -e

INIT_2_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $INIT_2_DIR/../functions.sh
source_bashrc
source $INIT_2_DIR/../tpcds_variables.sh

step=init
init_log $step
start_log
schema_name="tpcds"
table_name="init"

set_segment_bashrc()
{
	echo "if [ -f /etc/bashrc ]; then" > $INIT_2_DIR/segment_bashrc
	echo "	. /etc/bashrc" >> $INIT_2_DIR/segment_bashrc
	echo "fi" >> $INIT_2_DIR/segment_bashrc
	echo "source $GREENPLUM_PATH" >> $INIT_2_DIR/segment_bashrc
	chmod 755 $INIT_2_DIR/segment_bashrc

	#copy generate_data.sh to ~/
	for i in $(cat $INIT_2_DIR/../segment_hosts.txt); do
		# don't overwrite the master.  Only needed on single node installs
		shortname=$(echo $i | awk -F '.' '{print $1}')
		if [ "$MASTER_HOST" != "$shortname" ]; then
			echo "copy new .bashrc to $i:$ADMIN_HOME"
			scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $INIT_2_DIR/segment_bashrc $i:$ADMIN_HOME/.bashrc
		fi
	done
}

check_gucs()
{
	update_config="0"

	get_version
	if [[ "$VERSION" == "gpdb_4_3" || "$VERSION" == "gpdb_5_0" || "$VERSION" == "hawq_1" ]]; then
		echo "Set optimizer to " $OPTIMIZER
		if [ "$VERSION" == "hawq_2" ]; then
		    hawq config -c optimizer -v on
		else
		    gpconfig -c optimizer -v $OPTIMIZER --masteronly
				gpconfig -c statement_timeout -v $QUERY_TIMEOUT 
		fi
		update_config="1"

		echo "check analyze_root_partition"
		counter=$(psql -v ON_ERROR_STOP=ON -t -A -c "show optimizer_analyze_root_partition" | grep -i "on" | wc -l; exit ${PIPESTATUS[0]})
		if [ "$counter" -eq "0" ]; then
			echo "enabling analyze_root_partition"
			if [ "$VERSION" == "hawq_2" ]; then
				hawq config -c analyze_root_partition -v on
			else
				gpconfig -c optimizer_analyze_root_partition -v on --masteronly
			fi
			update_config="1"
		fi
	fi

	echo "check gp_autostats_mode"
	counter=$(psql -v ON_ERROR_STOP=ON -t -A -c "show gp_autostats_mode" | grep -i "none" | wc -l; exit ${PIPESTATUS[0]})
	if [ "$counter" -eq "0" ]; then
		echo "changing gp_autostats_mode to none"
		if [ "$VERSION" == "hawq_2" ]; then
			hawq config -c gp_autostats_mode -v NONE
		else
			gpconfig -c gp_autostats_mode -v none --masteronly
		fi
		update_config="1"
	fi

	if [ "$update_config" -eq "1" ]; then
		echo "update cluster because of config changes"
		if [ "$VERSION" == "hawq_2" ]; then
			hawq stop cluster -u -a
		else
			gpstop -u
		fi
	fi
}

copy_config()
{
	echo "copy config files"
	if [ "$MASTER_DATA_DIRECTORY" != "" ]; then
		cp $MASTER_DATA_DIRECTORY/pg_hba.conf $INIT_2_DIR/../log/
		cp $MASTER_DATA_DIRECTORY/postgresql.conf $INIT_2_DIR/../log/
	fi
	#gp_segment_configuration
	psql -q -A -t -v ON_ERROR_STOP=ON -c "SELECT * FROM gp_segment_configuration" -o $INIT_2_DIR/../log/gp_segment_configuration.txt
}

set_psqlrc()
{
	echo "set search_path=tpcds,public;" > ~/.psqlrc
	echo "\timing" >> ~/.psqlrc
	chmod 600 ~/.psqlrc
}

set_segment_bashrc
check_gucs
copy_config
set_psqlrc

log

end_step $step

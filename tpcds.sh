#!/bin/bash
set -euxo pipefail
PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

MYCMD="tpcds.sh"
CONFIG_FILE="$PWD/tpcds_variables.sh"
##################################################################################################################################################
# Functions
##################################################################################################################################################
check_variables()
{
	new_variable="0"

	### Make sure variables file is available
	if [ ! -f "$CONFIG_FILE" ]; then
		touch $CONFIG_FILE
		echo "Touched $CONFIG_FILE"
		new_variable=$(($new_variable + 1))
	fi
	echo "command: grep "REPO=" $CONFIG_FILE"
	local count=$(grep "REPO=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "REPO=\"TPC-DS\"" >> $CONFIG_FILE
		echo "Wrote REPO=TPC-DS"
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "REPO_URL=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "REPO_URL=\"https://github.com/Pivotal-DataFabric/TPC-DS\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "ADMIN_USER=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "ADMIN_USER=\"gpadmin\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "INSTALL_DIR=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "INSTALL_DIR=\"/pivotalguru\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "EXPLAIN_ANALYZE=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "EXPLAIN_ANALYZE=\"false\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "SQL_VERSION=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "SQL_VERSION=\"tpcds\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "RANDOM_DISTRIBUTION=" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RANDOM_DISTRIBUTION=\"false\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "MULTI_USER_COUNT" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "MULTI_USER_COUNT=\"5\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	local count=$(grep "GEN_DATA_SCALE" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "GEN_DATA_SCALE=\"3000\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#00
	local count=$(grep "RUN_COMPILE_TPCDS" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_COMPILE_TPCDS=\"false\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#01
	local count=$(grep "RUN_GEN_DATA" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_GEN_DATA=\"false\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#02
	local count=$(grep "RUN_INIT" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_INIT=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#03
	local count=$(grep "RUN_DDL" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_DDL=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#04
	local count=$(grep "RUN_LOAD" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_LOAD=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#05
	local count=$(grep "RUN_SQL" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_SQL=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#06
	local count=$(grep "RUN_SINGLE_USER_REPORT" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_SINGLE_USER_REPORT=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#07
	local count=$(grep "RUN_MULTI_USER" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_MULTI_USER=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#08
	local count=$(grep "RUN_MULTI_USER_REPORT" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "RUN_MULTI_USER_REPORT=\"true\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#09
	local count=$(grep "OPTIMIZER" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "OPTIMIZER=\"on\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#10
	local count=$(grep "QUERY_TIMEOUT" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "QUERY_TIMEOUT=\"0\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#11
	local count=$(grep "EXPLAIN_PLAN" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "EXPLAIN_PLAN=\"false\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi
	#12
	local count=$(grep "EXTRACT_GPSD" $CONFIG_FILE | wc -l)
	if [ "$count" -eq "0" ]; then
		echo "EXTRACT_GPSD=\"false\"" >> $CONFIG_FILE
		new_variable=$(($new_variable + 1))
	fi

	echo "############################################################################"
	echo "Sourcing $CONFIG_FILE"
	echo "############################################################################"
	echo ""
	source $CONFIG_FILE
	cat $CONFIG_FILE
}
exit_if_new_vars()
{
	if [ "$new_variable" -gt "0" ]; then
		echo "There are new variables in the tpcds_variables.sh file.  Please review to ensure the values are correct and then re-run this script."
		exit 1
	fi
}
check_user()
{
	### Make sure root is executing the script. ###
	echo "############################################################################"
	echo "Make sure root is executing this script."
	echo "############################################################################"
	echo ""
	local WHOAMI=`whoami`
	if [ "$WHOAMI" != "root" ]; then
		echo "Script must be executed as root!"
		exit 1
	fi
}

yum_installs()
{
	### Install and Update Demos ###
	echo "############################################################################"
	echo "Install git and gcc with yum."
	echo "############################################################################"
	echo ""
	# Install git and gcc if not found
	local YUM_INSTALLED=$(yum --help 2> /dev/null | wc -l)
	local CURL_INSTALLED=$(gcc --help 2> /dev/null | wc -l)
	local GIT_INSTALLED=$(git --help 2> /dev/null | wc -l)

	if [ "$YUM_INSTALLED" -gt "0" ]; then
		if [ "$CURL_INSTALLED" -eq "0" ]; then
			yum -y install gcc
		fi
		if [ "$GIT_INSTALLED" -eq "0" ]; then
			yum -y install git
		fi
	else
		if [ "$CURL_INSTALLED" -eq "0" ]; then
			echo "gcc not installed and yum not found to install it."
			echo "Please install gcc and try again."
			exit 1
		fi
		if [ "$GIT_INSTALLED" -eq "0" ]; then
			echo "git not installed and yum not found to install it."
			echo "Please install git and try again."
			exit 1
		fi
	fi
	echo ""
}

repo_init()
{
	### Install repo ###
	echo "############################################################################"
	echo "Install the github repository."
	echo "############################################################################"
	echo ""

	internet_down="0"
	for j in $(curl google.com 2>&1 | grep "Could not resolve host"); do
		internet_down="1"
	done

	if [ ! -d $INSTALL_DIR ]; then
		if [ "$internet_down" -eq "1" ]; then
			echo "Unable to continue because repo hasn't been downloaded and Internet is not available."
			exit 1
		else
			echo ""
			echo "Creating install dir"
			echo "-------------------------------------------------------------------------"
			mkdir $INSTALL_DIR
			chown $ADMIN_USER $INSTALL_DIR
		fi
	fi

	if [ ! -d $INSTALL_DIR/$REPO ]; then
		if [ "$internet_down" -eq "1" ]; then
			echo "Unable to continue because repo hasn't been downloaded and Internet is not available."
			exit 1
		else
			echo ""
			echo "Creating $REPO directory"
			echo "-------------------------------------------------------------------------"
			mkdir $INSTALL_DIR/$REPO
			chown $ADMIN_USER $INSTALL_DIR/$REPO
			su -c "cd $INSTALL_DIR; GIT_SSL_NO_VERIFY=true; git clone $REPO_URL" $ADMIN_USER
		fi
	else
		if [ "$internet_down" -eq "0" ]; then
			git config --global user.email "$ADMIN_USER@$HOSTNAME"
			git config --global user.name "$ADMIN_USER"
			su -c "cd $INSTALL_DIR/$REPO; GIT_SSL_NO_VERIFY=true; git fetch --all; git reset --hard origin/ubuntu" $ADMIN_USER
		fi
	fi
}

script_check()
{
	### Make sure the repo doesn't have a newer version of this script. ###
	echo "############################################################################"
	echo "Make sure this script is up to date."
	echo "############################################################################"
	echo ""
	# Must be executed after the repo has been pulled
	local d=`diff $PWD/$MYCMD $INSTALL_DIR/$REPO/$MYCMD | wc -l`

	if [ "$d" -eq "0" ]; then
		echo "$MYCMD script is up to date so continuing to TPC-DS."
		echo ""
	else
		echo "$MYCMD script is NOT up to date."
		echo ""
		cp $INSTALL_DIR/$REPO/$MYCMD $PWD/$MYCMD
		echo "After this script completes, restart the $MYCMD with this command:"
		echo "./$MYCMD"
		exit 1
	fi

}

check_sudo()
{
	cp $INSTALL_DIR/$REPO/update_sudo.sh $PWD/update_sudo.sh
	$PWD/update_sudo.sh
}

echo_variables()
{
	echo "############################################################################"
	echo "REPO: $REPO"
	echo "REPO_URL: $REPO_URL"
	echo "ADMIN_USER: $ADMIN_USER"
	echo "INSTALL_DIR: $INSTALL_DIR"
	echo "MULTI_USER_COUNT: $MULTI_USER_COUNT"
	echo "OPTIMIZER": $OPTIMIZER
	echo "############################################################################"
	echo ""
}

copy_tpcds_variable()
{
    cp $CONFIG_FILE $INSTALL_DIR/$REPO/tpcds_variables.sh
    chmod 755 $INSTALL_DIR/$REPO/tpcds_variables.sh
    cat $INSTALL_DIR/$REPO/tpcds_variables.sh
}

##################################################################################################################################################
# Body
##################################################################################################################################################

check_user
check_variables
#yum_installs
repo_init
#script_check
exit_if_new_vars
#check_sudo
echo_variables
copy_tpcds_variable

export MASTER_DATA_DIRECTORY=/greenplum/data-1

CMD_CD="cd \"$INSTALL_DIR/$REPO\";"
CMD_ROLLOUT="./rollout.sh $GEN_DATA_SCALE $EXPLAIN_ANALYZE $SQL_VERSION $RANDOM_DISTRIBUTION $MULTI_USER_COUNT $RUN_COMPILE_TPCDS $RUN_GEN_DATA $RUN_INIT $RUN_DDL $RUN_LOAD $RUN_SQL $RUN_SINGLE_USER_REPORT $RUN_MULTI_USER $RUN_MULTI_USER_REPORT $EXPLAIN_PLAN $EXTRACT_GPSD $OPTIMIZER $QUERY_TIMEOUT"
CMD="$CMD_CD $CMD_ROLLOUT"
su -c "$CMD" $ADMIN_USER
exit_status=$?
if [[ $exit_status -ne 0 ]]; then
	exit $exit_status
else
	echo "Finished execution of tpcds.sh"
fi

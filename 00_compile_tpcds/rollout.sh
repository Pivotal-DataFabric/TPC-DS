#!/bin/bash
set -e

COMPILE_0_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $COMPILE_0_DIR/../functions.sh
source_bashrc

GEN_DATA_SCALE=$1
EXPLAIN_ANALYZE=$2
SQL_VERSION=$3   
RANDOM_DISTRIBUTION=$4
MULTI_USER_COUNT=$5

if [[ "$GEN_DATA_SCALE" == "" || "$EXPLAIN_ANALYZE" == "" || "$SQL_VERSION" == "" || "$RANDOM_DISTRIBUTION" == "" || "$MULTI_USER_COUNT" == "" ]]; then
	echo "You must provide the scale as a parameter in terms of Gigabytes, true/false to run queries with EXPLAIN ANALYZE option, the SQL_VERSION, and true/false to use random distrbution."
	echo "Example: ./rollout.sh 100 false tpcds false 5"
	echo "This will create 100 GB of data for this test, not run EXPLAIN ANALYZE, use standard TPC-DS, not use random distribution and use 5 sessions for the multi-user test."
	exit 1
fi

step=compile_tpcds
init_log $step
start_log
schema_name="tpcds"
table_name="compile"

make_tpc()
{
	#compile the tools
	cd $COMPILE_0_DIR/tools
	rm -f *.o
	make
	cd ..
}

copy_tpc()
{
	cp $COMPILE_0_DIR/tools/dsqgen ../*_gen_data/
	cp $COMPILE_0_DIR/tools/dsqgen ../*_multi_user/
	cp $COMPILE_0_DIR/tools/tpcds.idx ../*_gen_data/
	cp $COMPILE_0_DIR/tools/tpcds.idx ../*_multi_user/

	#copy the compiled dsdgen program to the segment hosts
	for i in $(cat $COMPILE_0_DIR/../segment_hosts.txt); do
		echo "copy tpcds binaries to $i:$ADMIN_HOME"
		scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no tools/dsdgen tools/tpcds.idx $i:$ADMIN_HOME/
	done
}

copy_queries()
{
	rm -rf $COMPILE_0_DIR/../*_gen_data/query_templates
	rm -rf $COMPILE_0_DIR/../*_multi_user/query_templates
	cp -R query_templates $COMPILE_0_DIR/../*_gen_data/
	cp -R query_templates $COMPILE_0_DIR/../*_multi_user/
}

make_tpc
create_hosts_file
copy_tpc
copy_queries
log

end_step $step

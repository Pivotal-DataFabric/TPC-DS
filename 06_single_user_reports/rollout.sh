#!/bin/bash
set -e

RUN_SINGLE_USER_REPORT=$6

if [ "$RUN_SINGLE_USER_REPORT" == "false" ]; then
	echo "RUN_SINGLE_USER_REPORT set to false so exiting..."
	exit 0
fi

SINGLE_6_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SINGLE_6_DIR/../functions.sh
source_bashrc
step=single_user_reports

init_log $step

for i in $(ls $SINGLE_6_DIR/*.sql | grep -v report.sql); do
	table_name=`echo $i | awk -F '.' '{print $3}'`
	EXECUTE="'cat $SINGLE_6_DIR/../log/rollout_$table_name.log'"

	echo "psql -v ON_ERROR_STOP=ON -a -f $i -v EXECUTE=\"$EXECUTE\""
	psql -v ON_ERROR_STOP=ON -a -f $i -v EXECUTE="$EXECUTE"
	echo ""
done

echo "********************************************************************************"
echo "Generate Data"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=ON -P pager=off -f $SINGLE_6_DIR/gen_data_report.sql
echo ""
echo "********************************************************************************"
echo "Data Loads"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=ON -P pager=off -f $SINGLE_6_DIR/loads_report.sql
echo ""
echo "********************************************************************************"
echo "Analyze"
echo "********************************************************************************"
#psql -F $'\t' -A -v ON_ERROR_STOP=ON -P pager=off -f $SINGLE_6_DIR/analyze_report.sql
echo ""
echo ""
echo "********************************************************************************"
echo "Queries"
echo "********************************************************************************"
psql -F $'\t' -A -v ON_ERROR_STOP=ON -P pager=off -f $SINGLE_6_DIR/queries_report.sql
echo ""
end_step $step

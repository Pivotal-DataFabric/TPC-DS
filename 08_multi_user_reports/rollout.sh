#!/bin/bash
set -e

RUN_MULTI_USER_REPORT=$7

if [ "$RUN_MULTI_USER_REPORT" == "false" ]; then
	echo "RUN_MULTI_USER_REPORT set to false so exiting..."
	exit 0
fi

MULTI_8_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $MULTI_8_DIR/../functions.sh
source_bashrc
step="multi_user_reports"

init_log $step

for i in $(ls $MULTI_8_DIR/*.sql | grep -v report.sql); do
        schema_name=`echo $i | awk -F '.' '{print $2}'`
	EXECUTE="'cat $MULTI_8_DIR/../log/rollout_$schema_name*.log'"
        echo "psql -v ON_ERROR_STOP=ON -a -f $i -v EXECUTE=\"$EXECUTE\""
        psql -v ON_ERROR_STOP=ON -a -f $i -v EXECUTE="$EXECUTE"
        echo ""
done

psql -F $'\t' -A -v ON_ERROR_STOP=ON -P pager=off -f $MULTI_8_DIR/detailed_report.sql
echo ""

end_step $step

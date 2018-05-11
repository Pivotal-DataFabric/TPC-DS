#!/bin/bash
set -e

RUN_MULTI_USER_REPORT=$7

if [ "$RUN_MULTI_USER_REPORT" == "false" ]; then
	echo "RUN_MULTI_USER_REPORT set to false so exiting..."
	exit 0
fi

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc
step="multi_user_reports"

init_log $step

for i in $(ls $PWD/*.sql | grep -v report.sql); do
        schema_name=`echo $i | awk -F '.' '{print $2}'`
	EXECUTE="'cat $PWD/../log/rollout_$schema_name*.log'"
        echo "psql -v ON_ERROR_STOP=ON -a -f $i -v EXECUTE=\"$EXECUTE\""
        psql -v ON_ERROR_STOP=ON -a -f $i -v EXECUTE="$EXECUTE"
        echo ""
done

psql -F $'\t' -A -v ON_ERROR_STOP=ON -P pager=off -f $PWD/detailed_report.sql
echo ""

end_step $step

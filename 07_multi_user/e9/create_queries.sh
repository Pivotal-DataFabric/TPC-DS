#!/bin/bash
set -e
CREATE_E9_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

number_of_queries="5"

create_files()
{
	for VALUE in $@; do
		if [ "$i" -gt "0" ]; then
			if [ "$i" -le "$number_of_queries" ]; then
				q=$(printf %02d $query_id)
				query=$(printf %02d $VALUE)
				target="$CREATE_E9_DIR/$i/$q.query.$query.sql"
				source="$CREATE_E9_DIR/../../05_sql/*.e9.$query.sql"

				echo "cp $source $target"
				cp $source $target
			fi
		fi
		i=$(($i+1))
	done
}

for d in $(seq 1 5); do
	echo "rm -f $CREATE_E9_DIR/$d/*"
	rm -f $CREATE_E9_DIR/$d/*
done

query_id="100"
while read LINE
do
	query_id=$(($query_id+1))
	i="0"
	create_files ${LINE}
done < stream_map.txt

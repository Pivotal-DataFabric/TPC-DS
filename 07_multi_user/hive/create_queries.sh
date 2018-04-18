#!/bin/bash
set -e
CREATE_HIVE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

number_of_queries="10"

create_files()
{
	for VALUE in $@; do
		if [ "$i" -gt "0" ]; then
			if [ "$i" -le "$number_of_queries" ]; then
				q=$(printf %02d $query_id)
				query=$(printf %02d $VALUE)
				target="$CREATE_HIVE_DIR/$i/$q.query.$query.sql"
				source="$CREATE_HIVE_DIR/../../05_sql/*.hive.$query.sql"

				if [ -f $source ]; then
					echo "cp $source $target"
					cp $source $target
				fi
			fi
		fi
		i=$(($i+1))
	done
}

for d in $(seq 1 5); do
	echo "rm -f $CREATE_HIVE_DIR/$d/*"
	rm -f $CREATE_HIVE_DIR/$d/*
done

query_id="100"
while read LINE
do
	query_id=$(($query_id+1))
	i="0"
	create_files ${LINE}
done < stream_map.txt

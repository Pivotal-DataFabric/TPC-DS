#!/bin/bash

GEN_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $GEN_DIR/../functions.sh
source_bashrc

set -e

query_id=1
file_id=101

GEN_DATA_SCALE=$1

if [ "$GEN_DATA_SCALE" == "" ]; then
	echo "Usage: generate_queries.sh scale"
	echo "Example: ./generate_queries.sh 100"
	echo "This creates queries for 100GB of data."
	exit 1
fi

rm -f $GEN_DIR/query_0.sql

echo "$GEN_DIR/dsqgen -input $GEN_DIR/query_templates/templates.lst -directory $GEN_DIR/query_templates -dialect pivotal -scale $GEN_DATA_SCALE -verbose y -output $GEN_DIR"
$GEN_DIR/dsqgen -input $GEN_DIR/query_templates/templates.lst -directory $GEN_DIR/query_templates -dialect pivotal -scale $GEN_DATA_SCALE -verbose y -output $GEN_DIR

rm -f $GEN_DIR/../05_sql/*.query.*.sql

for p in $(seq 1 99); do
	q=$(printf %02d $query_id)
	filename=$file_id.tpcds.$q.sql
	template_filename=query$p.tpl
	start_position=""
	end_position=""
	for pos in $(grep -n $template_filename $GEN_DIR/query_0.sql | awk -F ':' '{print $1}'); do
		if [ "$start_position" == "" ]; then
			start_position=$pos
		else
			end_position=$pos
		fi
	done

	echo "echo \":EXPLAIN_ANALYZE\" > $GEN_DIR/../05_sql/$filename"
	echo ":EXPLAIN_ANALYZE" > $GEN_DIR/../05_sql/$filename
	echo "sed -n \"$start_position\",\"$end_position\"p $GEN_DIR/query_0.sql >> $GEN_DIR/../05_sql/$filename"
	sed -n "$start_position","$end_position"p $GEN_DIR/query_0.sql >> $GEN_DIR/../05_sql/$filename
	query_id=$(($query_id + 1))
	file_id=$(($file_id + 1))
	echo "Completed: $GEN_DIR/../05_sql/$filename"
done

echo ""
echo "queries 14, 23, 24, and 39 have 2 queries in each file.  Need to add :EXPLAIN_ANALYZE to second query in these files"
echo ""
special_queries=(14 23 24 39)
arr=()
for i in "${special_queries[@]}"; do
    skip=
    for j in "${timed_out_queries[@]}"; do
	[[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || arr+=("1$i.tpcds.$i.sql")
done
echo "special queries to be treated are:"
echo $(join , ${arr[@]})
echo ""

for z in "${arr[@]}"; do
	echo $z
	myfilename=$GEN_DIR/../05_sql/$z
	echo "myfilename: $myfilename"
	pos=$(grep -n ";" $myfilename | awk -F ':' '{print $1}' | head -1)
	pos=$(($pos+1))
	echo "pos: $pos"
	sed -i ''$pos'i\'$'\n'':EXPLAIN_ANALYZE'$'\n' $myfilename

done

echo "COMPLETE: dsqgen scale $GEN_DATA_SCALE"

#!/bin/sh
#
declare -a files
files=(/root/*.py)
declare -i lines=0
for i in $(seq 0 $[${#files[*]}-1]);do
	if [ $[$i%2] -eq 0 ];then
		let lines+=$(wc -l ${files[$i]} | cut -d ' ' -f 1)
	fi
done
echo "Lines: $lines."


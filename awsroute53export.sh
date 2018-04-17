#!/bin/bash

set -e

helpstring="script for amazon route 53 zones config export
supported arguments:
-d <directory_path> - output to directory. Directory must be nonexisting or empty. If argument is absent, output is redirected to stdout.
-l - list zones and exit.
-z <zone_id> - dump only zones containing specified string in id
-h -? - print this help"

# check for dependences

if ! [ -x "$(command -v aws)" ] ; then 
	echo "aws is not installed"
	exit 1
fi

if ! [ -x "$(command -v jq)" ] ; then 
	echo "jq is not installed"
	exit 1
fi


# parse arguments
while getopts "h?d:lz:" opt; do
	case "$opt" in
		h|\?)
			echo "$helpstring"
			exit 0;;
		d)  output_dir=$OPTARG
			;;
		z)  zoneid=$OPTARG
			;;
		l)  listzones=true
			;;
    esac
done

zones="$(aws route53 list-hosted-zones | jq -r '.HostedZones | map("" + .Name + "\t" + .Id)[]')"


if [ $listzones ]; then
	while read zone id; do
		echo $id $zone
	done <<< "$zones"
	exit 0
fi

# if zoneid filter specified

if ! [ -z ${zoneid+x} ]; then
	filteredzones=''
        while read zone id; do
		if [[ $id = *"$zoneid"* ]]; then
			filteredzones="$filteredzones $zone $id"
		fi
	done <<< "$zones"
	zones=$filteredzones
fi


if [ -z ${output_dir+x} ]; then
	while read zone id; do
		echo "$(aws route53 list-resource-record-sets --hosted-zone-id $id)"
	done <<< "$zones"
else
	if [ -d "$output_dir" ]; then
		if [ "$(ls -A $output_dir)" ]; then
			echo "output directory specified is not empty"
			exit 1
		fi
	else
		mkdir -p "$output_dir"
	fi
	while read zone id; do
		$(aws route53 list-resource-record-sets --hosted-zone-id $id > "$output_dir/$zone")
	done <<< "$zones"
fi

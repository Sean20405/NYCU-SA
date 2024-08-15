#!/bin/sh

while getopts ":i:o:c:j" op ; do
	case $op in
        i) 
            inputFile="$OPTARG" ;;
        o)
            outputDir="$OPTARG" ;;
        c)
            if [ "$OPTARG" = "csv" ] ; then
                space=","
                filetype="csv"
            elif [ "$OPTARG" = "tsv" ] ; then
                space='\t'
                filetype="tsv"
            fi
        ;;
        j) 
            hasInfo="Yes" ;;
        *)
            >&2 echo "hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]"
            >&2 echo ""
            >&2 echo "Available Options:"
            >&2 echo ""
            >&2 echo "-i: Input file to be decoded"
            >&2 echo "-o: Output directory"
            >&2 echo "-c csv|tsv: Output files.[ct]sv"
            >&2 echo "-j: Output info.json"
            exit 1
        ;;
    esac
done

mkdir -p "$outputDir"

invalid=0

files=$(yq ".files" "$inputFile" | jq -c .[])
name=$(yq ".name" "$inputFile")
timestamp=$(yq ".date" "$inputFile")
date=$(date -Iseconds -r "$timestamp")
author=$(yq ".author" "$inputFile")

if [ -n "$space" ] ; then
    printf "filename%bsize%bmd5%bsha1\n" "$space" "$space" "$space" >> "${outputDir}/files.${filetype}"
fi

for file in $files ; do
    type=$(echo "${file}" | jq '.type' | sed 's/"//g')
    filename=$(echo "${file}" | jq '.name' | sed 's/"//g')
    data=$(echo "${file}" | jq '.data' | sed 's/"//g' | base64 --decode)
    if echo "$filename" | grep -q "/" ; then
        mkdir -p "${outputDir}"/"${filename%/*}"
    fi
    path="${outputDir}/${filename}"
    printf "%s\n" "$data" > "$path"
    md5_check=$(echo "${file}" | jq '.hash.md5' | sed 's/"//g')
    sha_check=$(echo "${file}" | jq '.hash."sha-1"' | sed 's/"//g')
    size=$(wc -c "$path" | awk '{print $1;}')
    md5=$(md5sum "$path" | awk '{print $1;}')
    sha=$(sha1sum "$path" | awk '{print $1;}')

    if [ ! "$md5" = "$md5_check" ] || [ ! "$sha" = "$sha_check" ] ; then
        invalid=$(( "$invalid" + 1 ))
    fi

    if [ "$type" = "hw2" ] ; then
        ./hw2.sh -i "${path}" -o "${outputDir}"
    fi

    if [ -n "$space" ] ; then
        printf "%b%b%b%b%b%b%b\n" "${filename}" "${space}" "${size}" "${space}" "${md5}" "${space}" "${sha}" >> "${outputDir}/files.${filetype}"
    fi

done

if [ -n "$hasInfo" ] ; then
    info="{\n\t\"name\": ${name},\n\t\"author\": ${author},\n\t\"date\": \"${date}\"\n}"
    printf "%b\n" "${info}" >> "${outputDir}/info.json"
fi

exit $invalid

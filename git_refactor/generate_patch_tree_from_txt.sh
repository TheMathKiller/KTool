#!/bin/bash

ORGDIR=$(pwd)
TMPDIR=$(dirname ${BASH_SOURCE[0]})

cat $2 | while read file_and_path
do
    source $TMPDIR/generate_patch_tree.sh $1 $file_and_path
done

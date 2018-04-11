#!/bin/bash

patch_dir=(
    a
    b
    c
    d
    e
    f
    g
    h
    i
    j
    k
    l
    m
    n
    o
    p
    q
    r
    s
    t
    u
    v
    w
    x
    y
    z
)

ORGDIR=$(pwd)
TMPDIR=$(dirname ${BASH_SOURCE[0]})

git checkout -b temp

echo $2 > $TMPDIR/tmpfile

sed -i 's/\//_/g' $TMPDIR/tmpfile

postfix=$(cat ${TMPDIR}/tmpfile)

if [ -e $TMPDIR/patch_$postfix ];then
    rm -rf $TMPDIR/patch_$postfix
fi

mkdir -p $TMPDIR/patch_$postfix/info

git log --pretty=fuller $2 > $TMPDIR/patch_$postfix/info/log

echo $1 > $TMPDIR/patch_$postfix/info/branch
echo $2 > $TMPDIR/patch_$postfix/info/path_and_file
var=$2
echo ${var##*/} > $TMPDIR/patch_$postfix/info/file_name

sed -n '/^commit/p' $TMPDIR/patch_$postfix/info/log | cut -f 2 -d " " >$TMPDIR/patch_$postfix/info/all_commit
tac $TMPDIR/patch_$postfix/info/all_commit >$TMPDIR/patch_$postfix/info/all_commit_rev

let idx=0
cat $TMPDIR/patch_$postfix/info/all_commit_rev | while read commit
do
    mkdir -p $TMPDIR/patch_$postfix/${patch_dir[$idx]}/file
    git reset --hard $commit
    cp $2 $TMPDIR/patch_$postfix/${patch_dir[$idx]}/file
    git show $commit > $TMPDIR/patch_$postfix/info/temp_log
    sed -n '/^Author:/p' $TMPDIR/patch_$postfix/info/temp_log | cut -f 2 -d " " >$TMPDIR/patch_$postfix/${patch_dir[$idx]}/log_author
    sed -n '/^Date:   /p' $TMPDIR/patch_$postfix/info/temp_log | cut -f 4- -d " " >$TMPDIR/patch_$postfix/${patch_dir[$idx]}/log_time
    sed -n '/^Author:/p' $TMPDIR/patch_$postfix/info/temp_log | cut -f 2- -d "<" | cut -f 1 -d ">" > $TMPDIR/patch_$postfix/${patch_dir[$idx]}/email
    sed -n '/^Date:/,/^diff --git/p' $TMPDIR/patch_$postfix/info/temp_log | grep -v "^Date:" | grep -v "^diff --git" > $TMPDIR/patch_$postfix/${patch_dir[$idx]}/log
    sed -i 's/    //g' $TMPDIR/patch_$postfix/${patch_dir[$idx]}/log
    let idx+=1
done

git checkout $1
git branch -D temp
rm -rf $TMPDIR/tmpfile

#!/bin/bash

ORGDIR=$(pwd)
TMPDIR=$(dirname ${BASH_SOURCE[0]})

source $TMPDIR/rf2828_to_normal.sh

branch=$1

if [ -e $TMPDIR/tagspace ];then
    rm -rf $TMPDIR/tagspace
fi

mkdir -p $TMPDIR/tagspace

mkdir $TMPDIR/tagspace/$branch

git log $branch > $TMPDIR/tagspace/$branch/all_commit_log
sed -n '/^commit/p' $TMPDIR/tagspace/$branch/all_commit_log | cut -f 2 -d " " > $TMPDIR/tagspace/$branch/all_commit

git tag | while read t
do
    mkdir -p $TMPDIR/tagspace/tags/$t
    git show $t > $TMPDIR/tagspace/tags/$t/tag_context
    sed -n '/^Tagger:/p' $TMPDIR/tagspace/tags/$t/tag_context | cut -f 2 -d " " >$TMPDIR/tagspace/tags/$t/tagger
    sed -n '/^Date:   /p' $TMPDIR/tagspace/tags/$t/tag_context | sed -n '1p' |cut -f 4- -d " " >$TMPDIR/tagspace/tags/$t/tag_time
    sed -n '/^Date:   /p' $TMPDIR/tagspace/tags/$t/tag_context | sed -n '2p' |cut -f 4- -d " " >$TMPDIR/tagspace/tags/$t/bind_commit_time
    sed -n '/^Tagger:/p' $TMPDIR/tagspace/tags/$t/tag_context | cut -f 2- -d "<" | cut -f 1 -d ">" > $TMPDIR/tagspace/tags/$t/tagger_email
    sed -n '/^Tagger:/,/^commit/p' $TMPDIR/tagspace/tags/$t/tag_context |  grep -v "^Tagger:" | grep -v "^Date:" | grep -v "^commit" > $TMPDIR/tagspace/tags/$t/tag_log
    sed -i 's/    //g' $TMPDIR/tagspace/tags/$t/tag_log

    export rf2828_time=$(cat ${TMPDIR}/tagspace/tags/${t}/bind_commit_time)
    if [ "$rf2828_time" == "" ];then
        echo null time code...
        export rf2828_time=$(cat ${TMPDIR}/tagspace/tags/${t}/tag_time)
    fi
    rf2828_to_normal
    tag_bind_commit_time=$result

    cat $TMPDIR/tagspace/$branch/all_commit | while read commit
    do
        export rf2828_time=$(git show ${commit} | grep "^Date:" | cut -f 4- -d " ")
        rf2828_to_normal
        commit_time=$result
        echo tag_bind_commit_time=$tag_bind_commit_time
        echo commit_time=$commit_time
        if [ $tag_bind_commit_time -eq $commit_time ];then
            export GIT_AUTHOR_NAME=$(cat ${TMPDIR}/tagspace/tags/${t}/tagger)
            if [ "$GIT_AUTHOR_NAME" == "" ];then
                export GIT_AUTHOR_NAME=yourname
            fi 
            export GIT_AUTHOR_EMAIL=$(cat ${TMPDIR}/tagspace/tags/${t}/tagger_email)
            if [ "$GIT_AUTHOR_EMAIL" == "" ];then
                export GIT_AUTHOR_EMAIL=yourname@allwinnertech.com
            fi 
            export GIT_AUTHOR_DATE=$(cat ${TMPDIR}/tagspace/tags/${t}/tag_time)
            export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME
            export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
            export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE
            logs=$(cat ${TMPDIR}/tagspace/tags/${t}/tag_log)
            if [ "$logs" == "" ];then
                logs="for ${t}"
            fi 
            git tag -a $t -m "${logs}" $commit -f 
            break;
        fi
    done
done

#if [ -e $TMPDIR/tagspace ];then
#    rm -rf $TMPDIR/tagspace
#fi

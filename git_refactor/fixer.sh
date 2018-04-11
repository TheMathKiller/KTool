#!/bin/bash

ORGDIR=$(pwd)
TMPDIR=$(dirname ${BASH_SOURCE[0]})

echo ORGDIR=$ORGDIR
echo TMPDIR=$TMPDIR

source $TMPDIR/rf2828_to_normal.sh

if [ -e $TMPDIR/msg ];then
    rm -rf $TMPDIR/msg
fi

let branch_has_config=0
find $TMPDIR -maxdepth 1 -name "patch_*" | while read patch_come
do
    path_and_file=$(cat $patch_come/info/path_and_file)
    if [ $branch_has_config -eq 0 ];then
        branch=$(cat $patch_come/info/branch)
    fi
    file_name=$(cat $patch_come/info/file_name)

    git checkout -b ${branch}_c

    if [ $branch_has_config -ne 0 ];then
        git branch -D $branch
    fi

    let branch_has_config+=1
    
    echo path_and_file=$path_and_file

    git filter-branch --force --index-filter "git rm --cached --ignore-unmatch ${path_and_file} -r" --prune-empty  ${branch}_c

    for stage in $(ls -x $patch_come)
    do
        if [ $stage == info ];then
            continue
        fi

        echo start--------$stage
        patch_rf2828_time=$(cat $patch_come/$stage/log_time)
        export rf2828_time=$patch_rf2828_time
        rf2828_to_normal
        patch_time=$result

        if [ -e $TMPDIR/msg/${branch}_c ];then
            rm -rf $TMPDIR/msg/${branch}_c
        fi

        mkdir -p $TMPDIR/msg/${branch}_c
        git log ${branch}_c --pretty=fuller >$TMPDIR/msg/${branch}_c/all_msg
        sed -n '/^commit/p' $TMPDIR/msg/${branch}_c/all_msg | cut -f 2 -d " " >$TMPDIR/msg/${branch}_c/all_commit
        tac $TMPDIR/msg/${branch}_c/all_commit >$TMPDIR/msg/${branch}_c/all_commit_rev

        sed -n '/^AuthorDate:/p' $TMPDIR/msg/${branch}_c/all_msg | cut -f 2- -d : >$TMPDIR/msg/${branch}_c/all_date
        tac $TMPDIR/msg/${branch}_c/all_date >$TMPDIR/msg/${branch}_c/all_date_rev

        let idx=1
        cat $TMPDIR/msg/${branch}_c/all_date | while read date_c
        do
            export rf2828_time=$date_c
            rf2828_to_normal
            if [ $result -gt $patch_time ];then
                let idx+=1
                continue
            else
                #正数第一个不大于patch time的提交
                #reset回此提交-------------------->
                let jdx=1
                cat $TMPDIR/msg/${branch}_c/all_commit | while read commit_start
                do
                    if [ $jdx -lt $idx ];then
                        let jdx+=1
                        continue
                    fi
                    git reset --hard $commit_start
                    echo $commit_start > $TMPDIR/msg/${branch}_c/commit_start
                    break               
                done
                #<--------------------------------
                #打上patch,提交 ----------------->
                cp $patch_come/$stage/file/${file_name} ${path_and_file}
                if [ $? -ne 0 ];then
                    echo maybe copy dir not exist!!!!!!!!!
                    mkdir -p ${path_and_file}
                    rm -rf ${path_and_file}
                    cp $patch_come/$stage/file/${file_name} ${path_and_file}
                fi
                logs=$(cat $patch_come/$stage/log)

                export GIT_AUTHOR_NAME=$(cat $patch_come/$stage/log_author)
                export GIT_AUTHOR_EMAIL=$(cat $patch_come/$stage/email)
                export GIT_AUTHOR_DATE=$patch_rf2828_time
                export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME
                export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
                export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE

                git add .
                if [ $result -eq $patch_time ];then
                    echo e========
                    git commit --amend --no-edit
                else
                    echo no========e
                    git commit -m "$logs"
                fi
                #<----------------------------------
                #打上剩余补丁
                pick_left=0
                cat $TMPDIR/msg/${branch}_c/all_commit_rev | while read commit
                do
                    commit_start=$(cat $TMPDIR/msg/${branch}_c/commit_start)
                    echo commit=$commit
                    if [ $pick_left -eq 1 ];then
                        git cherry-pick $commit
                    fi
                    if [ $commit_start == $commit ];then
                        pick_left=1
                    fi
                done
                break
                #<----------------------------------
            fi
        done
        echo ----------end
    done

    rm -rf .git/refs/original/ && git filter-branch --env-filter 'GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE;export GIT_COMMITTER_DATE;GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME;export GIT_COMMITTER_NAME;GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL;export GIT_COMMITTER_EMAIL' ${branch}_c
    branch=${branch}_c
done

find $TMPDIR -maxdepth 1 -name "patch_*" | xargs rm -rf
rm -rf $TMPDIR/msg

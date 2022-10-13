#!/bin/bash

# run to copy all workflows from this dev repo to all other repos

# set which folder you're running from
cd -- "$(dirname "$BASH_SOURCE")"
cd ../..
tput reset

# remove mac files
rm -f crm-workflows-base/.github/workflows/.DS_Store
rm -f crm-workflows-base/.github/.DS_Store

# merge directly to master branches on all repos
for folder in * ; do
	cd $folder
	echo "Folder: "$folder

    #! don't update repos with other type of scripts
    if [[ $folder != crm-* || $folder == crm-platform-unpackaged  || $folder == crm-permset-changes || $folder == crm-utilities || $folder == crm-kafka-activity || $folder == crm-mellomvare-alerts $folder == crm-hot-referansedata $folder == ???|| $folder == crm-kafkarest]]; then
        echo "skipping" && echo ""
	    cd ..
        continue
    fi

	git stash >/dev/null 2>&1
	git checkout master >/dev/null 2>&1
	git stash >/dev/null 2>&1
	git pull >/dev/null 2>&1

	rm -rf .github/
    mkdir .github/
	cp -r ../crm-workflows-base/.github/* .github/

	git add .github/* >/dev/null 2>&1
	git commit -m "[AUTO] Updated Workflows" >/dev/null 2>&1
	git push origin master >/dev/null 2>&1

	cd ..
	echo ""
done
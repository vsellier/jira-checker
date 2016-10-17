#!/bin/bash

DATA_DIR=~/.jira/data

set -o pipefail

type jira > /dev/null || echo "Error, jira command is not declared in your path"

FOLLOWED="ITOP SWF"

TEMP_FILE=$(mktemp /tmp/jira.XXXX)

function separator() {
  echo "---------------------------------------------------------------------------"
}

function pressKey() {
  echo -n "Press enter to continue..."
  read
}

function getIssueIdsFromDiff() {
  local file=$1
  ISSUES=$(cut -b2- ${file} | cut -f1 -d":")
}

function getIssueIdsFromList() {
  local file=$1
  ISSUES=$(cut -f1 -d":" $file)
}

function loadAndDisplayIssue() {
  local i=$1

  separator
  jira $i > ${PROJECT_DIR}/$i.txt
  cat ${PROJECT_DIR}/$i.txt
}

function diffIssues() {
  local p=$1
  local dir=$2
  
  getIssueIdsFromList $dir/issues.lst

  for i in ${ISSUES}; do
    local comparable=false
    if [ -e ${PROJECT_DIR}/$i.txt ]; then
      comparable=true
      mv ${PROJECT_DIR}/$i.txt ${PROJECT_DIR}/$i.old
    fi
    jira $i > ${PROJECT_DIR}/$i.txt
    if [ $comparable ]; then
      diff ${PROJECT_DIR}/$i.old ${PROJECT_DIR}/$i.txt > ${TEMP_FILE}
      if [ -s ${TEMP_FILE} ]; then
        separator
        echo Changes on $i :
        cat ${TEMP_FILE}
        separator
        pressKey
      fi
    fi
  done
}


for p in ${FOLLOWED}
do
  PROJECT_DIR=${DATA_DIR}/$p
  INIT=0
  test -e ${PROJECT_DIR}/issues.lst || INIT=1
  separator
  echo Checking $p

  mkdir -p ${PROJECT_DIR}

  if [ ${INIT} -eq 0 ]; then
    rm -f ${PROJECT_DIR}/issues.old
    mv ${PROJECT_DIR}/issues.lst ${PROJECT_DIR}/issues.old
  fi

  jira ls -p $p -s "key" > ${PROJECT_DIR}/issues.lst

  if [ ${INIT} -eq 0 ]; then
    diff ${PROJECT_DIR}/issues.old ${PROJECT_DIR}/issues.lst | grep ">" > ${TEMP_FILE}
    if [ -s ${TEMP_FILE} ]; then
	echo "  New issues detected:"
	cat $TEMP_FILE
        pressKey
	getIssueIdsFromDiff $TEMP_FILE
	for i in ${ISSUES}
	do
          loadAndDisplayIssue $i
          pressKey
	done
    else
	echo "  No new issues"
    fi
    echo "  Checking issue updates..."
    diffIssues $p $PROJECT_DIR
  else
    echo Project initialized
  fi
done



rm ${TEMP_FILE}

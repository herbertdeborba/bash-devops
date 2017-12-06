#!/bin/bash

INSTANCIA="apache2"

MYDIR=`dirname $0`
. ${MYDIR}/custom-setup-${INSTANCIA}.sh

_append=""
if [[ -x ${CMD_CCZE} ]] ; then 
	_append=" | ${CMD_CCZE}"
fi 

${CMD_TAIL} -f ${AS_LOG_PATH}/logs/access_log ${AS_LOG_PATH}/logs/error_log ${_append}

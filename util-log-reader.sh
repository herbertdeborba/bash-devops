#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
	echo "Modo de usar: ${MYNME} -l <arquivo-log1 arquivo-log2> [-f]"
	echo "	-l <arquivo-log1 [arquivo-log2 ...]>: Um ou mais arquivos de log."
	echo "	-f (opcional) Monitora o log em tempo real."
}

appendtailf=""
logfiles=""
useccze="no"
instance="generic"
while getopts "l:i:fc" option ; do
	case "${option}" in
		l)
			logfiles=${OPTARG}
			#do_log "${logfiles}"
		;;
		f)
			appendtailf="-f"
		;;
		c)
			useccze="yes"
		;;
		i)
			instance=${OPTARG}
		;;
		?)
			set_error $ERR_INVALID_PARAMETER
			showusage
			exit $ERR_INVALID_PARAMETER
		;;
	esac
done

if [[ "x${logfiles}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
	exit $ERR_INVALID_PARAMETER
fi
	
if [[ ${instance} != "generic" ]] ; then
	inst_custom_script="${COMMONDIR}/custom/custom-setup-${instance}.sh"
	do_log "Customizando execucao para instancia \"${instance}\"..."
	if [[ -x ${inst_custom_script} ]] ; then
		do_log "Custom setup: \"${inst_custom_script}\"..."
		. "${inst_custom_script}"
	else
		do_log "Custom setup \"${inst_custom_script}\" nao encontrado."
	fi
fi

if [[ ${useccze} != "no" ]] ; then
	if [[ ! -x ${CMD_CCZE} ]] ; then 
		do_log "${STR_CMD_CCZE_NOTFOUND}"
		appendccze=""
	else
		appendccze=" | ${CMD_CCZE} ${CMD_CCZE_PARAM}"
	fi 
fi

do_intro "${STR_INTRO_UTIL_LOG_READER}"
set -f                      # avoid globbing (expansion of *).
array=(${logfiles// / })
for i in "${!array[@]}"
do
	afile=${array[i]}
	#do_log "$i: ${afile}"
	if [[ ! -e ${afile} ]] ; then
		do_log "${STR_ERR_LOGFILE_NOTFOUND}"
		#showusage
		do_exit ${ERR_FILE_OR_PATH_NOT_FOUND}
	fi
done

echo "Rodando: ${CMD_TAIL} ${appendtailf} ${logfiles} ${appendccze}"

eval "${CMD_TAIL} ${appendtailf} ${logfiles} ${appendccze}"

do_exit
#!/bin/bash

##
## Utiliza o sync-it para sincronizar de acordo com as configurações no custom/custom-setup.sh
##
## TJSC / DTI / DAD
## Secao de Sistemas Operacionais
## Autor: Herbert Mattei de Borba <herbert@tjsc.jus.br>
## 

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} [-v] -s <origem> -d <destino>"
  exit $(get_error)
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  set_error $ERR_ARGUMENT_NOT_FOUND
#  showusage
#fi

param_verbose=""
while getopts "vs:d:" option ; do
        case "${option}" in
                v)
					param_verbose="-v"
                ;;
                s)
					param_src=${OPTARG}
                ;;
                d)
					param_dest=${OPTARG}
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ "x${param_src}" == "x" ]] ; then 
	do_log "Parâmetro -s <origem> é obrigatório."
	showusage
fi 

if [[ "x${param_dest}" == "x" ]] ; then 
	do_log "Parâmetro -d <destino> é obrigatório."
	showusage
fi 


log_file="${LOG_PATH}/sync-me-local-${SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPREC}.log"

exclude_expr="custom/"

${MYDIR}/sync-it.sh -s ${param_src} -d ${param_dest} ${param_verbose} -l ${log_file} ${exclude_expr}

exit $(get_error)

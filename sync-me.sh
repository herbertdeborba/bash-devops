#!/bin/bash

##
## Utiliza o sync-it para sincronizar de acordo com as configurações no custom/custom-setup.sh
##
## TJSC / DTI / DAD
## Secao de Sistemas Operacionais
## Autor: Herbert Mattei de Borba <herbert@tjsc.jus.br>
##
## v2
## 

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME}"
  exit ${ERROR}
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  set_error $ERR_ARGUMENT_NOT_FOUND
#  showusage
#fi

param_verbose=""
while getopts "v" option ; do
        case "${option}" in
                v)
					param_verbose="-v"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

log_file="${LOG_PATH}/sync-me-${SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPREC}.log"

exclude_expr="custom/"

${MYDIR}/sync-it.sh -h ${SYNC_HOST} -s ${SYNC_SRC} -u ${SYNC_USR} -b ${SYNC_BKP} -l ${log_file} -x ${exclude_expr} ${param_verbose} 

exit $ERROR

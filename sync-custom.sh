#!/bin/bash

##
## Utiliza o sync-it para sincronizar de acordo com as configurações no custom/custom-setup.sh
##
## TJSC / DTI / DAD
## Secao de Sistemas Operacionais
## Autor: Herbert Mattei de Borba <herbert@tjsc.jus.br>
##
## v2.0 201710101615
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

log_file="${LOG_PATH}/sync-custom-${SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPREC}.log"

${MYDIR}/sync-it.sh -h ${CUSTOM_SYNC_HOST} -s ${CUSTOM_SYNC_SRC} -u ${CUSTOM_SYNC_USR} -b ${CUSTOM_SYNC_BKP} -l "${log_file}"

exit $ERROR

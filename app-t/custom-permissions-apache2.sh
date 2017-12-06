#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

if [[ ${COMMON_SETUP_VERIF} == "" ]] ; then echo "Este script nao deve ser executado diretamente." ; exit ; fi

INSTANCE_NAME=$(get_instance_from_filename ${BASH_SOURCE[0]})
#INSTANCE_NAME="apache2"

_custom_instance_setup_file=${COMMONDIR}/custom/custom-setup-${INSTANCE_NAME}.sh
if [ -x ${_custom_instance_setup_file} ] ; then 
	. ${_custom_instance_setup_file}
fi

do_log "Permissoes customizadas para ${INSTANCE_NAME}"
do_log
do_log "AS_BASE_PATH: ${AS_BASE_PATH}"
do_log "AS_BIN_PATH: ${AS_BIN_PATH}"
do_log "LOG PATH: ${AS_LOG_PATH}"

#do_chown ${ADM_USER} ${AS_GROUP} ${AS_BASE_PATH} -R
#do_chmod "u=rwx,g=rwx,o=rx" ${AS_BASE_PATH} -R

${CMD_CHOWN} -R ${ADM_USER}:${DEV_GROUP} ${AS_BASE_PATH}
${CMD_CHMOD} -R "u=rwx,g=rx,o=" ${AS_BASE_PATH}

${CMD_CHOWN} -R ${ADM_USER}:${DEV_GROUP} ${AS_LOG_PATH}/
${CMD_CHMOD} -R "u=rwx,g=rx,o=rx" ${AS_LOG_PATH}/

${CMD_CHOWN} -R ${DEV_USER}:${DEV_GROUP} ${AS_BASE_PATH}/htdocs/
${CMD_CHMOD} -R "u=rwx,g=rwx,o=rx" ${AS_BASE_PATH}/htdocs/

#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

echo
echo "AS_USER=$AS_USER ADM_GROUP=$ADM_GROUP DEV_GROUP=$DEV_GROUP"
echo "Seus grupos: $(id -nG $SUDO_USER)"
echo
echo "Ajustando permissoes de filesystem."
echo 

sysadm_scripts="*.sh custom/*.sh"
#sysadm_scripts=("common-permissions.sh" "common-setup.sh" "daemon-clean.sh" "daemon-init.sh" "daemon-restart.sh" "daemon-start.sh" "daemon-status.sh" "daemon-stop.sh" "network-block.sh" "sync-custom.sh" "sync-it.sh" "sync-me.sh" "sync-me-local.sh" "sync-root.sh" "tomcat-clean.sh" "tomcat-list.sh" "util-block-port.sh" "util-copy-files.sh" "util-log-monitor.sh" "util-swap-files.sh")
devadm_scripts="custom/daemon-logs*"

### Scripts /opt/devops ou seja la o que COMMONDIR for em common-setup.sh
verif_sensible_target ${COMMONDIR}
# Sysadm all
#chown -h -R ${ADM_USER}:${ADM_GROUP} .
do_chown ${ADM_USER} ${ADM_GROUP} ${COMMONDIR} "-h -R"
#chmod -R 755 .
do_chmod 755 ${COMMONDIR} "-R"
#chmod 750 ${sysadm_scripts}
do_chmod 750 ${COMMONDIR}/
do_chmod 750 ${COMMONDIR}/custom/

## Devadm some
pushd ${COMMONDIR} >/dev/null
do_chown ${ADM_USER} ${DEV_GROUP} ${COMMONDIR}

$CMD_CHOWN -h ${ADM_USER}:${DEV_GROUP} ${devadm_scripts}
$CMD_CHMOD 750 ${devadm_scripts}

$CMD_CHOWN -h ${ADM_USER}:${DEV_GROUP} custom

$CMD_CHOWN -h ${ADM_USER}:${DEV_GROUP} custom/custom-setup*
$CMD_CHMOD 750 custom/custom-setup*

$CMD_CHOWN -h ${ADM_USER}:${DEV_GROUP} custom/msg*
$CMD_CHMOD 750 custom/msg*
popd >/dev/null

make_dir_if_not_exists ${COMMONDIR_AUX}
do_chown ${ADM_USER} ${ADM_GROUP} ${COMMONDIR_AUX} "-h -R"

make_dir_if_not_exists ${SYNC_BKP}
do_chown ${ADM_USER} ${ADM_GROUP} ${SYNC_BKP} "-h -R"

make_dir_if_not_exists ${ROOT_SYNC_BKP}
do_chown ${ADM_USER} ${ADM_GROUP} ${ROOT_SYNC_BKP} "-h -R"

make_dir_if_not_exists ${CUSTOM_SYNC_BKP}
do_chown ${ADM_USER} ${ADM_GROUP} ${CUSTOM_SYNC_BKP} "-h -R"

make_dir_if_not_exists ${LOG_PATH}
do_chown ${ADM_USER} ${ADM_GROUP} ${LOG_PATH} "-h -R"

IFS=$OIFS

## Não dá pra botar no geral a seguir para garantir que  este deve ser 
## executado antes dos outros 
custom_permissions_file="${COMMONDIR}/custom/custom-permissions.sh"
if [[ -e "${custom_permissions_file}" ]] ; then 
	do_log "Executando \"$custom_permissions_file\"..."
	. ${COMMONDIR}/custom/custom-permissions.sh
fi

## Chama qualquer arquivo de custom permissions que haja no custom
for custom_permissions_instance in ${COMMONDIR}/custom/custom-permissions-*.sh; do
	if [[ -x "$custom_permissions_instance" ]] ; then
		do_log "Executando \"$custom_permissions_instance\"..."
		. $custom_permissions_instance
	else
		do_log "Não foi possivel fazer uma chamada para \"$custom_permissions_instance\". Verifique se o arquivo tem permissao de execucao."
	fi
done

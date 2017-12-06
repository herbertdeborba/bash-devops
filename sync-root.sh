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
	echo "Modo de usar: ${MYNME} [-a] [-p] [-s] [-u] [-c] [-i] [-v]"
	echo "	-v: (opcional) verbose, mostra mais informacoes."
	echo "	-p: (opcional) profile, sincroniza \"/etc/profile.d/startup-sys-user.sh\"."
	echo "	-s: (opcional) sudoers, sincroniza \"/etc/sudoers.d/startup-sys-sudoers\"."
	echo "	-u: (opcional) arquivo sudoers, sincroniza \"/etc/sudoers\". CUIDADO! Um sudoers mal formatado pode deixar o sistema inacessivel."
	echo "	-c: (opcional) cron, sincroniza \"/etc/cron.d/startup-sys-crontab\"."
	echo "	-i: (opcional) iptables, sincroniza \"/etc/init.d/iptables\"."
	echo "	-a: (opcional) sincroniza todos, exceto \"/etc/suoders\" e \"/etc/init.d/iptables\" que demandam parametros explícitos."
	exit ${ERROR}
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  set_error $ERR_ARGUMENT_NOT_FOUND
#  showusage
#fi

param_verbose=""
param_profile="nao"
param_sudoers="nao"
param_sudoersfile="nao"
param_cron="nao"
param_iptables="nao"
param_all="nao"
detected_parm="nao"
while getopts "vpsucia" option ; do
        case "${option}" in
                v)
					param_verbose="-v"
                ;;
                p)
					param_profile="sim"
					detected_parm="sim"
                ;;
                s)
					param_sudoers="sim"
					detected_parm="sim"
                ;;
                c)
					param_cron="sim"
					detected_parm="sim"
                ;;
                i)
					param_iptables="sim"
					detected_parm="sim"
                ;;
                u)
					param_sudoersfile="sim"
					detected_parm="sim"
                ;;
                a)
					param_all="sim"
					detected_parm="sim"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ ${detected_parm} == "sim" ]] ; then
	if [[ ${param_all} == "sim" ]] || [[ ${param_profile} == "sim" ]] ; then
		SYNC_SRC="/etc/profile.d/startup-sys-user.sh"
		log_file="${LOG_PATH}/sync-root-${ROOT_SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPRECPREC}.log"
		${MYDIR}/sync-it.sh -h ${ROOT_SYNC_HOST} -s ${SYNC_SRC} -u ${ROOT_SYNC_USR} -b ${ROOT_SYNC_BKP} -l ${log_file}
	fi

	if [[ ${param_all} == "sim" ]] || [[ ${param_sudoers} == "sim" ]] ; then
		SYNC_SRC="/etc/sudoers.d/startup-sys-sudoers"
		log_file="${LOG_PATH}/sync-root-${ROOT_SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPRECPREC}.log"
		${MYDIR}/sync-it.sh -h ${ROOT_SYNC_HOST} -s ${SYNC_SRC} -u ${ROOT_SYNC_USR} -b ${ROOT_SYNC_BKP} -l ${log_file}
	fi
	
	if [[ ${param_sudoersfile} == "sim" ]] ; then
		SYNC_SRC="/etc/sudoers"
		log_file="${LOG_PATH}/sync-root-${ROOT_SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPRECPREC}.log"
		${MYDIR}/sync-it.sh -h ${ROOT_SYNC_HOST} -s ${SYNC_SRC} -u ${ROOT_SYNC_USR} -b ${ROOT_SYNC_BKP} -l ${log_file}
	fi
	
	if [[ ${param_iptables} == "sim" ]] ; then
		SYNC_SRC="/etc/init.d/iptables"
		log_file="${LOG_PATH}/sync-root-${ROOT_SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPRECPREC}.log"
		${MYDIR}/sync-it.sh -h ${ROOT_SYNC_HOST} -s ${SYNC_SRC} -u ${ROOT_SYNC_USR} -b ${ROOT_SYNC_BKP} -l ${log_file}
	fi

	if [[ ${param_all} == "sim" ]] || [[ ${param_cron} == "sim" ]] ; then
		SYNC_SRC="/etc/cron.d/startup-sys-crontab"
		log_file="${LOG_PATH}/sync-root-${ROOT_SYNC_HOST}-${SYNC_SRC//\//^}-${DATAHORAHJPRECPREC}.log"
		${MYDIR}/sync-it.sh -h ${ROOT_SYNC_HOST} -s ${SYNC_SRC} -u ${ROOT_SYNC_USR} -b ${ROOT_SYNC_BKP} -l ${log_file}
	fi
else
	do_log "Parametro de sincronizacao nao detectado."
	do_log "Utilize ao menos um parametro documentado."
	showusage
fi

exit $(get_error)

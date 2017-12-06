#!/bin/bash

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} [-r]"
  echo "	O comportamento padrao e update, copia apenas o que e mais novo. Ver -o abaixo."
  echo "	-o: (opcional) overwrite. Sobrescreve tudo. CUIDADO!"
  echo "	-r: (opcional) modo reverso, substitui os arquivos do sistema. CUIDADO!"
  exit ${ERROR}
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  set_error $ERR_ARGUMENT_NOT_FOUND
#  showusage
#fi


param_reverse="nao"
str_update="-u"
while getopts "ro" option ; do
        case "${option}" in
				o)
					str_update=""
				;;
                r)
					param_reverse="sim"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done


if [[ "x$param_reverse" == "xnao" ]] ; then 
	echo "Os arquivos atualizados serao listados a seguir. Caso nada seja listado, nada foi atualizado."
	make_dir_if_not_exists ${COMMONDIR}/custom/root/etc/profile.d/
	make_dir_if_not_exists ${COMMONDIR}/custom/root/etc/sudoers.d/
	make_dir_if_not_exists ${COMMONDIR}/custom/root/etc/cron.d/

	cp ${str_update} --preserve=timestamps -v /etc/crontab /etc/sudoers /etc/passwd /etc/group /etc/profile ${COMMONDIR}/custom/root/etc/

	cp ${str_update} --preserve=timestamps -v /etc/profile.d/* ${COMMONDIR}/custom/root/etc/profile.d/
	cp ${str_update} --preserve=timestamps -v /etc/sudoers.d/* ${COMMONDIR}/custom/root/etc/sudoers.d/
	cp ${str_update} --preserve=timestamps -v /etc/cron.d/* ${COMMONDIR}/custom/root/etc/cron.d/
elif [[ "x$param_reverse" == "xsim" ]] ; then
	echo ""
	if [[ "x$str_update" == "x-u" ]] ; then
		str_ovw_upd="ATUALIZAR"
	else
		str_ovw_upd="SOBRESCREVER"
	fi
	echo "Isso vai ${str_ovw_upd}  arquivos de sistema deste servidor pelos da pasta '${COMMONDIR}/custom/root/etc/'."
	echo "Por favor, continue apenas se souber o que está fazendo!"
	echo ""
	read -p "Confirma? (s/n) " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Ss]$ ]]
	then
		do_log "Abortando operação."
		exit 1
	fi
	
	bak_time=$(get_now_for_log)
	bak_dir="${COMMONDIR_AUX}/backup/scripts/root/${bak_time}"
	
	do_log ""
	do_log "Armazenando backups EM '${bak_dir}'"
	do_log ""
	
	make_dir_if_not_exists "${bak_dir}/etc"
	cp /etc/crontab /etc/sudoers /etc/passwd /etc/group "${bak_dir}/etc"
	
	make_dir_if_not_exists "${bak_dir}/etc/profile.d"
	make_dir_if_not_exists "${bak_dir}/etc/sudoers.d"
	make_dir_if_not_exists "${bak_dir}/etc/cron.d"
	
	cp /etc/profile.d/* "${bak_dir}/etc/profile.d/"
	cp /etc/sudoers.d/* "${bak_dir}/etc/sudoers.d/"
	cp /etc/cron.d/* "${bak_dir}/etc/cron.d/"
	
	cp ${str_update} --preserve=timestamps -i -v ${COMMONDIR}/custom/root/etc/crontab ${COMMONDIR}/custom/root/etc/sudoers ${COMMONDIR}/custom/root/etc/passwd ${COMMONDIR}/custom/root/etc/group /etc/
	cp ${str_update} --preserve=timestamps -i -v ${COMMONDIR}/custom/root/etc/profile.d/* /etc/profile.d/
	cp ${str_update} --preserve=timestamps -i -v ${COMMONDIR}/custom/root/etc/sudoers.d/* /etc/sudoers.d/
	cp ${str_update} --preserve=timestamps -i -v ${COMMONDIR}/custom/root/etc/cron.d/* /etc/cron.d/
fi

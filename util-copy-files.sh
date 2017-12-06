#!/bin/bash

# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} -s <arquivo-origem> -d <arquivo-destino> [-t <path/nome-temporario>]"
  echo "	-s <arquivo-1>: arquivo 1."
  echo "	-d <arquivo-2>: arquivo 2."
  echo "	-f (opcional) Força a realização da permuta mesmo com erros encontrados (use com cuidado)."
  echo "	-t <path/nome-temporario>: (opcional) path e nome do temporario. Caso nao seja informado sera utilizado \"${TEMP_PATH}/swap-<arquivo-1>-<arquivo-2>-{datahora}.temp\"."
  exit ${ERROR}
}

ARGV=${@}
if [ "x$ARGV" = "x" ] ; then
  set_error $ERR_ARGUMENT_NOT_FOUND
  showusage
fi

opt_send_mail="sim"
force_permuta="nao"
origem=""
destino=""
pathnmtmp=""

while getopts "s:d:t:mf" option ; do
        case "${option}" in
                s)
					origem=${OPTARG}
                ;;
                d)
					destino=${OPTARG}
                ;;
                t)
					pathnmtmp=${OPTARG}
                ;;
                m)
					opt_send_mail="nao"
                ;;
				f)
					force_permuta="sim"
				;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ "x${origem}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
else 
	if [[ ! -e ${origem} ]] ; then
		do_log "Arquivo \"${origem}\" nao foi encontrado."
		showusage
	fi
fi

if [[ "x${destino}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
else
	if [[ ! -e ${destino} ]] ; then
		do_log "Arquivo \"${destino}\" nao foi encontrado."
		showusage
	fi
fi

if [[ "x${pathnmtmp}" == "x" ]] ; then
	datahoraexec=$(get_now_for_log)
	origemesc=$(echo ${origem} | sed 's/\//\%/g')
	destinoesc=$(echo ${destino} | sed 's/\//\%/g')
	pathnmtmp="${TEMP_PATH}/swap-${origemesc}-${destinoesc}-${datahoraexec}.temp"
fi

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Utilitário para permuta de nomes de arquivos."
do_log "Usuário: ${USRDATA}"

function do_swap {
	do_log "Permutando nome de arquivos..."
	do_log "Arquivo 1: ${origem}"
	do_log "Arquivo 2: ${destino}"
	#do_log "TmpFile: ${pathnmtmp}"
	#echo "Pararia se teste nao fosse... ${CMD_CUSTOM_START}"
	
	do_log "Fazendo backup dos arquivos..."
	backup_orig_path_and_file="${SYNC_BKP_SWAP}/${origem}-${datahoraexec}"
	make_dir_if_not_exists $(dirname "${backup_orig_path_and_file}") 
	cp ${origem} ${backup_orig_path_and_file}
	if [ $? -eq 0 ] ; then
		do_log "Backup do arquivo 1 realizado em \"${backup_orig_path_and_file}\"."
	else
		do_log "Backup do arquivo 1 em \"${backup_orig_path_and_file}\" nao pode ser realizado."
		if [[ "x${force_permuta}" == "xnao" ]] ; then 
			do_log "Abortando permuta. Para forçar, utilize \"-f\"".
			do_log "$(get_now) Procedimento '${MYNME}' abortado."
			exit ${ERR_FILE_OR_PATH_NOT_FOUND}
		else
			do_log "ATENCAO: parâmetro \"-f\" utilizado, forçando realização da permuta mesmo sem backup!"
		fi
	fi
	backup_dest_path_and_file="${SYNC_BKP_SWAP}/${destino}-${datahoraexec}"
	make_dir_if_not_exists $(dirname "${backup_dest_path_and_file}") 
	cp ${destino} ${backup_dest_path_and_file}
	if [ $? -eq 0 ] ; then
		do_log "Backup do arquivo 2 realizado em \"${backup_dest_path_and_file}\"."
	else 
		do_log "Backup do arquivo 2 em \"${backup_dest_path_and_file}\" nao pode ser realizado."
		if [[ "x${force_permuta}" == "xnao" ]] ; then 
			do_log "Abortando permuta. Para forçar, utilize \"-f\"".
			do_log "$(get_now) Procedimento '${MYNME}' abortado."
			exit ${ERR_FILE_OR_PATH_NOT_FOUND}
		else
			do_log "ATENCAO: parâmetro \"-f\" utilizado, forçando realização da permuta mesmo sem backup!"
		fi
	fi

	cp ${origem} ${pathnmtmp}
	if [ $? -ne 0 ] ; then
		do_log "Copia do arquivo 1 para \"${pathnmtmp}\" não pode ser realizada, procedimento abortado."
		do_log "$(get_now) Procedimento '${MYNME}' abortado."
		exit ${ERR_FILE_OR_PATH_NOT_FOUND}
	fi
	cp ${destino} ${origem}
	if [ $? -ne 0 ] ; then
		do_log "Copia do arquivo 2 para \"${origem}\" não pode ser realizada, procedimento abortado."
		do_log "$(get_now) Procedimento '${MYNME}' abortado."
		exit ${ERR_FILE_OR_PATH_NOT_FOUND}
	else 
		do_log "Copia do arquivo 2 para \"${origem}\" realizada com sucesso."
	fi
	cp ${pathnmtmp} ${origem}
	if [ $? -ne 0 ] ; then
		do_log "Copia do arquivo auxiliar para \"${origem}\" não pode ser realizada, o procedimento falhou."
		do_log "$(get_now) Procedimento '${MYNME}' abortado."
		exit ${ERR_FILE_OR_PATH_NOT_FOUND}
	else
		do_log "Copia do arquivo 1 para \"${destino}\" realizada com sucesso."
	fi
}

###
### RUN 
###

do_swap

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

if [[ "x${opt_send_mail}" == "xsim" ]] ; then
	$(send_email "Permuta de arquivos")
fi

exit $(get_error)

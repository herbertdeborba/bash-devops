#!/bin/bash

##
## Script para sincronizacao de diretorios entre servidores
## Sincroniza arquivos e detecta modificacoes, aleterando o valor
## da saida do script para que se programe procedimentos extras
## caso necessario.
##
## TJSC / DTI / DAD
## Secao de Sistemas Operacionais
## Autor: Herbert Mattei de Borba <herbert@tjsc.jus.br>
## Data release 1: 01/02/2013
## Data release 2: 30/09/2013
## Data release 3: 21/09/2015 sync_me
## Data release 4: 25/04/2016 -x 
## Data release 5: 01/10/2017 ajustes data e hora com nanosegundos
## 

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo
  echo "Modo de usar: ${MYNME} -h <host|ip origem> -s <source_folder> [-d <dest_folder>] -u <username> [-p <password>] [-b /path/para/backup] [-l <log_file>] [-q] [-m]"
  echo "	-h <host|ip origem|destino>: Origem dos dados a serem sincronizados. Se for utilizada a opção -r se refere ao destino."
  echo "	-s <source_folder>: Pasta origem da cópia dos arquivos."
  echo "	-d <dest_folder>: (opcional) Pasta destino a ser sincronizada. Se não houver, a pasta origem deve levar em conta o path completo, que será replicado."
  echo "	-u <username>: Nome de usuário a ser utilizado na sincronização."
  echo "	-p <password>: (opcional) Senha para o usuário <username> passado no parâmetro anterior. Padrão: se necessário, a senha será solicitada na transferencia."
  echo "	-b <backup_path>: (opcional) Path para backup. "
  echo "	-l <log_file>: (opcional) Path e nome de arquivo para log customizado. Inibe o log padrão."
  echo "	-q: (opcional) Quieto. não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
  echo "	-m [<custom>]: (opcional) Sem email OU e-mails para destino customizado."
  echo "	-x: (opcional) Excluir. pastas para não sincronizar, separadas por \":\"."
  echo "	-r: (opcional) Reverso. Faz push no host remoto."
  echo "	-n: (opcional) Ativa o modo de debug, pode ser utilizado com -v para prever alterações que serão realizadas sem efetivá-las."
  echo "	-e: (opcional) Passa parametos extras para o comando rsync"
  echo
  exit ${ERROR}
}

ARGV=${@}
if [ "x$ARGV" = "x" ] ; then
  set_error $ERR_ARGUMENT_NOT_FOUND
  showusage
fi

MUDOUALGO="Inicial----"

param_host=""
param_usr=""
param_pwd=""
param_src=""
param_dest=""
param_dir_bak="${COMMONDIR_AUX}/backup/sync_$(get_now_for_log)"
param_exclude=".*.swp"
param_verbose="nao"
param_reverse="nao"
param_debug="nao"
extra_parms=""

log_set="nao"
opt_send_mail="sim"

while getopts "h:s:d:u:p:l:b:x:nrqm:ve" option ; do
        case "${option}" in
		h)
					param_host=${OPTARG}
                ;;
                s)
					param_src=${OPTARG}
                ;;
                d)
					param_dest=${OPTARG}
                ;;
                u)
					param_usr=${OPTARG}
                ;;
                p)
					param_pwd=${OPTARG}
                ;;
                l)
					set_custom_log ${OPTARG}
					log_set="sim"
                ;;
                b)
					param_dir_bak=${OPTARG}
                ;;
                x)
					param_exclude="${param_exclude}:${OPTARG}"
                ;;
                n)
					param_debug="sim"
                ;;
                r)
					param_reverse="sim"
                ;;
                q)
					set_run_log "nao"
                ;;
                m)
					if [[ ${OPTARG} == ""  ]] ; then
						opt_send_mail="nao"
					else
						set_email_to ${OPTARG}
					fi
                ;;
                v)
					param_verbose="sim"
                ;;
                e)
                                        extra_parms=${OPTARG}
                ;;

		*)
			set_error $ERR_INVALID_PARAMETER
			showusage
		;;
		esac
done

#DTETME="$(get_now_for_log)"
DTETME="$(get_precision_date)"
DTETMER="$(get_now)"

if [[  "x$param_src" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
fi

opt_local="nao"
if [[ "x${param_host}" == "x" ]] ; then
	do_log "  ERRO: Host remoto não informado. Usando sincronização local."
	opt_local="sim"
	
	if [[  "x$param_dest" == "x" ]] ; then
		do_log "  ERRO: Na sincronização local, é necessário informar um destino."
		set_error $ERR_ARGUMENT_NOT_FOUND
		showusage
	fi
else
	if [[ "x${param_usr}" == "x" ]] ; then
		do_log "  ERRO: Na sincronização remota, é necessário informar um nome de usuário."
		set_error $ERR_ARGUMENT_NOT_FOUND
		showusage
	fi
	if [[  "x$param_dest" == "x" ]] ; then
		param_dest=$param_src
	fi
fi

if [[  "x$param_pwd" == "x" ]] ; then
	param_pwd="nopwd"
fi

if [[ log_set == "nao" ]] ; then 
	set_custom_log "${LOG_PATH}/sync-${RMTDIR//\//_}-${DTETME}.log"
fi

if [[ "$param_reverse" != "sim" ]] ; then
	make_dir_if_not_exists $param_dest
fi

#if [[ ! -d $param_dir_bak ]] ; then
#	do_log "Path de backup inválido. \"$param_dir_bak\" não é um diretório?"
#	set_error $ERR_INVALID_PARAMETER
#	showusage
#fi

day_sync_log="$(get_log_path)/${MYNME}-$(get_day_for_log).log"

do_log "===================================================================="
do_log " SYNC DATA/HORA: ${DTETMER} "
do_log "===================================================================="
do_log " Origem: ${param_src}"
do_log " Destino: ${param_dest}"
do_log " Backup dir: ${param_dir_bak}"
do_log " Usuario remoto: ${param_usr}"
do_log " Host remoto: ${param_host}"
do_log " Nao sincronizar: ${param_exclude}"
do_log " Log da operação: $(get_log_output)"
do_log "   O log da operação será mantido apenas se houver alterações"
do_log "   Todos os logs serão mantidos no log diário."
do_log " Log diário: ${day_sync_log}"
do_log "--------------------------------------------------------------------"


function syncit {
	#$param_src $param_dest $param_dir_bak $param_usr $param_pwd $param_host $param_exclude
	## Dir local
	RMTDIR=$param_src
	## Dir remoto
	LOCDIR=$param_dest
	## Dir backup
	BKPDIR=$param_dir_bak
	#make_dir_if_not_exists ${BKPDIR}
	## Usuario remoto
	RMTUSR=$param_usr
	## Password remoto
	RMTPWD=$param_pwd
	## Servidor remoto
	RMTSRV=$param_host
	## Pastas a serem excluidas do sync
	if [[ "x${param_exclude}" != "x"  ]] ; then
		IN=${param_exclude}
		OIFS=$IFS
		IFS=':'
		arr2=$IN
		EXCXPR=""
		for excfld in $arr2
		do
			EXCXPR="${EXCXPR} --exclude=${excfld}"
		done
		IFS=$OIFS
	fi

	str_ssh="'/usr/bin/ssh -l ${RMTUSR}'"
	if [[ $RMTPWD != "nopwd" ]] ; then
		# /usr/bin/sshpass -p Sso12TJ@sc ssh -o StrictHostKeyChecking=no sso@services-dev
		str_ssh="'/usr/bin/sshpass -p ${RMTPWD} /usr/bin/ssh -o StrictHostKeyChecking=no -l ${RMTUSR}'"
	fi
	
	str_debug=""
	str_result_mod="Foram "
	str_result_debug=""
	if [[ $param_debug == "sim" ]] ; then
		str_result_debug="Rodando em modo debug. "
		str_result_mod="${str_result_debug}Seriam "
		str_debug=" -n"
	fi

	##
	## Comeca os procedimentos de  SYNC
	##

	if [[ "$opt_local" != "sim" ]] ; then
		if [[ "$param_reverse" != "sim" ]] ; then
			CMD_RSYNC="/usr/bin/rsync ${EXCXPR} -F -b --delete-before --backup-dir=${BKPDIR}/sync_remote_${DTETME} --stats -rptgoD -zve ${str_ssh} ${RMTSRV}:${RMTDIR} ${LOCDIR} ${str_debug}"
		else
			CMD_RSYNC="/usr/bin/rsync ${EXCXPR} -F -b --delete-before --backup-dir=${BKPDIR}/sync_remote_${DTETME} --stats -rptgoD -zve ${str_ssh} ${LOCDIR} ${RMTSRV}:${RMTDIR} ${str_debug}"
		fi
	else
		if [[ "$param_reverse" != "sim" ]] ; then
			CMD_RSYNC="/usr/bin/rsync ${EXCXPR} -F -b --delete-before --backup-dir=${BKPDIR}/sync_local_${DTETME} --stats -rptgoD -zv ${RMTDIR} ${LOCDIR} ${str_debug}"
		else
			CMD_RSYNC="/usr/bin/rsync ${EXCXPR} -F -b --delete-before --backup-dir=${BKPDIR}/sync_local_${DTETME} --stats -rptgoD -zv ${LOCDIR} ${RMTDIR} ${str_debug}"
		fi
		
	fi

	if [[ ${extra_parms} != "" ]] ; then 
		CMD_RSYNC="${CMD_RSYNC} ${extra_parms}"
	fi

	if [ $param_verbose == "sim" ] ; then 
	  do_log ""
	  do_log "Comando de sincronização:"
	  eval "do_log \"CMD_RSYNC: ${CMD_RSYNC}\""
	  do_log ""
	fi 

	if [[ $param_verbose == "sim" ]] ; then 
		eval ${CMD_RSYNC} | ${CMD_TEE_APPEND} $(get_log_output)
	else
		eval ${CMD_RSYNC} >> $(get_log_output)
	fi

	NUMFTX=`cat $(get_log_output) | grep ".* files transferred:" | sed 's/.* files transferred: \(.*\)$/\1/'`
	NUMDEL=`cat $(get_log_output) | grep deleting | wc -l`
	
	

	do_log ""
	do_log "${str_result_mod}deletados: ${NUMDEL} arquivos ou pastas."
	do_log "${str_result_mod}transferidos: ${NUMFTX} arquivos ou pastas."
	do_log ""

	MUDOUALGO="nao"
	## Sobre a utilizacao de dois colchetes:
	## http://stackoverflow.com/questions/13781216/bash-meaning-of-too-many-arguments-error-from-if-square-brackets
	#echo "Debug: NUMFTX=${NUMFTX}, NUMDEL=${NUMDEL}"
	if [[ "g${NUMFTX}" != "g" ]] && [[ "g${NUMDEL}" != "g"  ]] && [[ ${NUMFTX} -gt 0 ]] || [[ ${NUMDEL} -gt 0 ]] ; then
		MUDOUALGO="sim"
		#do_log "Alteracoes detectadas."
	else
		do_log "Nao houveram mudancas. "
	fi

	if [ -s "$(get_log_output)ERR" ] ; then
		cat "$(get_log_output)ERR" >> $(get_log_output)
	else
		do_log "Não foram encontrados erros no procedimento."
	fi

	if [ ${MUDOUALGO} == "sim" ] ; then 
		#mail ${EMAILTO} -s "[BACKUP] Alteracoes Detectadas ${SYNNME}" -aFrom:${EMAILREPLY} < "${LOGTMP}" 2>/dev/null
		do_log "${str_result_mod}encontradas alterações."
	fi

	if [ -e "$(get_log_output)ERR" ] ; then 
		rm "$(get_log_output)ERR"
	fi
	if [ -e "$(get_log_output)ERR_EMAIL" ] ; then 
		rm "$(get_log_output)ERR_EMAIL"
	fi
}

SYNC_HOST_CAPS_HOST=$(echo ${param_host%%.*} | awk '{print toupper($0)}')

if [[ ${SYNC_HOST_CAPS_HOST} != ${SERVERNAME} ]] ; then 
	syncit
else
	do_log "ERRO: Host de sincronização é o mesmo que o script está sendo executado?"
	do_log "Host de sincronização: ${param_host}"
	do_log "Host atual: ${SERVERNAME}"
	do_log "Sincronização abortada."
	opt_send_mail="nao"
	set_error ${ERR_INVALID_PARAMETER}
fi

if [[ ${MUDOUALGO} != "sim" ]] ; then 
	do_log "Como não foram detectadas alterações, o log da operação será"
	do_log "removido, mantendo-se apenas o log diário. O diretório de backup"
	do_log "não utilizado também será eliminado."
else
	do_log "Os arquivos modificados foram mantidos no diretório de backup:"
	do_log "  $param_dir_bak"
fi

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

touch $day_sync_log

cat $(get_log_output) >> $day_sync_log

if [[ ${MUDOUALGO} != "sim" ]] ; then 
	rm -rf $param_dir_bak
	rm -rf $(get_log_output)
else 
	if [[ "x${opt_send_mail}" == "xsim" ]] ; then
		$(send_email "Sincronizacao de $param_host:$param_src")
	fi
fi


exit $(get_error)

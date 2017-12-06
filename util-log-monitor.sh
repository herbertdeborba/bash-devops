#!/bin/bash

##
## MONITORADOR DE LOG
## 
## Utilitario de monitoramento de log.
##
### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
	echo "Modo de usar: ${MYNME} -e <expressão> -L <log_file> [-t <timeout>] [-l <log_file>] [-q] [-m]"
	echo "	-e <expressão>: Expressão que será monitorada. Quando essa expressão aparecer no log, a execução será liberada."
	echo "	-L <log_file>: Log que será monitorado."
	echo "	-t <timeout>: Para de executar monitoramento se expressão não for encontrada em até <timeout> segundos. Qualquer número inteiro negativo desativa o timeout. O padrão é \"30\"."
	echo "	-l <log_file>: (opcional) path e nome de arquivo para log customizado. Inibe o log padrão. Este parâmetro está relacionado com o log de execução, não o de monitoramento."
	echo "	-q: (opcional) não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
	echo "	-m: (opcional) não envia email com os logs de execução."
	exit ${ERROR}
}

ARGV=${@}
if [ "x$ARGV" = "x" ] ; then
  set_error $ERR_ARGUMENT_NOT_FOUND
  showusage
fi

opt_expr_to_monitor=""
opt_log_to_monitor=""
opt_expr_timeout=30
while getopts "e:L:t:l:qm" option ; do
        case "${option}" in
                e)
					opt_expr_to_monitor=${OPTARG}
                ;;
                L)
					opt_log_to_monitor=${OPTARG}
                ;;
                t)
					opt_expr_timeout=${OPTARG}
                ;;
                l)
					set_custom_log ${OPTARG}
                ;;
                q)
					set_run_log "nao"
                ;;
                m)
					opt_send_mail="nao"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ "x${opt_expr_to_monitor}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário passar a expressão que será monitorada no log. Ex.: -e \"INFO: Server startup in \\(.*?\\) ms\""
	showusage
fi

if [[ "x${opt_log_to_monitor}" == "x" ]] ; then
	do_log "É necessário passar o arquivo de log que será monitorado a partir do parâmetro -L. Ex.: -L /var/log/syslog"
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
fi

function set_tail_pid {
	_TAIL_PID=$1
}

function get_tail_pid {
	echo $_TAIL_PID
}

function kill_tail_pid {
	do_log "Eliminando fluxo de log auxiliar..."
	#do_log "PID do tail: $(get_tail_pid)"
	kill $(get_tail_pid)
	wait $(get_tail_pid) 2> /dev/null
}

function exit_by_ctrlc {
	kill_tail_pid
	do_log "Finalizando monitoramento."
	do_exit
}

# Captura o ctrl+c para eliminar tail com seguranca
trap exit_by_ctrlc INT

_log_aux="${TEMP_PATH}/_monitor_log_${MYNME}_$(get_now_for_log).txt"

function inicia_log_auxiliar {
	#do_log "Iniciando log auxiliar em \"${_log_aux}\""  
	${CMD_TAIL_LOG_MONITOR} ${opt_log_to_monitor} > ${_log_aux} &
	set_tail_pid $!
}

function monitora_log_auxiliar {
	do_log "Monitorando: \"${opt_log_to_monitor}\""
	do_log "Em busca da expressão: \"${opt_expr_to_monitor}\""
	do_log "Timeout: ${opt_expr_timeout}s."
	
	EXP_ENCONTRADA="no"
	EXEC_TIMEOUT="no"
	
	date1=$(date +"%s")
	while [ ${EXP_ENCONTRADA} == "no" ] && [ ${EXEC_TIMEOUT} == "no" ] ; do
		date2=$(date +"%s")
		sec_elapsed=$(($date2-$date1))
		#diff=$(($date2-$date1))
		#min_elapsed=$(($diff / 60))
		#sec_elapsed=$(($diff % 60))
		cat ${_log_aux} | grep -E "${opt_expr_to_monitor}" > /dev/null
		RES=$?
		if [ ${RES} -eq 0 ] ; then
			EXP_ENCONTRADA="yes" 
		fi
		if [ $sec_elapsed -eq ${opt_expr_timeout} ] ; then
			EXEC_TIMEOUT="yes" 
		fi
	done
	do_log "Finalizando monitoramento."
#	if [ ${EXEC_TIMEOUT} == "yes" ] ; then
#		do_log "O procedimento foi abortado após ${opt_expr_timeout} segundos."
#		do_log "O procedimento de subida ou monitoramento pode ter falhado. Consulte os logs."
#	fi
	if [ ${EXP_ENCONTRADA} == "yes" ] ; then
		do_log "Expressão ENCONTRADA em ${sec_elapsed}s."
		set_error $ERR_LOG_ENTRY_FOUND
	else 
		do_log "Expressão NÃO ENCONTRADA em ${sec_elapsed}s."
		set_error $ERR_LOG_ENTRY_NOT_FOUND
	fi
	#do_log "Parando a geração do log auxiliar." 
	kill_tail_pid
}

inicia_log_auxiliar
monitora_log_auxiliar

do_exit



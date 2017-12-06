#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} -i <nome_instancia> [-l <log_file>] [-q] [-m]"
  echo "	-i <nome_instancia>: instância que será gerenciada."
  echo "	-l <log_file>: (opcional) path e nome de arquivo para log customizado. Inibe o log padrão."
  echo "	-q: (opcional) não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
  echo "	-m: (opcional) não envia email com os logs de execução."
  echo "	-L: (opcional) Usa o mecanismo de observacao de log para confirmar se a instancia subiu (ao inves da checagem simples atraves da expressao PID)."
  exit ${ERROR}
}

ARGV=${@}
if [ "x$ARGV" = "x" ] ; then
  set_error $ERR_ARGUMENT_NOT_FOUND
  showusage
fi

set_send_email "sim"
use_log_observer="no"
while getopts "i:l:qmL" option ; do
        case "${option}" in
                i)
					instancia=${OPTARG}
                ;;
                l)
					set_custom_log ${OPTARG}
                ;;
                q)
					set_run_log "nao"
                ;;
                m)
					set_send_email "nao"
                ;;
                L)
					use_log_observer="sim"
                ;;				
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ "x${instancia}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
fi

set_email_subject "Procedimento de subida da instancia \"${instancia}\""

do_intro "Procedimento de inicio da instância '${instancia}'"

custom_file="${COMMONDIR}/custom/custom-setup-${instancia}.sh"
if [[ -e "${custom_file}" ]] ; then
	do_log "Utilizando parametros customizados de: ${custom_file}"
	. "${custom_file}"
fi

if [[ "x${EXPR_PID_FIND}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de busca pelo PID da instância."
	do_exit $(get_error)
fi

if [[ "x${CMD_CUSTOM_START}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de início da instância."
	do_exit $(get_error)
fi

function do_start {
	do_log "Executando: ${CMD_CUSTOM_START}..."
	#echo "Iniciaria se teste nao fosse... ${CMD_CUSTOM_START}"
	run_dir=${AS_BIN_PATH}
	do_log "Rodando a partir do diretório: $run_dir"
	pushd $run_dir >/dev/null
	eval "${CMD_CUSTOM_START}"
	popd >/dev/null
}

function wait_for_startup {
	start_success="no"
	start_timed_out="no"
	start_timer_init=$(date +"%s")
	do_log "Monitorando sucesso da operação de startup (timeout: ${START_TIMEOUT}s)."
	while [ "${start_success}" == "no" ] && [ "${start_timed_out}" == "no" ] ; do
		sleep ${START_TIMEOUT_DELAY}
		instpid=$(eval "${EXPR_PID_FIND}")
		if [ "x${instpid}" != "x" ] ; then
			start_success="sim"
			do_log "Instância '${instancia}' iniciada normalmente (PID: ${instpid})."
			if [[ "x${PID_FILE}" != "x" ]] ; then 
				echo ${instpid} > ${PID_FILE}
			fi 
		else
			start_timer_now=$(date +"%s")
			start_timer_diff=$(($start_timer_now-$start_timer_init))
			min_elapsed=$(($start_timer_diff / 60))
			sec_elapsed=$(($start_timer_diff % 60))
			if [ $sec_elapsed -eq ${START_TIMEOUT} ] ; then
				start_timed_out="sim" 
				do_log "Atingido tempo definido para aguardar o startup normal (${START_TIMEOUT}s)."
			fi
		fi
	done
}

function wait_for_startup_by_log_observer {
	do_log "Ativando mecanismo de monitoramento de log..."
	eval "${EXPR_LOG_STARTUP}"
	expr_log_observer_result=$?
	if [[ ${expr_log_observer_result} == ${ERR_LOG_ENTRY_FOUND} ]] ; then
		start_success="sim"
		instpid=$(eval "${EXPR_PID_FIND}")
		do_log "Instância '${instancia}' iniciada normalmente (PID: ${instpid})."
	else
		do_log "Monitoramento de log nao encontrou expressao de sucesso em (${START_TIMEOUT}s)."
	fi
}

###
### RUN 
###
instpid=$(eval "${EXPR_PID_FIND}")

if [ "x${instpid}" != "x" ] ; then
	do_log "ERRO: Foi encontrado uma instância rodando com o nome '${instancia}'."
	do_log "PID da instância: ${instpid}."
	do_log "Se o servidor estiver com problemas, tente rodar o procedimento de 'parada' ou o procedimento de 'restart'."
	do_log "Procedimento de subida abortado."
	set_error ${ERR_INSTANCE_ALREADY_RUNNING}
else
	do_log "Iniciando '${instancia}'..."
	
	do_start
	if [[ ${use_log_observer} == "no" ]] ; then
		wait_for_startup
	else 
		wait_for_startup_by_log_observer
	fi
	
	if [[ $start_timed_out == "sim"  ]] && [[ $start_success != "sim" ]] ; then
		do_log "Instância não iniciou no tempo previsto."
		do_log "Por favor, verifique se existe algum problema nos logs e tente novamente."
		set_error ${ERR_INSTANCE_START_FAIL}
	fi
fi

do_exit

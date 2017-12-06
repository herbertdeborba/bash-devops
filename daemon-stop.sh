#!/bin/bash

# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} -i <nome_instancia> [-l <log_file>] [-q] [-m]"
  echo "	-i <nome_instancia>: instância que será gerenciada."
  echo "	-l <log_file>: (opcional) path e nome de arquivo para log customizado. Inibe o log padrão."
  echo "	-q: (opcional) não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
  echo "	-m: (opcional) não envia email com os logs de execução."
  exit ${ERROR}
}

ARGV=${@}
if [ "x$ARGV" = "x" ] ; then
  set_error $ERR_ARGUMENT_NOT_FOUND
  showusage
fi

set_send_email "sim"

while getopts "i:l:qm" option ; do
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

set_email_subject "Procedimento de parada da instancia \"${instancia}\""

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Procedimento de parada da instância '${instancia}'"
do_log "Usuário: ${USRDATA}"

custom_file="${MYDIR}/custom/custom-setup-${instancia}.sh"
if [[ -e "${custom_file}" ]] ; then
	do_log "Utilizando parametros customizados de: ${custom_file}"
	. "${custom_file}"
fi

if [[ "x${EXPR_PID_FIND}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de busca pelo PID da instância."
	do_exit
fi

if [[ "x${CMD_CUSTOM_STOP}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de parada da instância."
	do_exit
fi

function do_stop {
	do_log "Executando: ${CMD_CUSTOM_STOP}..."
	#echo "Pararia se teste nao fosse... ${CMD_CUSTOM_STOP}"
	eval "${CMD_CUSTOM_STOP}"
}

function do_kill {
	pid=$1
	#echo "Killaria $pid se teste nao fosse..."
	eval "kill $pid >> ${LOG_OUTPUT}"
}

function do_abort {
	pid=$1
	#echo "Abortaria $pid se teste nao fosse..."
	eval "kill -9 $pid >> ${LOG_OUTPUT}"
}

function wait_for_stopdown {
	stop_success="no"
	stop_timed_out="no"
	stop_timer_start=$(date +"%s")
	do_log "Monitorando sucesso da operação de parada normal (timeout: ${STOP_TIMEOUT}s)."
	while [ "${stop_success}" == "no" ] && [ "${stop_timed_out}" == "no" ] ; do
		sleep ${STOP_TIMEOUT_DELAY}
		instpid=$(eval "${EXPR_PID_FIND}")
		if [ "x${instpid}" == "x" ] ; then
			stop_success="sim"
			do_log "Instância '${instancia}' interrompida normalmente."
		else
			stop_timer_now=$(date +"%s")
			stop_timer_diff=$(($stop_timer_now-$stop_timer_start))
			min_elapsed=$(($stop_timer_diff / 60))
			sec_elapsed=$(($stop_timer_diff % 60))
			if [ $sec_elapsed -eq ${STOP_TIMEOUT} ] ; then
				stop_timed_out="sim" 
				do_log "Atingido tempo definido para aguardar a parada normal (${STOP_TIMEOUT}s)."
			fi
		fi
	done
}

###
### RUN
###

instpid=$(eval "${EXPR_PID_FIND}")

if [ "x${instpid}" == "x" ] ; then
	do_log "Nao foi encontrado nenhum PID de '${instancia}' rodando..."
else
	do_log "PID da instancia '${instancia}' rodando: ${instpid}."
	do_log "Tentando parar '${instancia}' pela via 'normal'..."

	do_stop
	
	wait_for_stopdown
	
	if [[ $stop_timed_out == "sim"  ]] && [[ $stop_success != "sim" ]] ; then
		do_log "Instância ainda não parou... Verificando novamente..."
		instpid=$(eval "${EXPR_PID_FIND}")
		if [ "x${instpid}" != "x" ] ; then
			do_log "Ainda está vivo... Tentando derrubar o processo '${instpid}' delicadamente..." 
			
			do_kill ${instpid}
			
			do_log "Aguardando ${DELAY_KILL} segundos..."
			sleep $DELAY_KILL
			do_log "Verificando novamente..."
			instpid=$(eval "${EXPR_PID_FIND}")
			if [ "x${instpid}" != "x" ] ; then
				do_log "Ainda respira... Matando o processo '${instpid}' por força bruta..." 

				do_abort ${instpid}
				
				do_log "Aguardando ${DELAY_BRUTE} segundos..." 
				sleep $DELAY_BRUTE
				do_log "Verificando processo..."
				instpid=$(eval "${EXPR_PID_FIND}")
				if [ "x${instpid}" == "x" ] ; then
					do_log "Ok, nenhum processo da instância '${instancia}' rodando após o 'kill -9'." 
				else
					do_log "PID rodando: ${instpid}."
					do_log "A instância '${instancia}' ainda possui ao menos um processo ativo."
					do_log "ERRO! Não foi possível realizar o procedimento de parada!"
					do_exit ${ERR_INSTANCE_STOP_FAIL}
				fi
			else 
				do_log "Ok, nenhum processo da instancia '${instancia}' rodando após o 'kill'." 
			fi
		fi
	fi
fi

do_exit

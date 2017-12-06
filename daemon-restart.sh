#!/bin/bash

# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>
#
# Restarta o servidor web informado no parâmetro -i <instancia>.
#
###
### V 1.0 generic daemon
###

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} -i <nome_instancia> [-l <log_file>] [-q] [-m] [-c] [-k] [-M]"
  echo "	-i <nome_instancia>: instância do tomcat que será gerenciada."
  echo "	-l <log_file>: (opcional) path e nome de arquivo para log customizado. Inibe o log padrão."
  echo "	-q: (opcional) não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
  echo "	-m: (opcional) não envia email com os logs de execução."
  echo "	-r: (opcional) executa o comando de reload do daemon, ao invés dos comandos de stop e start monitorados."
  echo "	-c: (opcional) executa o procedimento de limpeza dos arquivos temporarios."
  echo "	-k: (opcional) executa o procedimento de bloqueio de porta, evitando que a instância seja acessada enquanto é derrubada ou está subindo."
  echo "	-M: (opcional) monitora o log para avaliar se o servidor subiu adequadamente."
  exit $(get_error)
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  ERROR=1
#  showusage
#fi

opt_send_mail="sim"
quiet=""
opt_reload="nao"
opt_clean="nao"
opt_block="nao"
opt_monitora_log="nao"
while getopts "i:l:qmrckM" option ; do
        case "${option}" in
                i)
					instancia=${OPTARG}
                ;;
                l)
					set_custom_log ${OPTARG}
                ;;
                q)
					set_run_log "nao"
					quiet="-q"
                ;;
                m)
					opt_send_mail="nao"
                ;;
                r)
					opt_reload="sim"
                ;;
                c)
					opt_clean="sim"
                ;;
                k)
					opt_block="sim"
                ;;
				M)
					opt_monitora_log="sim"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ "x${instancia}" == "x" ]] ; then
	do_log "Argumento -i <instancia> é obrigatorio. Instância: $instancia"
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
fi

custom_file="${MYDIR}/custom/custom-setup-${instancia}.sh"
if [[ -e "${custom_file}" ]] ; then
	do_log "Utilizando parametros customizados de: ${custom_file}"
	. "${custom_file}"
fi

if [[ "x${opt_clean}" == "xsim" ]] ; then
	if [[ "x${CMD_DAEMON_CLEAN}" == "x" ]] ; then
		do_log "Parametro '-c' recebido, porem não existe procedimento de limpeza definido."
		do_log "A limpeza não será executada. Por favor, defina a diretiva CMD_DAEMON_CLEAN."
		opt_clean="nao"
	fi
fi

if [[ "x${opt_block}" == "xsim" ]] ; then
	if [[ "x${CMD_CUSTOM_BLOCK}" == "x" ]] || [[ "x${CMD_CUSTOM_UNBLOCK}" == "x" ]] ; then
		do_log "Parametro '-k' recebido, porem não existe procedimento de bloqueio ou de desbloqueio definido."
		do_log "O bloqueio não será executado. Por favor, defina as diretivas CMD_CUSTOM_BLOCK e CMD_CUSTOM_UNBLOCK."
		opt_block="nao"
	fi
fi

if [[ "x${opt_monitora_log}" == "xsim" ]] ; then
	if [[ "x${CMD_CUSTOM_LOG_MONITOR}" == "x" ]] ; then
		do_log "Parametro '-M' recebido, porem não existe procedimento de monitoramento de log definido."
		do_log "O monitoramento de início não será executado. Por favor, defina a diretiva CMD_CUSTOM_LOG_MONITOR."
		opt_monitora_log="nao"
	fi
fi

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Procedimento de restart da instancia '${instancia}'"
do_log "Usuário: ${USRDATA}"


function do_stop {
	${MYDIR}/daemon-stop.sh -i ${instancia} -l ${LOG_OUTPUT} -m ${quiet}
}

function do_start {
	${MYDIR}/daemon-start.sh -i ${instancia} -l ${LOG_OUTPUT} -m ${quiet}
}

function do_reload {
	do_log "Executando comando de reload '${CMD_DAEMON_RELOAD}'..."
	$(eval ${CMD_DAEMON_RELOAD})
}

function do_clean {
	do_log "Executando comando de limpeza '${CMD_DAEMON_CLEAN}'..."
	${CMD_DAEMON_CLEAN}
}

function do_block {
	do_log "Executando comando de bloqueio '${CMD_CUSTOM_BLOCK}'..."
	${CMD_CUSTOM_BLOCK}
}

function do_unblock {
	do_log "Executando comando de desbloqueio '${CMD_CUSTOM_UNBLOCK}'..."
	${CMD_CUSTOM_UNBLOCK}
}

function do_monitora_log {
	do_log "Monitoramento de log para identificar subida da instância ${instancia}..."
	$(eval "${CMD_CUSTOM_LOG_MONITOR}")
}

if [[ "x${opt_reload}" != "xsim" ]] ; then
	if [[ "x${opt_block}" == "xsim" ]] ; then
		do_block
	fi
	do_stop
	if [[ "x${opt_clean}" == "xsim" ]] ; then
		do_clean
	fi
	do_start
	if [[ "x${opt_monitora_log}" == "xsim" ]] ; then
		do_monitora_log
	fi
	if [[ "x${opt_block}" == "xsim" ]] ; then
		do_unblock
	fi
else
	do_reload
fi

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

if [[ "x${opt_send_mail}" == "xsim" ]] ; then
	$(send_email "Restart da instancia \"${instancia}\"")
fi

exit $(get_error)
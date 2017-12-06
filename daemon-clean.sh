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
  echo "Modo de usar: ${MYNME} -i <nome_instancia> [-l <log_file>] [-q] [-m]"
  echo "	-i <nome_instancia>: instância do tomcat que será gerenciada."
  echo "	-l <log_file>: (opcional) path e nome de arquivo para log customizado. Inibe o log padrão."
  echo "	-q: (opcional) não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
  echo "	-m: (opcional) não envia email com os logs de execução."
  echo "	-r: (opcional) executa o comando de reload do daemon, ao invés dos comandos de stop e start monitorados."
  exit $(get_error)
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  ERROR=1
#  showusage
#fi

set_send_email "sim"
quiet=""
opt_reload="nao"
opt_clean="nao"
while getopts "i:l:qmrc" option ; do
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
					set_send_email "nao"
                ;;
                r)
					opt_reload="sim"
                ;;
                c)
					opt_clean="sim"
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

if [[ "x${CMD_DAEMON_CLEAN}" == "x" ]] ; then
	do_log "Nao existe procedimento de limpeza definido."
	do_log "A limpeza não será executada. Por favor, defina a diretiva CMD_DAEMON_CLEAN."
	opt_clean="nao"
fi

if [[ "x${EXPR_PID_FIND}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de busca pelo PID da instância."
	do_exit $(get_error)
fi

set_email_subject "Limpeza da instancia \"${instancia}\""

instpid=$(eval "${EXPR_PID_FIND}")

if [ "x${instpid}" != "x" ] ; then
	do_log "ERRO: Foi encontrado uma instância rodando com o nome '${instancia}'."
	do_log "PID da instância: ${instpid}."
	do_log "Não é recomendável limpar uma instância que está rodando. Rode o procedimento de 'parada' ou o procedimento de 'restart'."
	do_log "Procedimento de limpeza abortado."
	do_exit ${ERR_INSTANCE_ALREADY_RUNNING}
fi

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Procedimento de limpeza da instancia '${instancia}'"
do_log "Usuário: ${USRDATA}"

function do_clean {
	do_log "Executando comando de limpeza '${CMD_DAEMON_CLEAN}'..."
	#eval "${CMD_DAEMON_CLEAN} -l ${LOG_OUTPUT} -m ${quiet}"
	eval "${CMD_DAEMON_CLEAN}" >> ${LOG_OUTPUT}
}

do_clean

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

do_exit
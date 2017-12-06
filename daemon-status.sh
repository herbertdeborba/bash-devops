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

opt_send_mail="sim"
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
					opt_send_mail="nao"
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

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Procedimento de verificação de status da instância '${instancia}'"
do_log "Usuário: ${USRDATA}"

custom_file="${MYDIR}/custom/custom-setup-${instancia}.sh"
if [[ -e "${custom_file}" ]] ; then
	do_log "Utilizando parametros customizados de: ${custom_file}"
	. "${custom_file}"
fi

if [[ "x${EXPR_PID_FIND}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de busca pelo PID da instância."
	exit $(get_error)
fi

opt_run_test="sim"
if [[ "x${CMD_DAEMON_TEST}" == "x" ]] ; then
	do_log "Expressao de teste ausente."
	opt_run_test="nao"
fi

function do_test {
	do_log "Executando: ${CMD_DAEMON_TEST}..."
	#echo "Pararia se teste nao fosse... ${CMD_DAEMON_TEST}"
	#$(eval ${CMD_DAEMON_TEST})
	eval "${CMD_DAEMON_TEST}"
}

###
### RUN
###

instpid=$(eval "${EXPR_PID_FIND}")

if [ "x${instpid}" == "x" ] ; then
	do_log "Nao foi encontrado nenhum PID de '${instancia}' rodando..."
else
	do_log "PID da instancia '${instancia}' rodando: ${instpid}."
fi

if [[ "x${opt_run_test}" == "xsim" ]] ; then
	do_log "Obtendo status da '${instancia}'..."
	do_log "Rodando teste de verificação de configuração..."
	do_test
fi

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

if [[ "x${opt_send_mail}" == "xsim" ]] ; then
	$(send_email "Status da instancia \"${instancia}\"")
fi

exit $(get_error)
#!/bin/bash

# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "${MYNME} utiliza comandos customizados por instância de bloqueio ou desbloqueio de acesso."
  echo "	Veja também: util-block-port.sh"
  echo "Modo de usar: ${MYNME} -i <nome_instancia> [-a (block|unblock)] [-l <log_file>] [-q] [-m]"
  echo "	-a (block|unblock): ação a ser tomada. Padrão é block."
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
opt_action="block"

while getopts "a:i:l:qm" option ; do
        case "${option}" in
                a)
					opt_action=${OPTARG}
                ;;
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
	do_log "Argumento inválido."
	showusage
fi

if [[ "x${opt_action}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "Ação não encontrada."
	showusage
else
	if [[ "x${opt_action}" != "xblock" ]] && [[ "x${opt_action}" != "xunblock" ]] ; then
		set_error $ERR_INVALID_PARAMETER
		do_log "Parâmetro inválido para -a: \"${opt_action}\"."
		showusage
	fi
fi

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Procedimento de bloqueio/desbloqueio da instância '${instancia}'."
do_log "Usuário: ${USRDATA}"
do_log "Ação: ${opt_action}"

custom_file="${MYDIR}/custom/custom-setup-${instancia}.sh"
if [[ -e "${custom_file}" ]] ; then
	do_log "Utilizando parametros customizados de: ${custom_file}"
	. "${custom_file}"
fi

if [[ "x${CMD_CUSTOM_BLOCK}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de bloqueio da instância."
	exit $(get_error)
fi

if [[ "x${CMD_CUSTOM_UNBLOCK}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	do_log "É necessário informar uma expressão de desbloqueio da instância."
	exit $(get_error)
fi

function do_block {
	do_log "Executando: ${CMD_CUSTOM_BLOCK}..."
	#echo "Bloquearia se teste nao fosse... ${CMD_CUSTOM_BLOCK}"
	${CMD_CUSTOM_BLOCK} -l ${LOG_OUTPUT} -m -q
}

function do_unblock {
	do_log "Executando: ${CMD_CUSTOM_UNBLOCK}..."
	#echo "Desbloquearia se teste nao fosse... ${CMD_CUSTOM_UNBLOCK}"
	${CMD_CUSTOM_UNBLOCK} -l ${LOG_OUTPUT} -m -q
}

###
### RUN
###

#instpid=$(eval "${EXPR_PID_FIND}")

#do_log "PID da instancia '${instancia}' rodando: ${instpid}."

if [[ "x${opt_action}" == "xblock" ]] ; then
	do_log "Realizando BLOQUEIO da instância '${instancia}'."
	mailstr="Bloqueio"
	do_block
elif [[ "x${opt_action}" == "xunblock" ]] ; then
	do_log "Realizando DESBLOQUEIO da instância '${instancia}'."
	mailstr="Desbloqueio"
	do_unblock
else
	do_log "Opção que define ação a ser tomada não foi encontrada."
fi

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

if [[ "x${opt_send_mail}" == "xsim" ]] ; then
	$(send_email "${mailstr} da instancia \"${instancia}\"")
fi

exit $(get_error)
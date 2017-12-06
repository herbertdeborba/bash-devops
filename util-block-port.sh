#!/bin/bash

##
## UTILITÁRIO PARA BLOQUEIO DE PORTAS TCP
## 
## Este script é um utilitário que bloqueia portas TCP contra entrada de novas conexões.
##

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
	echo "Modo de usar: ${MYNME} -i <nome_instancia> [-a (block|unblock)] [-l <log_file>] [-q] [-m]"
	echo "	-p <porta>: porta TCP a ser bloqueada em todas as interfaces."
	echo "	-a (block|unblock): ação a ser tomada. Padrão é block."
	echo "	-l <log_file>: (opcional) path e nome de arquivo para log customizado. Inibe o log padrão."
	echo "	-q: (opcional) não imprime o log de execução no console, mas continua gerando o log padrão ou customizado."
	echo "	-m: (opcional) não envia email com os logs de execução."
	exit ${ERROR}
}

#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#  set_error $ERR_ARGUMENT_NOT_FOUND
#  showusage
#fi

opt_action="block"
opt_port_to_block=""
while getopts "p:a:l:qm" option ; do
        case "${option}" in
				p)
					opt_port_to_block=${OPTARG}
				;;
                a)
					opt_action=${OPTARG}
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

if [[ "${opt_port_to_block}" == "x" ]] ; then
	do_log "É necessário passar a porta a ser bloqueada a partir do parâmetro -p. Ex.: -p 8009"
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
fi


### Tudo correto, podemos prosseguir

function iptables_init {
	do_log "Executando ação de bloqueio."
	$CMD_IPTABLES -N TEMPBLOCK
	$CMD_IPTABLES -A INPUT -j TEMPBLOCK
	$CMD_IPTABLES -A TEMPBLOCK -p tcp --dport ${opt_port_to_block} -m state --state NEW,ESTABLISHED -j DROP
}

function iptables_stop {
	do_log "Executando ação de desbloqueio."
	$CMD_IPTABLES -D INPUT -j TEMPBLOCK
	$CMD_IPTABLES -F TEMPBLOCK
	$CMD_IPTABLES -X TEMPBLOCK
}
	
if [[ "x${opt_action}" == "xblock" ]] ; then 
	iptables_init
elif [[ "x${opt_action}" == "xunblock" ]] ; then 
	iptables_stop
else
	do_log "Opção desconhecida: '${opt_action}'."
fi

exit $?

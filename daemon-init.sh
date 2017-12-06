#!/bin/bash
# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>
#
# Para ser chamado pelos scripts de init customizados.
#
# NÃO FOI FEITO PARA SER MODIFICADO, NEM PARA SER DIRETAMENTE CHAMADO!
#
# Leia abaixo por favor.
#
# Os comandos de start, stop e restart não devem ser customizados
# aqui. Este script deve chamar os scripts de administração de
# servidores, que por sua vez podem ser customizados com scrips de
# start, stop e restart específicos para cada instância.
# 
# Scripts relacionados:
# 	custom/tomcat-init-<instancia>: Chama este script após definir
#		parâmetros customizados de start do sistema (init.d).
# 	custom/custom-init-<instancia>: Define parâmetros customizados
#		para start, stop e restart da instância em questão.
###
### V 1.0 generic daemon
### 

COMMONDIR="/opt/devops"

if [[ "x${CMD_INIT_START}" == "x" ]] ; then
	CMD_START="${COMMONDIR}/daemon-start.sh -i ${INSTANCE_NAME} &"
else
	CMD_START=${CMD_INIT_START}
fi
if [[ "x${CMD_INIT_STOP}" == "x" ]] ; then
	CMD_STOP="${COMMONDIR}/daemon-stop.sh -i ${INSTANCE_NAME} &"
else
	CMD_STOP=${CMD_INIT_STOP}
fi
if [[ "x${CMD_INIT_RESTART}" == "x" ]] ; then
	CMD_RESTART="${COMMONDIR}/daemon-restart.sh -i ${INSTANCE_NAME} &"
else
	CMD_RESTART=${CMD_INIT_RESTART}
fi
if [[ "x${CMD_INIT_STATUS}" == "x" ]] ; then
	CMD_STATUS="${COMMONDIR}/daemon-status.sh -i ${INSTANCE_NAME} -m &"
else
	CMD_STATUS=${CMD_INIT_STATUS}
fi


do_start()
{	
	if [ $USER = "root" ] ; then 
		$CMD_START
	else
		sudo $CMD_START
	fi
}

do_stop()
{
	if [ $USER = "root" ] ; then
		$CMD_STOP
	else
		sudo $CMD_STOP
	fi
}

do_restart()
{
	if [ $USER = "root" ] ; then
	   $CMD_RESTART
	else
	   sudo $CMD_RESTART
	fi
}

do_status()
{
   $CMD_STATUS
}


case "$COMMAND" in
  start)
        do_start
        ;;
  stop)
        do_stop
        ;;
  restart)
        do_restart
        ;;
  status)
        do_status
        ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|status}" >&2
        exit 3
        ;;
esac

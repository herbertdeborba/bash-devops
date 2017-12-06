#!/bin/bash

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Lista as instâncias do tomcat que estão no ar no momento da execução do comando."
  echo "Modo de usar: ${MYNME} [-o]"
	echo "	-o: (opcional, experimental) Lista instâncias offline com base na configuração padrão do sistema."
  exit $(get_error)
}

# Quando houver argumentos obrigatórios:
#ARGV=${@}
#if [ "x$ARGV" = "x" ] ; then
#	set_error $ERR_ARGUMENT_NOT_FOUND
#	showusage
#fi

opt_offline="nao"
set_run_log "sim"

while getopts "ol" option ; do
        case "${option}" in
                o)
					opt_offline="sim"
                ;;
                l)
					set_run_log "nao"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

do_log "${DATA_EXEC}"
do_log "Iniciando procedimento de listagem de instâncias..."

function find_instances {
	aslist=""
	if [[ "x${opt_offline}" == "xsim" ]] ; then
		do_log "Listando instâncias offline, baseado na configuração do diretório base do Tomcat."
		do_log "Esta opção é experimental e pode não estar totalmente correta."
		do_log ""
		### AS PATHS
		IN=${AS_PATHS}
		OIFS=$IFS
		IFS=':'
		arr2=$IN
		i=0
		for aspath in $arr2
		do
			i=$(($i+1))
			do_log "Diretório base ($i): ${aspath}"
			find -L ${aspath}* -mindepth 1 -maxdepth 2 -type d | ${CMD_TEE_APPEND} ${LOG_OUTPUT} 2>> ${LOG_OUTPUT}
		done
		IFS=$OIFS
	else
		do_log "Buscando instâncias ativas..."
		search_catalina_base="ps -ef | grep org.apache.catalina.startup.Bootstrap | grep -v grep | grep -v /bin/bash | sed 's/\(\.*\)\s\+\([[:digit:]]\+\).*-Dcatalina.base=\(.\+\)\s.\+-D.*/\1 \2 \3/g' | grep -v 'sed\ '"
		#do_log "  Comando de busca: ${search_catalina_base}"
		aslist=$(eval ${search_catalina_base})
		
		if [[ "x${aslist}" == "x" ]] ; then 
			do_log "Nao foi possivel encontrar nenhuma instância rodando no momento."
			do_log "Você pode utilizar o parâmetro -o para mostrar as instâncias offline"
			do_log "com base no diretório raiz padrão configurado no common-setup."
			set_error $ERR_INSTANCE_LIST_NOT_FOUND
		else
			do_log ""
			#do_log "${aslist}"
			#IFS='\$' read -a array <<< "${aslist}"
			#arr=()
			while read -r line; do
			   arr+=("$line")
			done <<< "${aslist}"
			cnt=0
			for element in "${arr[@]}"
			do
				# root 1295 /java/apache-tomcat-6.0.32/server/petprec
				cnt=$(($cnt + 1))
				instary=($element)
				owner=${instary[0]}
				pid=${instary[1]}
				catalina_base=${instary[2]}
				instancia=${catalina_base##*/}
				do_log "#$cnt:	NOME: ${instancia}		PID: ${pid}"
				do_log "	CATALINA.BASE: ${catalina_base}		OWNER: ${owner}"
			done
		fi	
	fi
}

find_instances

do_log ""
do_log "$(get_now) Procedimento '${MYNME}' concluído."

exit $(get_error)
#!/bin/bash

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh

function showusage {
  echo "Modo de usar: ${MYNME} -i <nome_instancia> -b <catalina_base> [-l <log_file>] [-q] [-m]"
  echo "	-i <nome_instancia>: instância do tomcat que será gerenciada."
  echo "	-b <catalina_base>: path base da instância que será gerenciada."
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

while getopts "i:b:l:qm" option ; do
        case "${option}" in
                i)
					instancia=${OPTARG}
                ;;
                b)
					aspath=${OPTARG}
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

if [[ "x${instancia}" == "x" ]] ||  [[ "x${aspath}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
fi

custom_file="${MYDIR}/custom/custom-setup-${instancia}.sh"
if [[ -e "${custom_file}" ]] ; then
	do_log "Utilizando parametros customizados de: ${custom_file}"
	. "${custom_file}"
fi

testpid="ps -ef | grep org.apache.catalina.startup.Bootstrap | grep ${instancia} | grep -v grep | grep -v /bin/bash | grep -v ${MYNME} | sed 's/\s\s*/ /g' | cut -d ' ' -f2"

instpid=$(eval ${testpid})
### DEBUG DO testpid / instpid
#do_log "Comando de teste do PID: ${testpid}"
#do_log "InstPID: ${instpid}"
#exit 1


if [ "x${instpid}" != "x" ] ; then
	do_log "Foi encontrado uma instância rodando com o nome '${instancia}'..."
	do_log "PID da instância '${instancia}' rodando: ${instpid}."
	do_log "Nao e recomendável limpar os caches de uma instância ainda no ar."
	do_log "Tente rodar o procedimento de parada primeiro."
	set_error ${ERR_INSTANCE_ALREADY_RUNNING}
	opt_send_mail="nao"
else
	if [ "x${aspath}" != "x" ] ; then
	
		do_log "Catalina.base informado: '${aspath}'."
		do_log "Verificando '${aspath}'..."

		if [[ -d "${aspath}" ]] ; then 
			do_log "Ok, ${aspath} é um diretório."
			catalina_base="${aspath}"
			if [[ -d "${catalina_base}/temp/" ]] ; then 
				do_log "Removendo arquivos de '${catalina_base}/temp/*)'..."
				rm -rf ${catalina_base}/temp/* >> ${LOG_OUTPUT}
			else 
				do_log "'${catalina_base}/temp/*)' não existe ou não é um diretório."
				ERROR=3
			fi
			if [[ -d "${catalina_base}/work/" ]] ; then 
				do_log "Removendo arquivos de '${catalina_base}/work/*)'..." 
				rm -rf ${catalina_base}/work/* >> ${LOG_OUTPUT}
			else 
				do_log "'${catalina_base}/work/*)' não existe ou não é um diretório."
				set_error $ERR_INSTANCE_STOP_INVALID_AS_PATH
			fi
			if [[ -d "${catalina_base}/tmp/" ]] ; then 
				do_log "Removendo arquivos de '${catalina_base}/tmp/*)'..." 
				rm -rf ${catalina_base}/tmp/* >> ${LOG_OUTPUT}
			else 
				do_log "'${catalina_base}/tmp/*)' não existe ou não é um diretório."
				set_error $ERR_INSTANCE_STOP_INVALID_AS_PATH
			fi
		else 
			do_log "AVISO: ${aspath} não é um diretorio..."
			do_log "Catalina.base não pôde ser utilizado."
			do_log "Limpezas NÃO REALIZADAS."
			set_error $ERR_INSTANCE_STOP_INVALID_AS_PATH
		fi
	else 
		do_log "Catalina.base não informado. Não vou executar limpeza de caches."
		set_error $ERR_INSTANCE_STOP_INVALID_AS_PATH
	fi
fi

do_log "$(get_now) Procedimento '${MYNME}' concluído."
do_log ""

if [[ "x${opt_send_mail}" == "xsim" ]] ; then
	mail -s "$(echo -e "[${EMAILIDENT}] Limpeza de cache instancia ${instancia}\nFrom: ${EMAILNAME} <${EMAILREPLY}>\nReply-to: ${EMAILREPLY}\n")" ${EMAILTO} < "${LOG_OUTPUT}"
fi
	
exit $(get_error)

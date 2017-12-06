#!/bin/bash

# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>
#
# Tudo sera feito com base nisso, find precisa ser compativel:
# find /tmp/test/ -mmin -5 -type f -exec ls {} +
#

MYDIR=`dirname $0`
. ${MYDIR}/common-setup.sh


#######
######
####
## REMOVER NA PRODUCAO
######## 
#EMAILTO="herbert@tjsc.jus.br"

DEFAULT_TEMPO_MOD=5
DEFAULT_TEMPO_VER=30

function showusage {
  echo "Modo de usar: ${MYNME} -s <arquivo_ou_pasta_a_monitorar> [-m <tempo_de_modificacao_em_minutos>]"
  echo "	-s <arquivo_ou_pasta_a_monitorar>: O arquivo ou pasta que sera monitorado."
  echo "	-c <tempo_de_modificacao_em_minutos> (opcional): O arquivo sera considerado modificado se for mais novo que este parametro. Default: ${DEFAULT_TEMPO_MOD}"
  #echo "	-t <tempo_de_verificacao_em_minutos> (opcional): O arquivo sera verificado periodicamente com base neste parametro. Default: ${DEFAULT_TEMPO_VER}"
  #echo "	-d (opcional): Roda em modo daemon."
  echo "	-o: (opcional) Envia email apenas se houve modificacao."
  echo "	-m: (opcional) Nao envia email com os logs de execucao."
  exit ${ERROR}
}

ARGV=${@}
if [ "x$ARGV" = "x" ] ; then
  set_error $ERR_ARGUMENT_NOT_FOUND
  showusage
fi

arquivo_mon=""
tempo_mod=""
tempo_ver=""
run_as_daemon="nao"
opt_send_mail="sim"
opt_email_mod_only="nao"
while getopts "s:c:t:dmo" option ; do
        case "${option}" in
                s)
					arquivo_mon=${OPTARG}
                ;;
                c)
					tempo_mod=${OPTARG}
                ;;
                t)
					tempo_ver=${OPTARG}
                ;;
				d)
					run_as_daemon="sim"
				;;
                m)
					opt_send_mail="nao"
                ;;
                o)
					opt_email_mod_only="sim"
                ;;
				?)
					set_error $ERR_INVALID_PARAMETER
					showusage
				;;
		esac
done

if [[ "x${arquivo_mon}" == "x" ]] ; then
	set_error $ERR_ARGUMENT_NOT_FOUND
	showusage
else 
	if [[ ! -e ${arquivo_mon} ]] ; then
		do_log "Arquivo ou pasta \"${arquivo_mon}\" nao foi encontrado."
		showusage
	fi
fi

if [[ "x${tempo_mod}" != "x" ]] ; then
	if [[ "x$(is_an_integer $tempo_mod)" != "xsim" ]] ; then
		do_log "Numero invalido."
		set_error $ERR_INVALID_PARAMETER
		showusage
	fi
else
	tempo_mod=$DEFAULT_TEMPO_MOD
fi

if [[ "x${tempo_ver}" != "x" ]] ; then
	if [[ "x$(is_an_integer $tempo_ver)" != "xsim" ]] ; then
		do_log "Numero invalido."
		set_error $ERR_INVALID_PARAMETER
		showusage
	fi
else
	tempo_ver=$DEFAULT_TEMPO_VER
fi

verifstr="arquivo"
if [[ -d ${arquivo_mon} ]] ; then
	verifstr="diretorio"
fi

do_log ""
do_log "${DATA_EXEC} '${MYNME}'"
do_log "Utilitario para monitoramento de arquivos ou pastas."
do_log "Usuário: ${USRDATA}"
do_log ""
do_log "Verificando se o ${verifstr} \"${arquivo_mon}\" foi modificado nos ultimos ${tempo_mod} min."
do_log ""

datahoraexec=$(get_now_for_log)
origemesc=$(echo ${arquivo_mon} | sed 's/\//\%/g')
pathnmtmp="${TEMP_PATH}/_temp_${MYNME}-${origemesc}-${datahoraexec}.txt"



find ${arquivo_mon} -mmin -${tempo_mod} -type f -exec ls -l {} + > ${pathnmtmp}

nummod=`cat ${pathnmtmp} | wc -l`

detalhes=`cat ${pathnmtmp}`

if [[ ${verifstr} == "arquivo" ]] ; then 
	if [[ ${nummod} > 0 ]] ; then 
		do_log "Arquivo foi modificado."
		do_log ""
		do_log "Detalhes:"
		do_log ""
		do_log "${detalhes}"
	else
		do_log "Arquivo nao foi modificado."
	fi	
else
	if [[ ${nummod} > 0 ]] ; then 
		do_log "Diretorio possui arquivos modificados."
		do_log ""
		do_log "Detalhes:"
		do_log ""
		do_log "${detalhes}"
	else
		do_log "Diretorio nao possui arquivos modificados."
	fi	
fi

do_log ""
do_log "$(get_now) Procedimento '${MYNME}' concluido."
do_log ""

if [[ "x${opt_send_mail}" == "xsim" ]] ; then
	if [[ "x${opt_email_mod_only}" == "xsim" ]] ; then
		if [[ ${nummod} > 0 ]] ; then 
			$(send_email "Mudancas detectadas em \"${arquivo_mon}\"")
		fi
	else 
		$(send_email "Verificando mudancas em \"${arquivo_mon}\"")
	fi
fi

exit $(get_error)
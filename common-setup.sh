#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

###########################################################################
###########################################################################
### ATENCAO: ESTE SCRIPT NAO FOI PROJETADO PARA SER CUSTOMIZADO
### AS CUSTOMIZACOES DE UM AMBIENTE DEVEM SER FEITAS NO 
### $PATH_SCRIPTScustom/custom-setup.sh
###########################################################################
###########################################################################

_sensible_dirs=("/" "/boot" "/cdrom" "/dev" "/etc" "/initrd" "/lib" "/lib32" "/lib64" "/proc" "/sbin" "/selinux" "/sys" "/usr/bin" "/usr/sbin" "/var" "/vmlinuz" "/etc/profile.d" "/etc/sudoers.d" "/usr/lib" "/usr/lib64" "/usr/lib32" "/usr/share" "/usr/include" "/usr" "/usr/local/bin" "/usr/local/sbin" "/usr/local")
_sensible_files=("/etc/profile" "/etc/sudoers" "/etc/passwd" "/etc/group" "/etc/shadow")

##
## UTILS E FUNCTIONS
##
function do_log {
	MY_LOG_MSG="$1"
	touch ${LOG_OUTPUT}
	echo -e "${MY_LOG_MSG}" >> ${LOG_OUTPUT}
	if [[ "x${OPT_RUN_LOG}" == "xsim" ]] ; then
		echo -e "${MY_LOG_MSG}"
	fi
}

function set_run_log {
	OPT_RUN_LOG="$1"
}

function set_custom_log {
	LOG_OUTPUT="$1"
}

function get_log_output {
	echo "${LOG_OUTPUT}"
}

function get_log_path {
	echo "${LOG_PATH}"
}

function set_error {
	ERROR=$1
}

function get_error {
	echo "${ERROR}"
}

function get_now {
	echo $(date +"%d/%m/%Y %H:%M:%S")
}

function get_day_for_log {
	echo $(date +"%Y%m%d")
}

function get_now_for_log {
	echo $(date +"%Y%m%d%H%M%S")
}

function get_precision_date {
	echo $DATAHORAHJPREC
}

function send_email {
	psubject=$1
	if [[ "x$psubject" != "x" ]] ; then
		EMAILSUBJECT=$1
	fi
	$(eval ${CMD_SEND_MAIL})
}

function set_send_email {
	OPT_SEND_EMAIL=$1
}

function set_email_subject {
	EMAILSUBJECT=$1
}

function make_dir_if_not_exists {
	DIR_TO_CREATE=$1
	if [ ! -d ${DIR_TO_CREATE} ] ; then
		mkdir -p ${DIR_TO_CREATE}
	fi
}

function do_intro {
	desc=$1
	do_log ""
	do_log "${DATA_EXEC} '${MYNME}'"
	do_log "$1"
	do_log "Usuário: ${USRDATA}"
}

function do_exit {
	perror=$1
	if [[ "x$perror" != "x" ]] ; then
		set_error $perror
	fi
	#do_log "$(get_now) Procedimento '${MYNME}' concluído."
	do_log "$(get_now) Procedimento concluído."
	do_log ""
	if [[ "x${OPT_SEND_EMAIL}" == "xsim" ]] ; then
		#do_log "Enviando email."
		$(send_email)
	fi
	exit $(get_error)
}

function verif_target {
	$ptarg=$1
	if [[ "x$ptarg" == "x" ]] ; then
		do_log "Nao vou realizar a operacao $0 pois alvo nao esta informado corretamente."
		do_exit $ERR_INVALID_PARAMETER
	else
		if [[ "x$ptarg" == "x/" ]] ; then
			do_log "Nao vou realizar a operacao $0 pois diretorio alvo e a raiz do sistema."
			do_exit $ERR_INVALID_PARAMETER
		else
			if [[ ! -e "$ptarg" ]] ; then
				do_log "Nao vou realizar a operacao $0 pois alvo nao foi informado corretamente."
				do_exit $ERR_INVALID_PARAMETER
			fi
		fi
	fi
}

function is_sensible_dir {
	ptarg=$1
	dirname=$(dirname "${ptarg}/.")
	#echo "DIRNAME: $dirname"
	for targ in "${_sensible_dirs[@]}" ; do
		#echo "TESTE $dirname == $targ ?"
		if [[ "x${dirname}" == "x${targ}" ]] ; then
			do_log "Nao vou realizar a operacao ${FUNCNAME[2]} pois diretorio alvo $ptarg e sensivel."
			do_exit $ERR_INVALID_PARAMETER
		fi
	done
}

function is_file_inside_sensible_dir {
	ptarg=$1
	dirname=$(dirname "${ptarg}")
	#echo "DIRNAME: $dirname"
	for targ in "${_sensible_dirs[@]}" ; do
		#echo "TESTE $dirname == $targ ?"
		if [[ "x${dirname}" == "x${targ}" ]] ; then
			do_log "Nao vou realizar a operacao ${FUNCNAME[2]} pois alvo $ptarg esta em diretorio sensivel."
			do_exit $ERR_INVALID_PARAMETER
		fi
	done
}

function is_sensible_file {
	ptarg=$1
	for targ in "${_sensible_files[@]}" ; do
		if [[ "x${ptarg}" == "x${targ}" ]] ; then
			do_log "Nao vou realizar a operacao ${FUNCNAME[2]} pois arquivo alvo $ptarg e sensivel."
			do_exit $ERR_INVALID_PARAMETER
		fi
	done
}

function verif_sensible_target {
	ptargv=$1
	if [[ "x$ptargv" == "x" ]] ; then
		do_log "Nao vou realizar a operacao ${FUNCNAME[1]} pois alvo $ptargv nao foi informado corretamente."
		do_exit $ERR_INVALID_PARAMETER
	else
		if [[ ! -e "$ptargv" ]] ; then
			do_log "Nao vou realizar a operacao ${FUNCNAME[1]} pois alvo $ptargv nao foi encontrado."
			do_exit $ERR_INVALID_PARAMETER
		fi

		if [[ -d $ptargv  ]] ; then                 
			is_sensible_dir $ptargv
		else
			is_file_inside_sensible_dir $ptargv
			is_sensible_file $ptargv
		fi
	fi
}

function do_chown {
	puser=$1
	pgroup=$2
	ptarget=$3
	prec=$4
	if [[ "x$puser" == "x" ]] ; then
		do_log "Nao vou realizar a operacao ${FUNCNAME[0]}, argumentos invalidos."
		do_exit $ERR_INVALID_PARAMETER
	fi
	verif_sensible_target $ptarget
	cmd_prep="${CMD_CHOWN} $prec $puser:$pgroup $ptarget"
	#echo "$cmd_prep"
	$($cmd_prep)
}

function do_chmod {
	perms=$1
	ptarget=$2
	prec=$3
	if [[ "x$perms" == "x" ]] ; then
		do_log "Nao vou realizar a operacao ${FUNCNAME[0]}, argumentos invalidos."
		do_exit $ERR_INVALID_PARAMETER
	fi
	verif_sensible_target $ptarget
	cmd_prep="${CMD_CHMOD} $prec $perms $ptarget"
	#echo "$cmd_prep"
	$($cmd_prep)
}

function is_an_integer {
	# Exemplo: if [[ "x$(is_an_integer $numero)" != "xsim" ]] ; then ...
	string=$1
	case $string in
		''|*[!0-9]*) echo nao ;;
		*) echo sim ;;
	esac
}

function get_hostname {
	echo $MY_HOSTNAME	
}

function set_email_to {
	EMAILTO=$1
}

function get_instance_from_filename {
        _filen=$1
		# pega o nome da instance no campo 3
        instanceext=$(echo ${_filen} | cut -d'-' -f3)
		# stripa a extensao pegando apenas o campo 1
        instancen=$(echo ${instanceext} | cut -d'.' -f1)
        echo $instancen
}

##
## CONSTANTES DE ERRO
##
ERR_SUCCESS=0
ERR_INVALID_PARAMETER=1
ERR_ARGUMENT_NOT_FOUND=2
ERR_INSTANCE_LIST_NOT_FOUND=10
ERR_INSTANCE_START_FAIL=11
ERR_INSTANCE_STOP_INVALID_AS_PATH=12
ERR_INSTANCE_NOT_FOUND=13
ERR_INSTANCE_ALREADY_RUNNING=14
ERR_INSTANCE_STOP_FAIL=15
ERR_FILE_OR_PATH_NOT_FOUND="20"
ERR_LOG_ENTRY_FOUND="30"
ERR_LOG_ENTRY_NOT_FOUND="31"

###
### STRINGS
###

STR_CMD_CCZE_NOTFOUND="Comando colorizador CMD_CCZE nao encontrado! Usando padrao."
STR_ERR_LOGFILE_NOTFOUND="ERRO: Arquivo nao encontrado."
STR_INTRO_UTIL_LOG_READER="Utilitario para leitura de arquivos de log"

##
## PARAMETROS DE DESCOBERTA AUTOMATICA
##
MYDIR=`dirname $0`
MY_HOSTNAME==$(hostname)
MYNME=`basename $0`
SERVERNAME=$(uname -n | awk '{print toupper($0)}')

### 
### PATHS
###
COMMONDIR="${MYDIR}"
TEMP_PATH="/tmp"
COMMONDIR_AUX="${TEMP_PATH}/devops_aux"
LOG_PATH="${COMMONDIR_AUX}/logs"

###
### DATA E HORA
###
DATAANOMESDIA=`date +"%Y%m%d"`
DATAHRMINSEC=`date +"%H%M%S"`
DATAHRNANO=`date +"%N"`
DATAHORAHJ="${DATAANOMESDIA}${DATAHRMINSEC}"
DATAHORAHJPREC="${DATAHORAHJ}.${DATAHRNANO}"
DATA_EXEC=`date +"%d/%m/%Y %H:%M:%S"`

###
### EMAIL
###
EMAILIDENT="${SERVERNAME}"

###
### COMANDOS
###
CMD_SEND_MAIL="/usr/bin/mail -s \"\$(echo -e \"[\${EMAILIDENT}] \${EMAILSUBJECT}\nFrom: \${EMAILNAME} <\${EMAILREPLY}>\nReply-to: \${EMAILREPLY}\n\")\" \${EMAILTO} < \"\${LOG_OUTPUT}\""
# Comandos utilizados para tentar identificar o usuário
CMD_WHO1="/usr/bin/who am i --ips"
CMD_WHO2="/usr/bin/who --ips"
CMD_WHO3="/usr/bin/pinky -f -w"
CMD_WHO4="/usr/bin/last -1 -a -w | head -1"

CMD_TEE_APPEND="/usr/bin/tee -a"
CMD_IPTABLES="/sbin/iptables"

CMD_TAIL="/usr/bin/tail"
CMD_TAIL_LOG_MONITOR="/usr/bin/tail -2f"

CMD_CHOWN="/bin/chown"
CMD_CHMOD="/bin/chmod"

CMD_CCZE="/usr/bin/ccze"
CMD_CCZE_PARAM="-A"

###
### Variavel que indica que este common-setup foi rodado
###
COMMON_SETUP_VERIF="ok"

###
### CHAMA SCRIPT DE CUSTOMIZACAO DE AMBIENTE
### Tudo que foi definido acima pode ser redefinido no custom-setup.sh.
###
if [ -e ${COMMONDIR} ] ; then 
	. ${COMMONDIR}/custom/custom-setup.sh
fi

make_dir_if_not_exists ${SYNC_BKP_SWAP}
make_dir_if_not_exists ${COMMONDIR_AUX}
make_dir_if_not_exists ${LOG_PATH}

###
### INICIALIZACAO DO AMBIENTE
###
if [[ "x$CUSTOMLOG" == "x" ]] ; then
	LOG_OUTPUT="${LOG_PATH}/${MYNME%.*}_${DATAHORAHJPREC}.log"
else
	LOG_OUTPUT="${CUSTOMLOG}"
fi

USRDATA=$(eval ${CMD_WHO1})
if [[ "x${USRDATA}" == "x" ]] ; then
	USRDATA=$(eval ${CMD_WHO2})
	if [[ "x${USRDATA}" == "x" ]] ; then
		USRDATA=$(eval ${CMD_WHO3})
		if [[ "x${USRDATA}" == "x" ]] ; then
			USRDATA=$(eval ${CMD_WHO4})
			if [[ "x${USRDATA}" == "x" ]] ; then
				USRDATA="Nao logado? ${SUDOUSER:-$USER} (init)"
			fi
		fi
	fi
fi

set_error $ERR_SUCCESS
#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

INSTANCE_NAME="apache2"

DEV_USER="sso"
DEV_GROUP="devadm"

AS_USER="www-data"
AS_GROUP="www-data"

AS_BASE_PATH="/usr/local/apache2"
AS_BIN_PATH="${AS_BASE_PATH}/bin"
AS_LOG_PATH="/var/log/apache2"

CMD_CUSTOM_START="${AS_BIN_PATH}/apachectl start"
CMD_CUSTOM_STOP="${AS_BIN_PATH}/apachectl stop"

EXPR_PID_FIND="ps -ef | grep /usr/local/apache2/bin/httpd | grep ${INSTANCE_NAME} | grep root | grep -v grep | grep -v /bin/bash | grep -v ${MYNME} | sed 's/\s\s*/ /g' | cut -d ' ' -f2"

## START_TIMEOUT pode ser customizado, mas tem valores padrao no common-setup
START_TIMEOUT=35
EXPR_LOG_STARTUP="${COMMONDIR}/util-log-monitor.sh -e \"AH00489: Apache.*resuming normal operations\" -L /var/log/apache2/error_log -t ${START_TIMEOUT}"

## Customiza o colorizador de log, mantendo os parametros originais
CMD_CCZE_PARAM="${CMD_CCZE_PARAM} -p httpd"
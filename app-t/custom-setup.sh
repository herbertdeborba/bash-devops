#!/bin/bash

###
### Custom setup para scripts de gerenciamento. Esse script deve ser 
### mantido de forma que fique independente de instâncias.
###
### Uma maneira de entender este custom-setup é considerar que aqui
### devem estar os parâmetros referentes a todo o sistema operacional.
### 
### Para customizar para uma instância específica, devem ser utilizados
### os "custom/custom-init-<instancia>.sh".
###
### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

if [[ ${COMMON_SETUP_VERIF} == "" ]] ; then echo "Este script nao deve ser executado diretamente." ; exit ; fi

##
## CUSTOMIZAÇÃO ~ Podem mudar de acordo com o tipo de servidor
##

## Define se o log deve ser mostrado ao rodar um comando, além de ser
## escrito em disco
OPT_RUN_LOG="sim"

##
## Paths
##

## Deve definir usuários de gerenciamento geral
## Usuário de servidor de aplicação e instâncias devem ser definidos
## nos custom-setup-<instancia>.sh
ADM_USER="sso"
ADM_GROUP="sysadm"
DEV_GROUP="devadm"

EMAILREPLY="dti.sso@tjsc.jus.br"
EMAILTO="dti.sso@tjsc.jus.br"

## COMMONDIR_AUX é o diretório onde são gravados logs de execução 
## e arquivos temporários
COMMONDIR_AUX="/opt/devops_aux"
LOG_PATH="/var/log/devops"

##
## TIMEOUTS ~ modificar em casos extraordinários
##
STOP_TIMEOUT=40
START_TIMEOUT=30
STOP_TIMEOUT_DELAY=0.5
START_TIMEOUT_DELAY=0.5
DELAY_KILL=10
DELAY_BRUTE=5
DELAY_START=3

##
## SYNC DE SCRIPTS
##

##
## SYNC DE SCRIPTS COMMON
##
SYNC_HOST="10.17.5.144"
SYNC_SRC="${COMMONDIR}/"
SYNC_USR="sso"
SYNC_BKP="${COMMONDIR_AUX}/backup/scripts"
SYNC_BKP_SWAP="${COMMONDIR_AUX}/backup/permuta"

##
## SYNC DE SCRIPTS CUSTOM
##
CUSTOM_SYNC_HOST=${SYNC_HOST}
CUSTOM_SYNC_SRC="${COMMONDIR}/custom/"
CUSTOM_SYNC_USR=${SYNC_USR}
CUSTOM_SYNC_BKP="${COMMONDIR_AUX}/backup/scripts/custom"

##
## ROOT SYNC SETUP
##
ROOT_SYNC_HOST=${SYNC_HOST}
ROOT_SYNC_USR=${SYNC_USR}
ROOT_SYNC_BKP="${COMMONDIR_AUX}/backup/root"

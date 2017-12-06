#!/bin/bash

### Author:
### Herbert Mattei de Borba <herbert@tjsc.jus.br>
###
### V 2.0 DEVOPS 2017
###

if [[ ${COMMON_SETUP_VERIF} == "" ]] ; then echo "Este script nao deve ser executado diretamente." ; exit ; fi

## Deve ser utilizado em casos raros onde alguma das 
## common-permissions.sh serão redefinidas
##
## Permissões de instâncias devem ser tratadas nas novas
## custom-permissions-<instancia>.sh

#AS_PATHS=${AS_BASE_PATH}

### AS PATHS
#IN=${AS_PATHS}
#OIFS=$IFS
#IFS=':'
#arr2=$IN

#for aspath in $arr2 ; do
#		if [ -d $aspath ] ; then
#			$CMD_CHOWN -R ${AS_USER}:${ADM_GROUP} ${aspath} && chmod -R 775 ${aspath} 
#		else
#			echo "AVISO: $aspath não existe neste servidor."
#		fi
#done

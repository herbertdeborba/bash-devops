#!/bin/bash

##
## REGRAS CUSTOMIZADAS PARA O IPTABLES 
## 
## Este script é um fragmento que será utilizado pelo /etc/init.d/iptables start
##

IPTABLES=/sbin/iptables

function iptables_init {
echo ""
	## Exemplo
	## ACESSO A TJWEB
	#$IPTABLES -A OUTPUT -o eth0 -p tcp -d 172.17.6.0/24 -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
	#$IPTABLES -A INPUT -i eth0 -p tcp -s 172.17.6.0/24 -m multiport --sports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
}
	
iptables_init

exit $?

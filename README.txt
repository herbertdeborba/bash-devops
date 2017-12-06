

							"DEVOPS"
		SCRIPTS PARA ADMINISTRAÇÃO DE SISTEMAS OPERACIONAIS
					E SERVIDORES DE APLICAÇÃO


O QUE SÃO?

São procedimentos disponibilizados nos sistemas operacionais, que, integrados com um conjunto de configurações de autenticação e permissão, permitem a execução de tarefas administrativas de forma prática, segura e padronizada.

Estes procedimentos promovem praticidade pois determinados processos que demandam complexidade são abstraídos em "comandos" simples e acessíveis. Promovem segurança pois é possível disponibilizar os comandos de administração até mesmo para usuários sem poder de  total sobre o sistema operacional de forma monitorada, com geração de logs e notificações por email das operações executadas. Por fim, promovem padronização pois toda vez que uma operação administrativa for executada através deles será da maneira como foi definida,  com validações que praticamente eliminam a incidência de erros.


ONDE ESTÃO?

/opt/devops: Diretório com scripts genéricos.
/opt/devops/custom: Diretório de scripts customizados por servidor e artefatos extras.
/opt/devops_aux: Logs, backup e arquivos temporários.


COMO UTILIZÁ-LOS?

Geralmente será necessário executar um script através do comando "sudo". O administrador do sistema pode optar por criar aliases para as chamadas dos procedimentos, simplificando a utilização.


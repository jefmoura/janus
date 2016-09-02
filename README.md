# Janus

Janus(em Latin: *Ianus*) é o deus dos inícios e transições, e, assim, de portões, portas, passagens e finais. Ele é geralmente descrito como tendo duas faces, uma vez que ele olha para o futuro e para o passado. O maior monumento em sua glória se encontra em Roma e tem o nome de Ianus Geminus.[Wikipedia](https://en.wikipedia.org/wiki/Janus)
Janus também é uma aplicação para automatizar a manutenção dos esquemas de bancos de dados. Com ele é possível manter as tabelas de vários bancos atualizadas, comparando o banco de dados local com um remoto. Leva em consideração que o banco remoto é o mais recente e o local é o que deverá ser atualizado, assim todas alterações que forem feitas no banco de dados remoto serão replicadas no banco local, mantendo as estruturas iguais **sempre**.

## Instalação
1. Para que o sistema funcione terá que indicar algumas configurações. Na pasta *conf/*, faça:
   - No arquivo **db.cfg** liste os bancos que deseja manter atualizados. (ps.: os bancos remotos e locais tem que ter o mesmo nome)
   - No arquivo **janus.cfg**, apenas indique a URL de acesso do banco de dados remoto em *REMOTEDB_URL*
   - Se desejar mudar a frequência de atualização/verificação dos bancos, altere no arquivo job.cfg

2. Depois para instalar o programa basta executar *Janus.sh* com o parametro *install*.
```
/bin/sh installJanus.sh
```

## Extra
- A aplicação utiliza um agendador para que o proprio sistema operacional execute-o.
- Caso deseje atualizar a lista de bancos que deseja manter atualizados, faça:
   - Edite o arquivo que lista os bancos de dados;
   - Execute o programa com o parametro *update-dbs*

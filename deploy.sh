#!/bin/bash

USER={{YOUR_USER}}
HOST={{YOUR_HOST}}
DIR_PROD=/opt/production/
DIR_BETA=/opt/beta/

function restart_servers_beta
{
  echo "restarting servers..."

  ssh $USER@$HOST "pkill -f 127.0.0.1:9000"

  ssh $USER@$HOST "
    source .virtualenvs/beta/bin/activate
    export ENV_PROJECT=BETA
    pip install -r ${DIR_BETA}requirements.txt
    python ${DIR_BETA}project/manage.py migrate
    python ${DIR_BETA}project/manage.py collectstatic
    cd ${DIR_BETA}project/ && gunicorn -b 127.0.0.1:9000 project.wsgi:application&
    echo 'done!'
  "
}

function restart_servers_prod
{
  echo "restarting servers..."

  ssh $USER@$HOST "pkill -f 127.0.0.1:8000"

  ssh $USER@$HOST " 
    source .virtualenvs/production/bin/activate
    export ENV_PROJECT=PRODUCTION
    pip install -r ${DIR_PROD}requirements.txt
    python ${DIR_PROD}project/manage.py migrate
    python ${DIR_PROD}project/manage.py collectstatic
    cd ${DIR_PROD}project/ && gunicorn project.wsgi:application&
    echo 'done!'
  "
}

function deploy_application
{
  LC_CTYPE="en_US.UTF-8"

  if [ "$1" == "prod" ]; then
    git push production master
    restart_servers_prod
  else
    git push beta master
    restart_servers_beta
  fi
}

if [ "$1" ==  "--environment" ] || [ "$1" == "-e" ]; then
  deploy_application $2 
else
  echo "
    Usage:
    ./deploy.sh <options>

    Options:
      -e | --environment    accept prod or beta
  "
fi


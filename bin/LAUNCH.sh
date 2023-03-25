#!/bin/bash

GREEN="\\033[1;32m"
DEFAULT="\\033[0;39m"
RED="\\033[1;31m"
ROSE="\\033[1;35m"
BLUE="\\033[1;34m"
WHITE="\\033[0;02m"
YELLOW="\\033[1;33m"
CYAN="\\033[1;36m"

# Getting CWD where bash script resides
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd |sed 's/bin//' )"
export AIL_HOME="${DIR}"

cd ${AIL_HOME}

if [ -e "${DIR}/AILENV/bin/python" ]; then
    ENV_PY="${DIR}/AILENV/bin/python"
    export AIL_VENV=${AIL_HOME}/AILENV/
    . ./AILENV/bin/activate
else
    echo "Please make sure you have a AIL-framework environment, au revoir"
    exit 1
fi

export PATH=$AIL_VENV/bin:$PATH
export PATH=$AIL_HOME:$PATH
export PATH=$AIL_REDIS:$PATH
export PATH=$AIL_ARDB:$PATH
export PATH=$AIL_BIN:$PATH
export PATH=$AIL_FLASK:$PATH

isredis=`screen -ls | egrep '[0-9]+.Redis_AIL' | cut -d. -f1`
isardb=`screen -ls | egrep '[0-9]+.ARDB_AIL' | cut -d. -f1`
islogged=`screen -ls | egrep '[0-9]+.Logging_AIL' | cut -d. -f1`
isqueued=`screen -ls | egrep '[0-9]+.Queue_AIL' | cut -d. -f1`
is_ail_core=`screen -ls | egrep '[0-9]+.Core_AIL' | cut -d. -f1`
is_ail_2_ail=`screen -ls | egrep '[0-9]+.AIL_2_AIL' | cut -d. -f1`
isscripted=`screen -ls | egrep '[0-9]+.Script_AIL' | cut -d. -f1`
isflasked=`screen -ls | egrep '[0-9]+.Flask_AIL' | cut -d. -f1`
iscrawler=`screen -ls | egrep '[0-9]+.Crawler_AIL' | cut -d. -f1`
isfeeded=`screen -ls | egrep '[0-9]+.Feeder_Pystemon' | cut -d. -f1`

function helptext {
    echo -e $YELLOW"

              .o.            ooooo      ooooo
             .888.           \`888'      \`888'
            .8\"888.           888        888
           .8' \`888.          888        888
          .88ooo8888.         888        888
         .8'     \`888.        888        888       o
        o88o     o8888o   o  o888o   o  o888ooooood8

         Analysis Information Leak framework
    "$DEFAULT"
    This script launch:
    "$CYAN"
    - All the queuing modules.
    - All the processing modules.
    - All Redis in memory servers.
    - All ARDB on disk servers.
    "$DEFAULT"
    (Inside screen Daemons)
    "$DEFAULT"
    Usage:
    -----
    LAUNCH.sh
      [-l  | --launchAuto]         LAUNCH DB + Scripts
      [-k  | --killAll]            Kill DB + Scripts
      [-ks | --killscript]         Scripts
      [-u  | --update]             Update AIL
      [-ut | --thirdpartyUpdate]   Update UI/Frontend
      [-t  | --test]               Launch Tests
      [-rp | --resetPassword]      Reset Password
      [-f  | --launchFeeder]       LAUNCH Pystemon feeder
      [-m  | --menu]               Display Advanced Menu
      [-h  | --help]               Help
    "
}

function launching_redis {
    conf_dir="${AIL_HOME}/configs/"

    screen -dmS "Redis_AIL"
    sleep 0.1
    echo -e $GREEN"\t* Launching Redis servers"$DEFAULT
    screen -S "Redis_AIL" -X screen -t "6379" bash -c 'redis-server '$conf_dir'6379.conf ; read x'
    sleep 0.1
    screen -S "Redis_AIL" -X screen -t "6380" bash -c 'redis-server '$conf_dir'6380.conf ; read x'
    sleep 0.1
    screen -S "Redis_AIL" -X screen -t "6381" bash -c 'redis-server '$conf_dir'6381.conf ; read x'
}

function launching_ardb {
    conf_dir="${AIL_HOME}/configs/"

    screen -dmS "ARDB_AIL"
    sleep 0.1
    echo -e $GREEN"\t* Launching ARDB servers"$DEFAULT

    sleep 0.1
    screen -S "ARDB_AIL" -X screen -t "6382" bash -c 'cd '${AIL_HOME}'; ardb-server '$conf_dir'6382.conf ; read x'
}

function launching_logs {
    conf_dir="${AIL_HOME}/configs/"
    syslog_cmd=""
    syslog_enabled=`cat $conf_dir/core.cfg | grep 'ail_logs_syslog' | cut -d " " -f 3 `
    if [ "$syslog_enabled" = "True" ]; then
      syslog_cmd="--syslog"
    fi
    syslog_server=`cat $conf_dir/core.cfg | grep 'ail_logs_syslog_server' | cut -d " " -f 3 `
    syslog_port=`cat $conf_dir/core.cfg | grep 'ail_logs_syslog_port' | cut -d " " -f 3 `
    if [ ! -z "$syslog_server" -a "$str" != " " ]; then
        syslog_cmd="${syslog_cmd} -ss ${syslog_server}"
        if [ ! -z "$syslog_port" -a "$str" != " " ]; then
            syslog_cmd="${syslog_cmd} -sp ${syslog_port}"
        fi
    fi
    syslog_facility=`cat $conf_dir/core.cfg | grep 'ail_logs_syslog_facility' | cut -d " " -f 3 `
    if [ ! -z "$syslog_facility" -a "$str" != " " ]; then
        syslog_cmd="${syslog_cmd} -sf ${syslog_facility}"
    fi
    syslog_level=`cat $conf_dir/core.cfg | grep 'ail_logs_syslog_level' | cut -d " " -f 3 `
    if [ ! -z "$syslog_level" -a "$str" != " " ]; then
        syslog_cmd="${syslog_cmd} -sl ${syslog_level}"
    fi

    screen -dmS "Logging_AIL"
    sleep 0.1
    echo -e $GREEN"\t* Launching logging process"$DEFAULT
    screen -S "Logging_AIL" -X screen -t "LogQueue" bash -c "cd ${AIL_BIN}; ${AIL_VENV}/bin/log_subscriber -p 6380 -c Queuing -l ../logs/ ${syslog_cmd}; read x"
    sleep 0.1
    screen -S "Logging_AIL" -X screen -t "LogScript" bash -c "cd ${AIL_BIN}; ${AIL_VENV}/bin/log_subscriber -p 6380 -c Script -l ../logs/ ${syslog_cmd}; read x"
    sleep 0.1
    screen -S "Logging_AIL" -X screen -t "LogScript" bash -c "cd ${AIL_BIN}; ${AIL_VENV}/bin/log_subscriber -p 6380 -c Sync -l ../logs/ ${syslog_cmd}; read x"
}

function launching_queues {
    screen -dmS "Queue_AIL"
    sleep 0.1

    echo -e $GREEN"\t* Launching all the queues"$DEFAULT
    screen -S "Queue_AIL" -X screen -t "Queues" bash -c "cd ${AIL_BIN}; ${ENV_PY} launch_queues.py; read x"
}

function checking_configuration {
    bin_dir=${AIL_HOME}/bin
    echo -e "\t* Checking configuration"
    bash -c "${ENV_PY} $bin_dir/Update-conf.py"
    exitStatus=$?
    if [ $exitStatus -ge 1 ]; then
        echo -e $RED"\t* Configuration not up-to-date"$DEFAULT
        exit
    fi
    echo -e $GREEN"\t* Configuration up-to-date"$DEFAULT
}

function launching_scripts {
    checking_configuration;

    screen -dmS "Script_AIL"
    sleep 0.1

    ##################################
    #         CORE MODULES           #
    ##################################
    # screen -dmS "Core_AIL"
    # sleep 0.1
    echo -e $GREEN"\t* Launching core scripts ..."$DEFAULT

    # TODO: MOOVE IMPORTER ????  => multiple scripts

    #### SYNC ####
    screen -S "Script_AIL" -X screen -t "Sync_importer" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./Sync_importer.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "ail_2_ail_server" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./ail_2_ail_server.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Sync_manager" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./Sync_manager.py; read x"
    sleep 0.1
    ##-- SYNC --##

    screen -S "Script_AIL" -X screen -t "JSON_importer" bash -c "cd ${AIL_BIN}/import; ${ENV_PY} ./JSON_importer.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Crawler_manager" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./Crawler_manager.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "D4_client" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./D4_client.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "DbCleaner" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./DbCleaner.py; read x"
    sleep 0.1

    screen -S "Script_AIL" -X screen -t "UpdateBackground" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./update-background.py; read x"
    sleep 0.1

    ##################################
    #           MODULES              #
    ##################################
    # screen -dmS "Script_AIL"
    # sleep 0.1
    echo -e $GREEN"\t* Launching scripts"$DEFAULT

    screen -S "Script_AIL" -X screen -t "Global" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Global.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Categ" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Categ.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Indexer" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Indexer.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Tags" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Tags.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "SubmitPaste" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./submit_paste.py; read x"
    sleep 0.1

    screen -S "Script_AIL" -X screen -t "Sync_module" bash -c "cd ${AIL_BIN}/core; ${ENV_PY} ./Sync_module.py; read x"
    sleep 0.1

    screen -S "Script_AIL" -X screen -t "ApiKey" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./ApiKey.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Credential" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Credential.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "CreditCards" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./CreditCards.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Decoder" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Decoder.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Keys" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Keys.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Onion" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Onion.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "SentimentAnalysis" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./SentimentAnalysis.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Telegram" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Telegram.py; read x"
    sleep 0.1

    screen -S "Script_AIL" -X screen -t "Hosts" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Hosts.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "DomClassifier" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./DomClassifier.py; read x"
    sleep 0.1

    screen -S "Script_AIL" -X screen -t "Urls" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Urls.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "SQLInjectionDetection" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./SQLInjectionDetection.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "LibInjection" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./LibInjection.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Zerobins" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Zerobins.py; read x"
    sleep 0.1

    ##################################
    #       TRACKERS MODULES         #
    ##################################
    screen -S "Script_AIL" -X screen -t "Tracker_Typo_Squatting" bash -c "cd ${AIL_BIN}/trackers; ${ENV_PY} ./Tracker_Typo_Squatting.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Tracker_Term" bash -c "cd ${AIL_BIN}/trackers; ${ENV_PY} ./Tracker_Term.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Tracker_Regex" bash -c "cd ${AIL_BIN}/trackers; ${ENV_PY} ./Tracker_Regex.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Tracker_Yara" bash -c "cd ${AIL_BIN}/trackers; ${ENV_PY} ./Tracker_Yara.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Retro_Hunt" bash -c "cd ${AIL_BIN}/trackers; ${ENV_PY} ./Retro_Hunt.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Retro_Hunt" bash -c "cd ${AIL_BIN}/trackers; ${ENV_PY} ./Retro_Hunt.py; read x"
    sleep 0.1

    ##################################
    #       DISABLED MODULES         #
    ##################################
    #screen -S "Script_AIL" -X screen -t "Phone" bash -c "cd ${AIL_BIN}/modules; ${ENV_PY} ./Phone.py; read x"
    #sleep 0.1

    ##################################
    #                                #
    ##################################
    screen -S "Script_AIL" -X screen -t "ModuleInformation" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./ModulesInformationV2.py -k 0 -c 1; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Mixer" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Mixer.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Duplicates" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Duplicates.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "BankAccount" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./BankAccount.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Mail" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Mail.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "PgpDump" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./PgpDump.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Cryptocurrency" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Cryptocurrencies.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Tools" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Tools.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Cve" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Cve.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "ModuleStats" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./ModuleStats.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "MISPtheHIVEfeeder" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./MISP_The_Hive_feeder.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "Languages" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Languages.py; read x"
    sleep 0.1
    screen -S "Script_AIL" -X screen -t "IPAddress" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./IPAddress.py; read x"

    #screen -S "Script_AIL" -X screen -t "Release" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./Release.py; read x"
    #sleep 0.1

}

function shutting_down_redis {
    redis_dir=${AIL_HOME}/redis/src/
    bash -c $redis_dir'redis-cli -p 6379 SHUTDOWN'
    sleep 0.1
    bash -c $redis_dir'redis-cli -p 6380 SHUTDOWN'
    sleep 0.1
    bash -c $redis_dir'redis-cli -p 6381 SHUTDOWN'
}

function shutting_down_ardb {
    redis_dir=${AIL_HOME}/redis/src/
    bash -c $redis_dir'redis-cli -p 6382 SHUTDOWN'
}

function checking_redis {
    flag_redis=0
    redis_dir=${AIL_HOME}/redis/src/
    bash -c $redis_dir'redis-cli -p 6379 PING | grep "PONG" &> /dev/null'
    if [ ! $? == 0 ]; then
        echo -e $RED"\t6379 not ready"$DEFAULT
        flag_redis=1
    fi
    sleep 0.1
    bash -c $redis_dir'redis-cli -p 6380 PING | grep "PONG" &> /dev/null'
    if [ ! $? == 0 ]; then
        echo -e $RED"\t6380 not ready"$DEFAULT
        flag_redis=1
    fi
    sleep 0.1
    bash -c $redis_dir'redis-cli -p 6381 PING | grep "PONG" &> /dev/null'
    if [ ! $? == 0 ]; then
        echo -e $RED"\t6381 not ready"$DEFAULT
        flag_redis=1
    fi
    sleep 0.1

    return $flag_redis;
}

function checking_ardb {
    flag_ardb=0
    redis_dir=${AIL_HOME}/redis/src/
    sleep 0.2
    bash -c $redis_dir'redis-cli -p 6382 PING | grep "PONG" &> /dev/null'
    if [ ! $? == 0 ]; then
        echo -e $RED"\t6382 ARDB not ready"$DEFAULT
        flag_ardb=1
    fi

    return $flag_ardb;
}

function wait_until_redis_is_ready {
    redis_not_ready=true
    while $redis_not_ready; do
        if checking_redis; then
            redis_not_ready=false;
        else
            sleep 1
        fi
    done
    echo -e $YELLOW"\t* Redis Launched"$DEFAULT
}

function wait_until_ardb_is_ready {
    ardb_not_ready=true;
    while $ardb_not_ready; do
        if checking_ardb; then
            ardb_not_ready=false
        else
            sleep 3
        fi
    done
    echo -e $YELLOW"\t* ARDB Launched"$DEFAULT
}

function launch_redis {
    if [[ ! $isredis ]]; then
        launching_redis;
    else
        echo -e $RED"\t* A screen is already launched"$DEFAULT
    fi
}

function launch_ardb {
    if [[ ! $isardb ]]; then
        launching_ardb;
    else
        echo -e $RED"\t* A screen is already launched"$DEFAULT
    fi
}

function launch_logs {
    if [[ ! $islogged ]]; then
        launching_logs;
    else
        echo -e $RED"\t* A screen is already launched"$DEFAULT
    fi
}

function launch_queues {
    if [[ ! $isqueued ]]; then
        launching_queues;
    else
        echo -e $RED"\t* A screen is already launched"$DEFAULT
    fi
}

function launch_scripts {
    if [[ ! $isscripted ]]; then ############################# is core
      sleep 1
        if checking_ardb && checking_redis; then
            launching_scripts;
        else
            no_script_launched=true
            while $no_script_launched; do
                echo -e $YELLOW"\tScript not started, waiting 5 more secondes"$DEFAULT
                sleep 5
                if checking_redis && checking_ardb; then
                    launching_scripts;
                    no_script_launched=false
                else
                    echo -e $RED"\tScript not started"$DEFAULT
                fi;
            done
        fi;
    else
        echo -e $RED"\t* A screen is already launched"$DEFAULT
    fi
}

function launch_flask {
    if [[ ! $isflasked ]]; then
        flask_dir=${AIL_FLASK}
        screen -dmS "Flask_AIL"
        sleep 0.1
        echo -e $GREEN"\t* Launching Flask server"$DEFAULT
        screen -S "Flask_AIL" -X screen -t "Flask_server" bash -c "cd $flask_dir; ls; ${ENV_PY} ./Flask_server.py; read x"
    else
        echo -e $RED"\t* A Flask screen is already launched"$DEFAULT
    fi
}

function launch_feeder {
    if [[ ! $isfeeded ]]; then
        screen -dmS "Feeder_Pystemon"
        sleep 0.1
        echo -e $GREEN"\t* Launching Pystemon feeder"$DEFAULT
        screen -S "Feeder_Pystemon" -X screen -t "Pystemon_feeder" bash -c "cd ${AIL_BIN}; ${ENV_PY} ./feeder/pystemon-feeder.py; read x"
        sleep 0.1
        screen -S "Feeder_Pystemon" -X screen -t "Pystemon" bash -c "cd ${AIL_HOME}/../pystemon; ${ENV_PY} ./pystemon.py; read x"
    else
        echo -e $RED"\t* A Feeder screen is already launched"$DEFAULT
    fi
}

function killscript {
    if [[ $islogged || $isqueued || $is_ail_core || $isscripted || $isflasked || $isfeeded || $iscrawler || $is_ail_2_ail ]]; then
        echo -e $GREEN"Killing Script"$DEFAULT
        kill $islogged $isqueued $is_ail_core $isscripted $isflasked $isfeeded $iscrawler $is_ail_2_ail
        sleep 0.2
        echo -e $ROSE`screen -ls`$DEFAULT
        echo -e $GREEN"\t* $islogged $isqueued $is_ail_core $isscripted $isflasked $isfeeded $iscrawler $is_ail_2_ail killed."$DEFAULT
    else
        echo -e $RED"\t* No script to kill"$DEFAULT
    fi
}

function killall {
    if [[ $isredis || $isardb || $islogged || $isqueued || $is_ail_2_ail || $isscripted || $isflasked || $isfeeded || $iscrawler || $is_ail_core ]]; then
        if [[ $isredis ]]; then
            echo -e $GREEN"Gracefully closing redis servers"$DEFAULT
            shutting_down_redis;
            sleep 0.2
        fi
        if [[ $isardb ]]; then
            echo -e $GREEN"Gracefully closing ardb servers"$DEFAULT
            shutting_down_ardb;
        fi
        echo -e $GREEN"Killing all"$DEFAULT
        kill $isredis $isardb $islogged $isqueued $is_ail_core $isscripted $isflasked $isfeeded $iscrawler $is_ail_2_ail
        sleep 0.2
        echo -e $ROSE`screen -ls`$DEFAULT
        echo -e $GREEN"\t* $isredis $isardb $islogged $isqueued $isscripted $is_ail_2_ail $isflasked $isfeeded $iscrawler $is_ail_core killed."$DEFAULT
    else
        echo -e $RED"\t* No screen to kill"$DEFAULT
    fi
}

function shutdown {
    bash -c "./Shutdown.py"
}

function update() {
    bin_dir=${AIL_HOME}/bin

    bash -c "python3 $bin_dir/Update.py $1"
    exitStatus=$?
    if [ $exitStatus -ge 3 ]; then
        echo -e "\t* Update..."
        bash -c "python3 $bin_dir/Update.py $1"
        exitStatus=$?
        if [ $exitStatus -ge 1 ]; then
            echo -e $RED"\t* Update Error"$DEFAULT
            exit
        fi
    fi

    if [ $exitStatus -ge 1 ]; then
        echo -e $RED"\t* Update Error"$DEFAULT
        exit
    fi

}

function update_thirdparty {
    echo -e "\t* Updating thirdparty..."
    bash -c "(cd ${AIL_FLASK}; ./update_thirdparty.sh)"
    exitStatus=$?
    if [ $exitStatus -ge 1 ]; then
        echo -e $RED"\t* Thirdparty not up-to-date"$DEFAULT
        exit
    else
        echo -e $GREEN"\t* Thirdparty updated"$DEFAULT
    fi
}

function launch_tests() {
  tests_dir=${AIL_HOME}/tests
  bin_dir=${AIL_BIN}
  python3 `which nosetests` -w $tests_dir --with-coverage --cover-package=$bin_dir -d --cover-erase
}

function reset_password() {
  echo -e "\t* Reseting UI admin password..."
  if checking_ardb && checking_redis; then
      python ${AIL_HOME}/var/www/create_default_user.py &
      wait
  else
      echo -e $RED"\t* Error: Please launch all Redis and ARDB servers"$DEFAULT
      exit
  fi
}

function launch_all {
    checking_configuration;
    update;
    launch_redis;
    launch_ardb;
    launch_logs;
    launch_queues;
    launch_scripts;
    launch_flask;
}

function menu_display {

  options=("Redis" "Ardb" "Logs" "Queues" "Scripts" "Flask" "Killall" "Shutdown" "Update" "Update-config" "Update-thirdparty")

  menu() {
      echo "What do you want to Launch?:"
      for i in ${!options[@]}; do
          printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
      done
      [[ "$msg" ]] && echo "$msg"; :
  }

  prompt="Check an option (again to uncheck, ENTER when done): "

  while menu && read -rp "$prompt" numinput && [[ "$numinput" ]]; do
      for num in $numinput; do
          [[ "$num" != *[![:digit:]]* ]] && (( num > 0 && num <= ${#options[@]} )) || {
              msg="Invalid option: $num"; break
          }
          ((num--)); msg="${options[num]} was ${choices[num]:+un}checked"
          [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
      done
  done

  for i in ${!options[@]}; do
      if [[ "${choices[i]}" ]]; then
          case ${options[i]} in
              Redis)
                  launch_redis;
                  ;;
              Ardb)
                  launch_ardb;
                  ;;
              Logs)
                  launch_logs;
                  ;;
              Queues)
                  launch_queues;
                  ;;
              Scripts)
                  launch_scripts;
                  ;;
              Flask)
                  launch_flask;
                  ;;
              Killall)
                  killall;
                  ;;
              Shutdown)
                  shutdown;
                  ;;
              Update)
                  checking_configuration;
                  update;
                  ;;
              Update-config)
                  checking_configuration;
                  ;;
              Update-thirdparty)
                  update_thirdparty;
                  ;;
          esac
      fi
  done

  exit

}


#If no params, display the help
[[ $@ ]] || {

    helptext;
}

#echo "$@"

while [ "$1" != "" ]; do
    case $1 in
        -l | --launchAuto )           launch_all "automatic";
                                      ;;
        -lr | --launchRedis )         launch_redis;
                                      ;;
        -la | --launchARDB )          launch_ardb;
                                      ;;
        -lrv | --launchRedisVerify )  launch_redis;
                                      wait_until_redis_is_ready;
                                      ;;
        -lav | --launchARDBVerify )   launch_ardb;
                                      wait_until_ardb_is_ready;
                                      ;;
        -k | --killAll )              killall;
                                      ;;
        -ks | --killscript )          killscript;
                                      ;;
        -m | --menu )                 menu_display;
                                      ;;
        -u | --update )               checking_configuration;
                                      update "--manual";
                                      ;;
        -t | --test )                 launch_tests;
                                      ;;
        -ut | --thirdpartyUpdate )    update_thirdparty;
                                      ;;
        -rp | --resetPassword )       reset_password;
                                      ;;
        -f | --launchFeeder )         launch_feeder;
                                      ;;
        -h | --help )                 helptext;
                                      exit
                                      ;;
        -kh | --khelp )               helptext;
                                      ;;
        * )                           helptext
                                      exit 1
    esac
    shift
done

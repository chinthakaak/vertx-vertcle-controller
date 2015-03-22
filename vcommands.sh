#!/bin/bash
##################################################################################################################################
# Title           :vcommands.sh                                                                                                  #
# Description     :This script contains set of reusable commands to setting up cluster environment for vertx based applications  #
# Author          :Kushan Athukorala                                                                                             #
# Date            :12-Sept-2014                                                                                                  #
# Version         :0.1                                                                                                           #
# Usage           :bash vcommands.sh                                                                                             #
# Notes           :refer vcommands-readme.txt for more details                                                                   #
# Bash version    :4.1.2(1)-release (x86_64-redhat-linux-gnu)                                                                    #
##################################################################################################################################
propertyfile=/home/ka40215/vcommands.properties

. $propertyfile

nodes=(`grep ^node $propertyfile | sed -e 's/^node.=//g'`)
users=(`grep ^username $propertyfile | sed -e 's/^username.=//g'`)
mods=(${mods//,/ })
gtexts=(${gtexts//,/ })

declare -A modtextmap;

#set -e
#set -xv
#echo ${nodes[@]}
#echo ${users[@]}
#echo ${mods[1]}

############ Public functions #############
vstart(){
    ## Processing command line options
	__getopts $@
	__createmodtextmap
	__checkmodules
	if [ $? != 0 ];then return 1; fi

	if [ ${#modules_arr[@]} != ${#instances_arr[@]} ]
		then 
			wrn "Number of modules   : "${#modules_arr[@]}
			wrn "Number of instances : "${#instances_arr[@]}
			err "Number of modules should be same as the number of instances ...";
			__printUsage
		    #exit 0;
		    return 4;
	fi
	
	## Stoping running verticles 
	vstop $@

	## Staring verticles
	for node in "${nodes_arr[@]}"
	  do
            for ((i=0 ; i<${#modules_arr[@]}; ++i));
             do
                __vstart ${users[$node - 1]} ${nodes[$node - 1]} ${modules_arr[$i]} ${instances_arr[$i]}
             done
	  done
}

vstop(){
	## Processing command line options
	__getopts $@
	__createmodtextmap
	__checkmodules

	## Stoping running verticles 
	for node in "${nodes_arr[@]}"
	  do
            for ((i=0 ; i<${#modules_arr[@]}; ++i));
             do
                __killProcess ${users[$node - 1]} ${nodes[$node - 1]} ${modtextmap[${modules_arr[$i]}]}
             done
	  done
}

vstatus(){
	## set text format
	__setformat

	## Processing command line options
	__getopts $@

	## Status checking running verticles
	for node in "${nodes_arr[@]}"
	  do
            #for ((i=0 ; i<${#modules_arr[@]}; ++i));
             #do
             if [ ${#modules_arr[@]} -gt 0 ];
                then
                    __createmodtextmap
                    __checkmodules
                    if [ $? != 0 ];then return 1; fi

                    printf "${b}node:${nodes[$node - 1]}${n}\n"

                    for ((i=0 ; i<${#modules_arr[@]}; ++i));
                        do

                            processId=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf java | grep ${modtextmap[${modules_arr[$i]}]}| awk '{print $1}'`
	                        #instances=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf java | grep ${modtextmap[${modules_arr[$i]}]}| awk '{print $(NF-2)}'`
	                        instances=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf java | grep ${modtextmap[${modules_arr[$i]}]}| awk -F1 '/-instances/ {f=NR} f&&NR-1==f' RS=" "`

                           if [ ! -z $processId ] && [ ! -z $instances ];
                             then status="${GREEN}${b}STARTED${n}${NONE}"
                             else status=""
                           fi


                           printf "${modules_arr[$i]}:$processId:$instances:$status\n"
                        done

                else

                    printf "${b}node:${nodes[$node - 1]}${n}\n"

                    for ((j=0 ; j<${#mods[@]}; ++j));
                        do
                           processId=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf java | grep ${gtexts[$j]}| awk '{print $1}'`
	                       #instances=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf java | grep ${gtexts[$j]}| awk '{print $(NF-2)}'`
                           instances=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf java | grep ${gtexts[$j]}| awk -F1 '/-instances/ {f=NR} f&&NR-1==f' RS=" "`

                           if [ ! -z $processId ] && [ ! -z $instances ];
                             then status="${GREEN}${b}STARTED${n}${NONE}"
                             else status=""
                           fi

                           printf "${mods[$j]}:$processId:$instances:$status\n"
                        done

             fi
      done
}

vcstatus(){
echo
}

vcstart(){ 
echo
}
vcstop(){
echo
}

vpgstart(){
echo
}
vpgstop(){
echo
}

vmstart(){
echo
}

vmstop(){
echo
}

################Private functions#############
__vstatus(){
echo

}
__checkmodules(){
    not_in_mods=()

    for item1 in "${modules_arr[@]}"; do
        for item2 in "${mods[@]}"; do
            [[ $item1 == "$item2" ]] && continue 2
        done

        # If we reached here, nothing matched.
        not_in_mods+=( "$item1" )
    done

    if [ ${#not_in_mods[@]} -gt 0 ];
      then
        err "Invalid module found : ${not_in_mods[@]}"
        return 6;
#        exit 0;
    fi
}

__createmodtextmap(){

    for ((i=0 ; i<${#mods[@]}; ++i));
      do
        modtextmap[${mods[i]}]=${gtexts[i]};
        deb "module index $i"
      done

    for j in "${!modtextmap[@]}"
      do
        deb "key  : $j"
        deb "value: ${modtextmap[$j]}"
      done

}
__killProcess(){
    if [ -z $3 ];
      then
        err "Invalid module name"
        return 10;
    fi

	processId=`ssh $1@$2 pgrep -lf java | grep $3| awk '{print $1}'`
	ssh $1@$2 kill -9 $processId
	inf "Server: $2 Process ID: $processId Module: $3 was successfully terminated"
	inf "Server: $2 Process ID: $processId Module: $3 was terminated"
}

__vstatusall(){
echo
}
__getmods(){
	cd $appname
	mods=($(ls))
	cd ~
	echo ${mods[3]}
}

__getopts(){
	b=`tput bold`
	n=`tput sgr0`
	NONE='\033[00m'
	RED='\033[01;31m'
	GREEN='\033[01;32m'
	if [ $# -eq 0 ]
	  then
        __printUsage
	fi

	nodes_arr=();
	modules_arr=();
	instances_arr=();

	while [ "$1" != "" ]; do
	    case $1 in
		-n )deb "${FUNCNAME} : Next command line argument is $@"
		    inf "Creating nodes array";
            shift
            deb "${FUNCNAME} : Next command line argument is $@"

            if [ $# == 0 ];
                 then err "No nodes are given as arguments ...";
                 __printUsage
                 #exit 0;
                 return 1;
            fi;

           	while [[ $1 == [0-9]* ]]; do
				deb "${nodes[$1 - 1]} added";
				nodes_arr+=($1);
				shift; 
			done

		        ;;
		-m )shift
			inf "Creating modules array";
			deb "${FUNCNAME} : Next command line argument is $@"
			if [ $# == 0 ];
                 then err "No modues are given as arguments ..";
                 __printUsage
                 #exit 0;
                 return 2;
            fi;
			while [[ $1 == [a-zA-Z]* ]]; do 
				inf "$1 module added";
				modules_arr+=($1);
				shift; 
			done
	
		        ;;
		-i )shift
			inf "Creating instances array";
			if [ $# == 0 ];
                 then err "No number of instances are given as arguments ..";
                 __printUsage
                 #exit 0;
                 return 3;
            fi;
			while [[ $1 == [0-9]* ]]; do 
				inf "instance $1 added";
				instances_arr+=($1);
				shift; 
			done 
		;;

		* ) __printUsage
			shift
		    
	    esac
	done
}

__getvcommand(){
	if [ $# -eq 0 ]
	  then __printUsage
	fi

	nodes_arr=();
	modules_arr=();
	instances_arr=();

	while [ "$1" != "" ]; do
	    case $1 in
	    vstart ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vstart $@
	            for a in "$@"; do shift; done
	            ;;

	    vstop ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vstop $@
	            for a in "$@"; do shift; done
	            ;;
	    vstatus ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vstatus $@
	            for a in "$@"; do shift; done
	            ;;

		* ) err "Invalid ${b}vcommand${n} or argument ..."
		    deb "${FUNCNAME} : Next command line argument is $@"
		    __printUsage
			shift

	    esac
	done
}

__printUsage(){

    USAGE1="${b}Usage1:${n} ./vcommands.sh <vcommand> [-n nodes [-m modules [-i instances]]"
    USAGE2="${b}Usage2:${n} <vcommand> [-n nodes [-m modules [-i instances]] after sourcing the vcommands.sh in current shell - source vcommands.sh"
    USAGE3="${b}Usage3:${n} <vcommand> [-n nodes [-m modules [-i instances]] after sourcing the vcommands.sh by adding to .bashrc - source vcommands.sh in .bashrc"

    VCOMMANDS="${b}Note:${n} <vcommand> in any ${b}Usage${n} should be replaced with vstart, vstop, vtail, vcstart, etc ..."

    echo $USAGE1
    echo $USAGE2
    echo $USAGE3
    echo
    echo $VCOMMANDS
}

__vstart(){

	ssh $1@$2 "\
	cd $applocation/$3;\
		
	sed -i 's/-instances [0-9]*/-instances $4/g' start.sh;\
	echo "Server: $2, number of instances were set to $4 ...";\
        source ~/.bash_profile;\
        nohup ./start.sh > nohup.out 2>&1 &"
}

__setformat(){
    b=`tput bold`
    n=`tput sgr0`
    NONE='\033[00m'
    RED='\033[01;31m'
    GREEN='\033[01;32m'
}
############# Logging ##############
wrn()
{
	if [ ! -f ~/vcommands.log ];
		then touch ~/vcommands.log;
	fi
	if [ $loglevel == "info" ] || [ $loglevel == "warn" ] || [ $loglevel == "error" ] || [ $loglevel == "debug" ];
	  then echo -e "`date +"%Y-%m-%d %T"` [WARN] : $1" |tee -a   $loglocation/vcommands.log
	fi
}

err()
{
	if [ ! -f ~/vcommands.log ];
		then touch vcommands.log;
	fi
	if [ $loglevel == "info" ] || [ $loglevel == "error" ] || [ $loglevel == "debug" ];
	  then echo -e "`date +"%Y-%m-%d %T"` [ERROR] : $1" |tee -a  $loglocation/vcommands.log
	fi
}

inf()
{
	if [ ! -f ~/vcommands.log ];
		then touch ~/vcommands.log;
	fi
	if [ $loglevel == "info" ] || [ $loglevel == "debug" ];
	  then echo -e "`date +"%Y-%m-%d %T"` [INFO] : $1" >>  $loglocation/vcommands.log
	fi
}

deb()
{
	if [ ! -f ~/vcommands.log ];
		then touch ~/vcommands.log;
	fi
	if [ $loglevel == "debug" ];
	  then echo -e "`date +"%Y-%m-%d %T"` [DEBUG] : $1" >> $loglocation/vcommands.log
	fi
}



ext()
{
	echo "$1" 1>&2
	exit 1
}

############End Functions #########

#__getvcommand $@

#vstart -n 1 4 -m pay ide -i 1 3
#vstart -n 1 -m pay ide

#vstop -n 1 2 4 -m payment idempotency
#vstart -n 1 -m payment idempotency -i 1 4
#vstart -n 1
#__getmods
#killVerticle
#ssh ${bridgeuser}@${bridgeserver}
#ls

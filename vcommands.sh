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
currentlocation=`pwd`

propertyfile=$currentlocation/vcommands.properties

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
	## Processing command line options
	__getopts $@

    ## set text format
    __setformat

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

vkstart(){
	## Processing command line options
	__getopts $@

    ## stop ksar
    #vkstop $@

	#timestamp

	for node in "${nodes_arr[@]}"
	  do
	    timestamp=`ssh ${users[$node - 1]}@${nodes[$node - 1]} date +"%Y.%m.%d.%S.%N"| awk '{print $1}'`
	    deb $timestamp
        ssh ${users[$node - 1]}@${nodes[$node - 1]} "\
        rm -rf sar-${nodes[$node - 1]};\
        LC_ALL=C sar -o sar-${nodes[$node - 1]} ${ksarinterval} >/dev/null 2>&1 &"
      done
#    echo
#    LC_ALL=C sar -A -s 16:10:00 -e 05:00:00 > sar.data.txt
#
#    LC_ALL=C sar -f test -A  > t.txt
#
#    sar -o test 5 >/dev/null 2>&1 &
#
#    java -jar PATH_TO/kSar.jar -input "$1" -outputPDF today.pdf
#    -input '/var/log/sa/sarXX'
# java -jar /data/kSar-5.0.6/kSar.jar -input final2.txt -outputPDF final2.pdf

}

vkstop(){
	## Processing command line options
	__getopts $@

	for node in "${nodes_arr[@]}"
	  do

        deb ${users[$node - 1]}
        deb ${nodes[$node - 1]}
        processId=`ssh ${users[$node - 1]}@${nodes[$node - 1]} pgrep -lf sar | grep "sar"| awk '{print $1}'`
        ssh ${users[$node - 1]}@${nodes[$node - 1]} kill -9 $processId
	    deb $processId
      done

	vkget $@
	vkpdf $@

}

vkget(){
	## Processing command line options
	__getopts $@

    if [ ! -d "temp" ]; then
        mkdir temp
    fi

	for node in "${nodes_arr[@]}"
	  do

        inf ${users[$node - 1]}
        inf ${nodes[$node - 1]}
        scp ${users[$node - 1]}@${nodes[$node - 1]}:~/sar-${nodes[$node - 1]} temp

	    inf $processId
      done

}

vkpdf(){
	## Processing command line options
	__getopts $@

	if [ ! -d "perf-test-results" ]; then
        mkdir perf-test-results
    fi

	if [ ! -d "perf-test-results/txt" ]; then
        mkdir perf-test-results/txt
    fi

	for node in "${nodes_arr[@]}"
	  do
	    ts=`timestamp`
        LC_ALL=C sar -A -f temp/sar-${nodes[$node - 1]} > temp/sar-${nodes[$node - 1]}.txt
        java -jar $ksarlocation/kSar.jar -input temp/sar-${nodes[$node - 1]}.txt -outputPDF perf-test-results/sar-${nodes[$node - 1]}-$ts.pdf
        cp temp/sar-${nodes[$node - 1]}.txt perf-test-results/txt/sar-${nodes[$node - 1]}-$ts.txt
        #rm -rf temp
      done

}

vperftest(){
    echo

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

# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d-%S-%N"
}

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

		-tid )shift
			inf "Getting test id";
			if [ $# == 0 ];
                 then err "No test id is given as an argument ..";
                 __printUsage
                 #exit 0;
                 return 3;
            fi;
            testid=$1;
            shift
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

	    vkstart ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vkstart $@
	            for a in "$@"; do shift; done
	            ;;

	    vkstop ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vkstop $@
	            for a in "$@"; do shift; done
	            ;;

	    vkget ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vkget $@
	            for a in "$@"; do shift; done
	            ;;

	    vkpdf ) shift
	            deb "${FUNCNAME} : Next command line argument is $@"
	            vkpdf $@
	            for a in "$@"; do shift; done
	            ;;

		* ) err "Invalid ${b}vcommand${n} or argument ..."
		    deb "${FUNCNAME} : Next command line argument is $@"
		    __printUsage
			shift

	    esac
	done
}

__setformat(){
    b=`tput bold`
    n=`tput sgr0`
    NONE='\033[00m'
    RED='\033[01;31m'
    GREEN='\033[01;32m'
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


#./jmeter -n -t /data/perf-arch/PerfTest.jmx -R cosmos-db2 -l test.jtl
# jmeter -n -t script.jmx -r
# vperftest -n 1 2 -jn 1 2 -tp yy.jmx
# jstatd -p 4380 -J-Djava.security.policy=jstatd.all.policy
# vertx.sh - JVM_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9000  -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

# jstatd.all.policy policy file
# grant codebase "file:/data/jdk1.7.0_60/lib/tools.jar" {
#   permission java.security.AllPermission;
#};
#


## app1 to app2 monitoring
#client - jstat -gcutil -t 92189@cosmos-app2:4380 3s
#rmi server - jstatd -p 4380 -J-Djava.security.policy=jstatd.all.policy

# jps
#  nohup jstatd -J-Djava.security.policy=jstatd.all.policy -p 1099 > /dev/null 2>&1 &

# if kcathuko-mobl-vm1 as remote host not show vms, then the reason is proxy setting of visualvm. Tools>options> network> noproxy

#vstart -n 1 4 -m pay ide -i 1 3
#vstart -n 1 -m pay ide

#vstop -n 1 2 4 -m payment idempotency
#vstart -n 1 -m payment idempotency -i 1 4
#vstart -n 1
#__getmods
#killVerticle
#ssh ${bridgeuser}@${bridgeserver}
#ls

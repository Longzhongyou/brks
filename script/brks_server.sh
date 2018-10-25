#! /bin/sh
PS="ps"
PORT=6379

BACFDBIN=/usr/local/brks_server/bin
BACFDCFG=/usr/local/brks_server/etc
PIDDIR=/usr/local/brks_server/working
SCRIPT=/usr/local/brks_server/script
SUBSYSDIR=/var/lock/subsys
PIDOF=/bin/pidof

#BASEPATH=/usr/local/
#export LD_LIBRARY_PATH=$BASEPATH/lib:$LD_LIBRARY_PATH

cd $SCRIPT

# A function to stop a program.
killproc() {
   RC=0
   # Test syntax.
   if [ $# = 0 ]; then
      echo "Usage: killproc {program} [signal]"
      return 1
   fi

   notset=0
   # check for third arg to be kill level
   if [ "$2" != "" ] ; then
      killlevel=$2
   else
      notset=1
      killlevel="-9"
   fi

   # Get base program name
   base=`basename $1`
   #echo $base
   # Find pid.
   #pid=`pidofproc $base`
   if [ -x ${PIDOF} ] ; then
      pid=`${PIDOF} $base`
   fi
   # Kill it.
   if [ "$pid" != "" ] ; then
      if [ "$notset" = "1" ] ; then
	       if ${PS} -p "$pid">/dev/null 2>&1; then
	          # TERM first, then KILL if not dead
	          kill -TERM $pid 2>/dev/null
	          sleep 1
	          if ${PS} -p "$pid" >/dev/null 2>&1 ; then
		           sleep 1
		           if ${PS} -p "$pid" >/dev/null 2>&1 ; then
		              sleep 3
		              if ${PS} -p "$pid" >/dev/null 2>&1 ; then
			               kill -KILL $pid 2>/dev/null
		              fi
		           fi
	          fi
	       fi
	       ${PS} -p "$pid" >/dev/null 2>&1
	       RC=$?
	       [ $RC -eq 0 ] && failure "$base shutdown" || success "$base shutdown"
         #    RC=$((! $RC))
         # use specified level only
      else
	       if ${PS} -p "$pid" >/dev/null 2>&1; then
	          kill $killlevel $pid 2>/dev/null
	          RC=$?
	          [ $RC -eq 0 ] && success "$base $killlevel" || failure "$base $killlevel"
	       fi
      fi
   else
      failure "$base shutdown"
   fi
   # Remove pid file if any.
   if [ "$notset" = "1" ]; then
      rm -f ${PIDDIR}/$base.$2.pid
   fi
   return $RC
}

# A function to find the pid of a program.
pidofproc() {
   pid=""
   # Test syntax.
   if [ $# = 0 ] ; then
      echo "Usage: pidofproc {program}"
      return 1
   fi
   echo "pidofproc"
   # Get base program name
   base=`basename $1`
   echo $base
   # First try PID file
   #if [ -f ${PIDDIR}/$base.$2.pid ] ; then
   #   pid=`head -n 1 ${PIDDIR}/$base.$2.pid`
   #   if [ "$pid" != "" ] ; then
	 #      echo $pid
	 #      return 0
   #   fi
   #fi

   # Next try "pidof"
   if [ -x ${PIDOF} ] ; then
      pid=`${PIDOF} $1`
   fi
   if [ "$pid" != "" ] ; then
      echo $pid
      return 0
   fi

   # Finally try to extract it from ps
   pid=`${PSCMD} | grep $1 | awk '{ print $1 }' | tr '\n' ' '`
   echo $pid
   return 0
}

status() {
   pid=""
   # Test syntax.
   if [ $# = 0 ] ; then
       echo "Usage: status {program}"
       return 1
   fi

   # Get base program name
   base=`basename $1`
  
   #pid=`${PSCMD} | awk 'BEGIN { prog=ARGV[1]; ARGC=1 } 
   #{ if ((prog == $2) || (("(" prog ")") == $2) ||
  #(("[" prog "]") == $2) ||
  #((prog ":") == $2)) { print $1 ; exit 0 } }' $1`
  #echo $pid
   #if [ "$pid" != "" ] ; then
   #  echo "$base (pid $pid) is running..."
   #  return 0
   #fi
   

   # Next try the PID files
   #if [ -f ${PIDDIR}/$base.$2.pid ] ; then
   #   pid=`head -n 1 ${PIDDIR}/$base.$2.pid`
   #   if [ "$pid" != "" ] ; then
	 #     echo "$base dead but pid file exists"
	 #     return 1
   #   fi
   #fi
   # See if the subsys lock exists
   #if [ -f ${SUBSYSDIR}/$base ] ; then
   #   echo "$base dead but subsys locked"
   #   return 2
   #fi
   if [ -x ${PIDOF} ] ; then
      pid=`${PIDOF} $1`
   fi
   if [ "$pid" != "" ] ; then
      echo "$base (pid $pid) is running..."
      return 0
   fi
   echo "$base is stopped"
   return 3
}

success() {
   return 0
}

failure() {
   rc=$?
   return $rc
}

case "$1" in
   start)
      [ -x ${BACFDBIN}/brks ] && {
      	if [ -x ${PIDOF} ] ; then
      	   pid=`${PIDOF} $1`
		    fi
		    if [ "$pid" != "" ] ; then
		       echo "$base (pid $pid) is running..."
		       return 0
		    fi
	      echo "Starting the brks daemon"
		    ${BACFDBIN}/brks  ${BACFDCFG}/log.conf > ${PIDDIR}/brk_start.log &
      }
      ;;

   stop)
      # Stop the FD first so that SD will fail jobs and update catalog
      [ -x ${BACFDBIN}/brks ] && {
	      echo "Stopping the brks daemon"
	      killproc ${BACFDBIN}/brks
      }
      ;;

   restart)
      $0 stop
      sleep 5
      $0 start
      ;;

   status)
      [ -x ${BACFDBIN}/brks ] && status ${BACFDBIN}/brks
      ;;

   *)
      echo "Usage: $0 {start|stop|restart|status}"
      exit 1
      ;;
esac
exit 0
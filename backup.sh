#!/bin/bash
MAJORVER=0
MINORVER=2

SRCDIR="$1";DSTDIR="$2";
if [ -z "$DSTDIR" ] || [ -z "$SRCDIR" ]; then
  echo "$0 SRCDIR DSTDIR"
  exit 1
fi

if [ ! -d "$SRCDIR" ]; then
  echo "No srcdir $SRCDIR"
  exit 1
fi

if [ ! -d "$DSTDIR" ]; then
  echo "No dstdir $DSTDIR"
  exit 1
fi

function log {
  echo "$1" >> "$DSTDIR/log.tmp"
  echo "$1"
}

function secondsToTimestamp {
  echo - | awk -v "S=$1" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'
}

SECSTART=`date +"%s"`
START=`date +"%d-%m-%Y %H:%M:%S"`
NUMBER_OF_ERRORS=0


function backup {
  cd $SRCDIR

  for file in *
  do
    TIMEBEGIN=`date +"%H:%M:%S"`
    if [ -h "$file" ]; then
      SRC=`readlink "$file"`
      DIRNAME=`echo "$file" | awk -F/ '{print $NF}'`

      if ! `rdiff-backup --exclude-symbolic-links "$SRC" "$DSTDIR"/"$DIRNAME"` 2> "$DSTDIR/error.txt"
      then
        TIMEEND=`date +"%H:%M:%S"`
        ERR="`< ./error.txt`"
        log "    $TIMEBEGIN - $TIMEEND : $SRC -> $DSTDIR/$DIRNAME [FAILED] Error: '$ERR'"
        NUMBER_OF_ERRORS=`echo 1+$NUMBER_OF_ERRORS | bc`
      else
        TIMEEND=`date +"%H:%M:%S"`
        log "    $TIMEBEGIN - $TIMEEND : $SRC -> $DSTDIR/$DIRNAME [OK]"
      fi
      if [ -f "$DSTDIR/error.txt" ]; then
        rm $DSTDIR/error.txt
      fi
    fi
  done
}

log "--> BEGIN $START <--"
log "    Backup script ver=$MAJORVER.$MINORVER"

## Do backup
backup $SRCDIR $DSTDIR

STOP=`date +"%d-%m-%Y %H:%M:%S"`
SECSTOP=`date +"%s"`
ELAPSED=`echo "$SECSTOP - $SECSTART " | bc`

TIMECONVERT=`secondsToTimestamp "$ELAPSED"`

log "    Backup took $TIMECONVERT, with $NUMBER_OF_ERRORS errors"
log "--> END $STOP <--"
log " "

#Store the log
cat $DSTDIR/log.tmp >> $DSTDIR/backup.log
rm $DSTDIR/log.tmp

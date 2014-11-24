#!/bin/bash

# Exit on first error
set -e
cd /var/lib/virtuoso/db

#set NumberOfBuffers and MaxDirtyBuffers parameters in Virtuoso.ini
totalMem=$(cat /proc/meminfo | grep "MemTotal" | grep -o "[0-9]*")

virtMemAlloc=$(($totalMem/2))
nBuffers=$(($virtMemAlloc/9))
dirtyBuffers=$(($nBuffers*3/4))

echo "Virtuoso params: NumberOfBuffers $nBuffers ; MaxDirtyBuffers: $dirtyBuffers "

sed -i "s/^\(NumberOfBuffers\s*= \)[0-9]*/\1$nBuffers/" /var/lib/virtuoso/db/virtuoso.ini
sed -i "s/^\(MaxDirtyBuffers\s*= \)[0-9]*/\1$dirtyBuffers/" /var/lib/virtuoso/db/virtuoso.ini




alias isql="isql-v 1111 dba dba VERBOSE=OFF BANNER=OFF PROMPT=OFF ECHO=OFF BLOBS=ON ERRORS=stdout"

function finish {
  echo "Shutting down virtuoso"
  isql-v 1111 dba dba -K
  sleep 2
}
trap finish HUP INT QUIT KILL TERM


if [ -f /staging/staging.sql ] ; then
  echo "Starting Virtuosa"
  /usr/bin/virtuoso-t "+wait"
  echo "Configuring SPARQL"
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARQL_INSERT_DICT_CONTENT TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.L_O_LOOK TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARUL_RUN TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARQL_DELETE_DICT_CONTENT TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.RDF_OBJ_ADD_KEYWORD_FOR_GRAPH TO "SPARQL";'

  echo "Populating from /staging/staging.sql"
  isql /staging/staging.sql 
  for core in $(cat /proc/cpuinfo  | grep "^processor" | awk '{ print $3} '); do 
    echo Starting RDF loader for core $core 
    isql 'EXEC=rdf_loader_run();' & 
  done
  wait
  echo "Checkpointing"
  isql 'EXEC=checkpoint;' 
  echo -n "Total number of triples: " 
  isql 'EXEC=SPARQL SELECT COUNT(*) WHERE { ?s ?p ?o} '
  echo "Keep running Virtuosa"
  . /virtuoso/virtuoso.lck
  while [ -e /proc/$VIRT_PID ] ; do sleep 1.0 ; done
else
  echo "Starting Virtuosa"
  /usr/bin/virtuoso-t "+wait" "+foreground"
fi 


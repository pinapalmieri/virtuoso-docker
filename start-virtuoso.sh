#!/bin/sh

set -e

#set NumberOfBuffers and MaxDirtyBuffers parameters in Virtuoso.ini
totalMem=$(cat /proc/meminfo | grep "MemTotal" | grep -o "[0-9]*")

virtMemAlloc=$(($totalMem/2))
nBuffers=$(($virtMemAlloc/9))
dirtyBuffers=$(($nBuffers*3/4))

echo "Virtuoso params: NumberOfBuffers $nBuffers ; MaxDirtyBuffers: $dirtyBuffers "

sed -i "s/^\(NumberOfBuffers\s*= \)[0-9]*/\1$nBuffers/" /var/lib/virtuoso/db/virtuoso.ini
sed -i "s/^\(MaxDirtyBuffers\s*= \)[0-9]*/\1$dirtyBuffers/" /var/lib/virtuoso/db/virtuoso.ini




alias isql="isql-v 1111 dba dba VERBOSE=OFF BANNER=OFF PROMPT=OFF ECHO=OFF BLOBS=ON ERRORS=stdout"

if [ -f /staging/staging.sql ] ; then
  echo "Populating from /staging/staging.sql"
  /usr/bin/virtuoso-t "+wait"

  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARQL_INSERT_DICT_CONTENT TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.L_O_LOOK TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARUL_RUN TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARQL_DELETE_DICT_CONTENT TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.RDF_OBJ_ADD_KEYWORD_FOR_GRAPH TO "SPARQL";'
  isql /staging/staging.sql 'EXEC=rdf_loader_run();' 'EXEC=checkpoint;' 
## TODO: one rdf_loader_run() for each core?
# for core in $(cat /proc/cpuinfo  | grep "^processor" | awk '{ print $3} '); do echo Core $core  ; done
## .. but how to wait for them to finish?
  echo "Total number of triples": 
  isql 'EXEC=SPARQL SELECT COUNT(*) WHERE { ?s ?p ?o} '
  isql 'EXEC=shutdown'
  sleep 5
fi

/usr/bin/virtuoso-t "+wait" "+foreground"

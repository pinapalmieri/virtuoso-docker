#!/bin/bash

# Exit on first error
set -e

service virtuoso-opensource-7 start

function isql {
 /usr/local/bin/isql localhost dba dba VERBOSE=OFF BANNER=OFF PROMPT=OFF ECHO=OFF BLOBS=ON ERRORS=stdout "$@"
}


# FIXME: Is this needed? It seems overly permissive..
  echo "Configuring SPARQL"
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARQL_INSERT_DICT_CONTENT TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.L_O_LOOK TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARUL_RUN TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.SPARQL_DELETE_DICT_CONTENT TO "SPARQL";'
  isql 'exec=GRANT EXECUTE ON DB.DBA.RDF_OBJ_ADD_KEYWORD_FOR_GRAPH TO "SPARQL";'

echo "Populating from /staging/staging.sql"
isql /staging/staging.sql 
MAX_CORES=8
for core in $(cat /proc/cpuinfo  | grep "^processor" | head -n $MAX_CORES | awk '{ print $3} '); do 
  echo Starting RDF loader for core $core 
  isql 'EXEC=rdf_loader_run();' & 
done
wait
echo "Checkpointing"
isql 'EXEC=checkpoint;' 
echo -n "Staging finished, total triples: " 
isql 'EXEC=SPARQL SELECT COUNT(*) WHERE { ?s ?p ?o} ;'

service virtuoso-opensource-7 stop


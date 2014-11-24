#!/bin/sh

#set NumberOfBuffers and MaxDirtyBuffers parameters in Virtuoso.ini
totalMem=$(cat /proc/meminfo | grep "MemTotal" | grep -o "[0-9]*")

virtMemAlloc=$(($totalMem/2))
nBuffers=$(($virtMemAlloc/9))
dirtyBuffers=$(($nBuffers*3/4))

echo "Virtuoso params: NumberOfBuffers $nBuffers ; MaxDirtyBuffers: $dirtyBuffers "

sed -i "s/^\(NumberOfBuffers\s*= \)[0-9]*/\1$nBuffers/" /var/lib/virtuoso/db/virtuoso.ini
sed -i "s/^\(MaxDirtyBuffers\s*= \)[0-9]*/\1$dirtyBuffers/" /var/lib/virtuoso/db/virtuoso.ini



/usr/bin/virtuoso-t "+wait" "+foreground" &

if [ -f /staging/staging.sql ] ; then
  echo "Populating from /staging/staging.sql"
  isql-v "LOAD /staging/staging.sql"
  isql-v "EXEC rdf_loader_run ();"
  isql-v "EXEC checkpoint;"

fi

# Rejoin virtuoso
wait

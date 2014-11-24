# Virtuoso

Virtuoso 7 Open Source Edition on Ubuntu 12.04


## License

* Dockerfile: [Apache Software License 2.0](LICENSE.md) 
* Docker image: [GNU GPL 2](https://github.com/openlink/virtuoso-opensource/blob/develop/7/LICENSE), like Virtuoso.


## Credits

[Virtuoso Open Source Edition](https://github.com/openlink/virtuoso-opensource) (C) 1998-2014 [OpenLink Software](http://www.openlinksw.com/) <vos.admin@openlinksw.com>

Docker image maintained by [Stian Soiland-Reyes](http://orcid.org/0000-0001-9842-9718) on behalf of the 
[Open PHACTS Foundation](http://www.openphactsfoundation.org/), based on
[ansible-role-virtuoso](https://github.com/nicholsn/ansible-role-virtuoso) by
[Nolan Nichols](http://orcid.org/0000-0003-1099-3328) 


## Usage

This docker image exposes ports `8890` (SPARQL/WebDAV) and `1111` (isql).

Virtuosa data is stored in the volume `/virtuoso`. If needed, you can modify
the `virtuoso.ini` through the volume `/var/lib/virtuoso/db`.

Example of running Virtuosa to directly expose port `8890` and have the volume
`/virtuoso` mounted from `/scratch/virtuoso` on the host:

  docker run -d -p 8890:8890 -v /scratch/virtuoso/:/virtuoso soilandreyes/virtuoso-docker

Note that only a single container can access the `/virtuoso` volume at a time, otherwise you'll get:

	14:36:57 Unable to lock file /virtuoso/virtuoso.lck (Resource temporarily unavailable).
	14:36:57 Virtuoso is already runnning (pid 0)


## Staging

The volume `/staging` and the file `/staging/staging.sql` can be used to load data,
typically using 
[ld\_dir](http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VirtBulkRDFLoader)
Note that the staging will execute on startup whenever `/staging/staging.sql` is present.

Example:

    docker run -v /scratch/ops/1.4/rdf/:/staging -v /scratch/virtuoso/:/virtuoso soilandreyes/virtuoso-docker

Note that `/scratch/ops/1.4/rdf/staging.sql` uses `/staging` as base directory, example:


	-- Gene Ontology
	ld_dir('/staging/GO' , 'go_daily-termdb.owl.gz' , 'http://www.geneontology.org' );
	ld_dir('/staging/GO' , 'goTreeInference.ttl.gz', 'http://www.geneontology.org/inference');
	ld_dir('/staging/GO' , 'go_daily-termdb.nt.gz' , 'http://www.geneontology.org/terms' );

	-- GOA
	ld_dir('/staging/GOA' , '*.rdf.gz' , 'http://www.openphacts.org/goa' );

After staging is complete, a total number of triples (including any present before staging) will be output, and virtuoso will continue running.

	stain@docker:~$ docker run -p 8890:8890 -v /scratch/ops/1.4/rdf/:/staging -v /scratch/virtuoso/:/virtuoso -it b2054848d569
	Virtuoso params: NumberOfBuffers 236980 ; MaxDirtyBuffers: 177735
	Populating from /staging/staging.sql
	Total number of triples:
	5752



### Multiple staging threads

By default the staging will execute a single `rdf_loader_run();` thread - to use multiple CPU cores, add additional lines to the `staging.sql`, e.g. for a total of 3 loader threads:

	rdf_loader_run() &
	rdf_loader_run() &
	



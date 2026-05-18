sleep:{et:.z.p+`second$x; while[.z.p<et]}
dbs:use `kx.dbservice_client;

session:dbs.createSession[];
r0:session.importFiles[`table`path`createTable!("fxquote";"fxquote.csv.gz";1b)];
show r0;
while[(r1:session.getImport[r0`name])[`status] in ("pending";"processing"); sleep[1]]
show r1;
r2:session.querySimple[`table`startTS`endTS`sortCols`limit!(`fxquote;2026.03.02D;2026.03.03D;enlist "ts"; 5)]
show r2;

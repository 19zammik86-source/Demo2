apt-get update && apt-get install -y openssl-gost-engine

control openssl-gost enabled

openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:TCB -out ca.key

openssl req -new -x509 -md_gost12_256 -days 30 -key ca.key -out ca.cer

openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out web.au-team.irpo.key

openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out docker.au-team.irpo.key

openssl req -new  -md_gost12_256 -key web.au-team.irpo.key -out web.au-team.irpo.csr

openssl req -new  -md_gost12_256 -key docker.au-team.irpo.key -out docker.au-team.irpo.csr

openssl x509 -req -in web.au-team.irpo.csr -CA ca.cer -CAkey ca.key -CAcreateserial -out web.au-team.irpo.cer -days 30

openssl x509 -req -in docker.au-team.irpo.csr -CA ca.cer -CAkey ca.key -CAcreateserial -out docker.au-team.irpo.cer -days 30

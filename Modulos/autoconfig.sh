#!/bin/bash
col1='\033[1;31m' 
col2='\033[1;32m' 
col3='\033[1;33m' 
col4='\033[1;34m' 
col5='\033[1;35m' 
col6='\033[1;36m'
col7='\033[1;37m' 
barra="\033[0;31m=====================================================\033[0m"


blanco(){
	[[ !  $2 = 0 ]] && {
		echo -e "\033[1;37m$1\033[0m"
	} || {
		echo -ne " \033[1;37m$1:\033[0m "
	}
}

col(){

	nom=$(printf '%-55s' "\033[0;92m${1} \033[0;31m>> \033[1;37m${2}")
	echo -e "	$nom\033[0;31m${3}   \033[0;92m${4}\033[0m"
}


vacio(){

	blanco "\n no se puede ingresar campos vacios..."
}

cancelar(){

	echo -e "\n \033[3;49;31minstalacion cancelada...\033[0m"
}

continuar(){

	echo -e " \033[3;49;32mEnter para continuar...\033[0m"
}

fun_bar () {
          comando[0]="$1"
          comando[1]="$2"
          (
          [[ -e $HOME/fim ]] && rm $HOME/fim
          ${comando[0]} > /dev/null 2>&1
          ${comando[1]} > /dev/null 2>&1
          touch $HOME/fim
          ) > /dev/null 2>&1 &
          tput civis
		  echo -e "${col1}---------------------------------------------------${col0}"
          echo -ne "${col4}    ESPERE*** ${col6}["
          while true; do
          for((i=0; i<20; i++)); do
          echo -ne "${col1}x"
          sleep 0.2s
          done
         [[ -e $HOME/fim ]] && rm $HOME/fim && break
         echo -e "${col5}"
         sleep 1s
         tput cuu1
         tput dl1
         echo -ne "${col7}    ESPERE..${col5}["
         done
         echo -e "${col6}]${col7} -${col2} INSTALADO !${col7}"
         tput cnorm
		 echo -e "${col1}---------------------------------------------------${col0}"
        }
        



inst_ssl () {
echo -e "$barra"
pkill -f stunnel4
echo "Destruyendo Stunnel Activo"
apt purge stunnel4 -y > /dev/null 2>&1
echo "Reinstalando Stunnel"
apt install stunnel4 -y > /dev/null 2>&1
echo -e "$barra"
read -p "Ingresa Puerto SSL a USAR : " porta
pt=$(netstat -nplt |grep 'sshd' | awk -F ":" NR==1{'print $2'} | cut -d " " -f 1)
echo -e "\033[1;31mPUERTO PROXY PYTHON\033[0m"
echo -e "$barra"
read -p "Introduzca puerto proxy: " redirporta
echo ""
echo -e "\033[1;37m Mensaje en el mini Banner por defecto ( @WOLI0101 ) \033[1;36m"
echo -e "\033[1;37m No exagerar en el mini Banner  \033[1;36m"
echo -e "\e[0;31m Soporta HTML\e[0m"
read -p " :" msgbanner
[[ "$msgbanner" = "" ]]&& msgbanner=' <font color="red"> @WOLI0101 </font> '
echo 
echo -e "Respuesta de Encabezado ( 101,200,484,500,etc ) \n \033[1;37m"
read -p "Response Status (Default 101 ) : " respo_stat
[[ -z $respo_stat  ]] && respo_stat="101"
echo "Configurando Conexion SSL"
echo -e "cert = /etc/stunnel/stunnel.pem\nclient = no\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n\n[stunnel]\naccept = ${porta}\nconnect = 127.0.0.1:${redirporta}\n" > /etc/stunnel/stunnel.conf
openssl genrsa -out key.pem 2048 > /dev/null 2>&1
(echo "$(curl -sSL ipinfo.io > info && cat info | grep country | awk '{print $2}' | sed -e 's/[^a-z0-9 -]//ig')" ; echo "" ; echo "$(wget -qO- ifconfig.me):81" ; echo "" ; echo "" ; echo "" ; echo "@cloudflare" )|openssl req -new -x509 -key key.pem -out cert.pem -days 1095 > /dev/null 2>&1
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
service stunnel4 restart > /dev/null 2>&1
echo -e "SSL Activo Exitosamente"
}


inst_py () {
#echo -e "\033[1;33m                 CONFIGURANDO PYTHON.. "
pkill -f $redirporta
pidpython=$(ps x | grep "$HOME/proxy_copia.py" | grep -v grep |awk '{print $1}') 
pidpython1=$(ps x | grep "proxy.py" | grep -v grep |awk '{print $1}') 
[[ ! -z $pidpython ]] && kill -9 $pidpython
[[ ! -z $pidpython1 ]] && kill -9 $pidpython1
apt install python -y  > /dev/null 2>&1
apt install screen -y  > /dev/null 2>&1
pt=$(netstat -nplt |grep 'sshd' | awk -F ":" NR==1{'print $2'} | cut -d " " -f 1)
 cat <<EOF > proxy.py
import socket, threading, thread, select, signal, sys, time, getopt

# CONFIG
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = 1080
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = "127.0.0.1:$pt"
RESPONSE = 'HTTP/1.1 $respo_stat $msgbanner \r\nContent-length: 0\r\n\r\nHTTP/1.1 200 conexion exitosa\r\n\r\n'
 
class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
	self.threadsLock = threading.Lock()
	self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True

        try:                    
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                
                conn = ConnectionHandler(c, self, addr)
                conn.start();
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()
            
    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()
	
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()
                    
    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()
                
    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()
			

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
            
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
        
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            
            if hostPort == '':
                hostPort = DEFAULT_HOST

            split = self.findHeader(self.client_buffer, 'X-Split')

            if split != '':
                self.client.recv(BUFLEN)
            
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')

        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)

    def findHeader(self, head, header):
        aux = head.find(header + ': ')
    
        if aux == -1:
            return ''

        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')

        if aux == -1:
            return ''

        return head[:aux];

    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
                port = 443
            else:
                port = 80

        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]

        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)

    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path
        
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''

        self.server.printLog(self.log)
        self.doCONNECT()

    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]

                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True

            if error:
                break


def print_usage():
    print 'Usage: proxy.py -p <port>'
    print '       proxy.py -b <bindAddr> -p <port>'
    print '       proxy.py -b 0.0.0.0 -p 1080'

def parse_args(argv):
    global LISTENING_ADDR
    global LISTENING_PORT
    
    try:
        opts, args = getopt.getopt(argv,"hb:p:",["bind=","port="])
    except getopt.GetoptError:
        print_usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print_usage()
            sys.exit()
        elif opt in ("-b", "--bind"):
            LISTENING_ADDR = arg
        elif opt in ("-p", "--port"):
            LISTENING_PORT = int(arg)
    

def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    
    print "\n ==============================\n"
    print "\n         PYTHON PROXY          \n"
    print "\n ==============================\n"
    print "corriendo ip: " + LISTENING_ADDR
    print "corriendo port: " + str(LISTENING_PORT) + "\n"
    print "Se ha Iniciado Por Favor Cierre el Terminal\n"
    
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()

    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break
    
if __name__ == '__main__':
    parse_args(sys.argv[1:])
    main()
EOF
echo $redirporta > /bin/ejecutar/proxtport
cat proxy.py > $HOME/proxy_copia.py
screen -dmS pythonwe python $HOME/proxy_copia.py -p $redirporta&

}

menuintro() {
clear&&clear
echo -e "\033[1;31m————————————————————————————————————————————————————\033[1;37m"
echo -e "\033[1;34m              PYTHON + SSL | By: @WOLI0101 "
echo -e "\033[1;31m————————————————————————————————————————————————————\033[1;37m"
echo -e "\033[1;36m        SCRIPT REESTRUCTURA y AUTOCONFIGURACION "
echo -e "\033[1;31m————————————————————————————————————————————————————\033[1;37m"
echo -e "\033[1;37m      Requiere tener el puerto libre ,443 y el 80"
echo
	while :
	do
		#col "5)" "\033[1;33mCONFIGURAR Trojan"
		echo -e $barra
		col "1)" "\033[1;33mINSTALAR SERVICIO DE PYTHON & SSL"
		echo -e $barra
		#col "2)" "\033[1;33mDETENER SERVICIO DE  PYTHON & SSL"
		col "2)" "\033[1;33mCONFIGURAR PYTHON (RESPONSE STATUS 200)"
		echo -e $barra
		col "0)" "SALIR \033[0;31m"
		echo -e $barra
		blanco "Elija una Opcion " 0
		read opcion
		case $opcion in
			1)
			echo -e "\033[1;33m INSTALADO SSL.. "
			inst_ssl
			echo -e "Instalando Redireccion Python"
			fun_bar 'inst_py'
			rm -rf proxy.py
			echo -e " Respaldo Guardado en $HOME/proxy_copia.py "
			echo -e "                 INSTALACIÓN TERMINADA"
			echo
			echo -e "Solucionado el error de conectividad mediante el puerto $porta con SNI"
echo

			;;
			#2)unistall
			#;;
			2)
			source <(curl -sSL https://www.dropbox.com/s/rpknp7f1l9u0q59/Proxy.sh)
			;;
			0) break;;
			*) blanco "\n selecione una opcion del 0 al 2" && sleep 1;;
		esac
	done
#continuar
#read foo
echo
#echo -e " \033[1;37m  Ve a Menu 1, Opcion 2, \n   Y crea tu usuario para Pruebas "
}
menuintro

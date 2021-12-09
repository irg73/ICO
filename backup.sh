# SCRIPT de BACKUP backup.sh con MEJORAS -- Ticket relacionado = SR-139115:

#!/bin/sh

#------------------------------------------------------------------------------
# Uso: backup.sh nombre_nas carpeta_raiz
#------------------------------------------------------------------------------

appName="backup_${1}"
logDir="/raid0/data/backup/backup_${1}/logs"
messageInfo=""
root_folder=$2

# Array que define las 4 direcciones de envío -eliminados los espacios que sobraban y las comas-
ubop_sysadmins=('famoral@iconcologia.net' 'dcordero@iconcologia.net' 'pandora_admin@iconcologia.net' 'odap_admin@iconcologia.net')

#------------------------------------------------------------------------------
# Funciones de log
#------------------------------------------------------------------------------

fn_log_info()
  {
  echo -e "$appName: $1"
  printf -v messageInfo "$messageInfo\n$appName: $1"
  }

fn_log_warn()
  {
  echo "$appName: [WARNING] $1" 1>&2
  }

fn_log_error()
  {
  echo "$appName: [ERROR] $1" 1>&2
  }


#------------------------------------------------------------------------------
# Funcionamos con marcas de tiempo. Nos quedamos con dos fechas incluidos
# los milisegundos para luego restarlas
#------------------------------------------------------------------------------

fn_ejemploMarca()
  {
  local marca1=`date +%s | cut -b1-13`
  sleep 1s
  local marca2=`date +%s | cut -b1-13`
  echo -e "Espero exactamente 1 segundo \t[\e[31m$(( marca2 -marca1 ))\e[0m] segundo(s)"
  }


  #------------------------------------------------------------------------------
  # Timestamps
  #
  # Cálculo de timestamps (ms) para obtener el tiempo transcurrido en h:m:s.
  #------------------------------------------------------------------------------

  fn_duration()
    {
    if (( $1 <= $2 )); then
      ms=$(( ${2} -${1} ))
    else
      ms=$(( ${1} -${2} ))
    fi
      #printf "%dh %dm %02ds" "$(( ${ms} / (1000*60*60) ))" "$(( (${ms} / (1000*60) ) % 60 ))" "$(( (${ms} / 1000 ) % 60 ))"
      printf "%d:%02d:%02d" "$(( ${ms} / 3600000 ))" "$(( (${ms} / 60000 ) % 60 ))" "$(( (${ms} / 1000 ) % 60 ))"
    }


#------------------------------------------------------------------------------
# Comprobamos si el directorio esta montado
#------------------------------------------------------------------------------

fn_checkMounted()
  {
  fn_log_info "Comprobando si $1 esta montado"
  if grep -qs ${1} /proc/mounts; then
    fn_log_info "${1} esta montado. Continuamos"
  else
    fn_log_info "${1} NO esta montado. Abortamos"
    exit 1
  fi
  }

fn_checkMounted "/raid0/data/mnt/${1}"

#------------------------------------------------------------------------------
# Creamos la carpeta log si no existe
#------------------------------------------------------------------------------

if [ ! -d "$logDir" ]; then
  fn_log_info "Creando carpeta de log en '$logDir'"
  mkdir -- "$logDir"
fi

#------------------------------------------------------------------------------
# INICIO BACKUP
#------------------------------------------------------------------------------

snapshotDate=`date "+%Y-%m-%dT%H:%M:%S"`
logFile="$logDir/$snapshotDate.log"
fn_log_info "Backup empieza --> ["`date "+%Y-%m-%dT%H:%M:%S"`"]"

marca1=`date +%s | cut -b1-13`

#definimos la variable BASEDIR, que almacena la ruta donde se crean los backups
BASEDIR=/raid0/data/backup/backup_${1}

 # Creamos los subdirectorios daily y monthly, y previamente chequeamos si existen;
 # a continuación cambiar las rutas que se le pasan como args al rsync

  DIR_DAILY=/raid0/data/backup/backup_${1}/daily
  DIR_MONTHLY=/raid0/data/backup/backup_${1}/monthly

  if [ ! -d "$DIR1" ]; then
    mkdir /raid0/data/backup/backup_${1}/daily
  else if [ ! -d "$DIR2" ]; then
    mkdir /raid0/data/backup/backup_${1}/monthly

  # modificadas las rutas de destino --link-dest el día 07-12-2021, para que
  # tengan en cuenta la subcarpeta daily
  rsync \
    --archive --verbose --verbose --human-readable \
    --partial --progress \
    --no-whole-file \
    --delete \
    --log-file=$logFile \
    --link-dest=${BASEDIR}/last /raid0/data/mnt/${1}/${root_folder} ${basedir}/daily/snapshot-$snapshotDate > /dev/null

  retValRsync=$?
  if [ $retValRsync -ne 0 ]; then
    fn_log_info  "Rsync no ha funcionado devuelve: $retValRsync. Abortamos"
    exit 1
  else
    fn_log_info  "Rsync ejecutado con exito. Continuamos"
  fi

marca2=`date +%s | cut -b1-13`
fn_log_info "Snapshot creado en: [$(( marca2 -marca1 ))] segundos"

marca1=`date +%s | cut -b1-13`

  rm -rf /raid0/data/backup/backup_${1}/last

marca2=`date +%s | cut -b1-13`
fn_log_info "Ultimo mirror eliminado en: [$(( marca2 -marca1 ))] segundos"

marca1=`date +%s | cut -b1-13`

  cp -al /raid0/data/backup/backup_${1}/snapshot-$snapshotDate /raid0/data/backup/backup_${1}/last

marca2=`date +%s | cut -b1-13`
fn_log_info "Snapshot actual copiado como mirror en: [$(( marca2 -marca1 ))] segundos"

marca1=`date +%s | cut -b1-13`

  cat $logFile | grep -v "is uptodate" > "$logFile.summary"

marca2=`date +%s | cut -b1-13`
fn_log_info "Log sintetizado en: [$(( marca2 -marca1 ))] segundos"

marca1=`date +%s | cut -b1-13`

  tar cvzf "$logFile.tar.gz" $logFile
  tar cvzf "$logFile.summary.tar.gz" "$logFile.summary"

marca2=`date +%s | cut -b1-13`
fn_log_info "Logs comprimidos en: [$(( marca2 -marca1 ))] segundos"

marca1=`date +%s | cut -b1-13`

  rm  $logFile
  rm  "$logFile.summary"

marca2=`date +%s | cut -b1-13`
fn_log_info "Logs sin comprimir eliminados en: [$(( marca2 -marca1 ))] segundos"

fn_log_info "["`date "+%Y-%m-%dT%H:%M:%S"`"] <-- Acaba Backup"

summarySpace=`df -h | grep "/raid0$" | awk '{$1=" Filesystem: "$1"\n"}{$2="Size: "$2"\n"}{$3="Used: "$3"\n"}{$4="Available: "$4"\n"}{$5="Use percentage: "$5" percent\n"}{$6="Monunted on: "$6"\n"}1'`

# Limpiamos cuaqluier % que pueda malinterpretar el printf de la fn_log_info
summarySpace=${summarySpace//%}
fn_log_info "Resumen espacio en NAS UBOPNAS02 despues del backup\n$summarySpace"

#------------------------------------------------------------------------------
# INICIO ENVIO MAIL
#------------------------------------------------------------------------------

body='From: <%s>
To: <%s>
Subject: Thecus Backup %s Snapshot %s event
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8Bit
Hello ubopnas02 SysAdmin,
This notification message is generated automatically from ubopnas02.
The system experienced the following event(s):
%s\n\n\n
Please be aware of the event(s) above. Also if necessary, please react to the event(s).
'

fn_mail_body()
    {
	  mail_from=$1
	  mail_to=$2
      nas=$3
    printf "${body}" "${mail_from}" "${mail_to}" "${nas}" "${snapshotDate}" "${messageInfo}"
    return 0
    }

from='ubopnas02.ico.scs.local'
recip='famoral@iconcologia.net'
nas=${1}
msmtp="/opt/bin/msmtp"
optdomain=""
host="10.84.175.11"
port="25"
auth="off"
user=""
p=""
# Envio mail Administradores; NUEVA INSTRUCCION:

for recip in ${ubop_sysadmins[@]}
do
  fn_mail_body "${from}" "${recip}" "${nas}"| ${msmtp} ${recip}

# Envio mail Administrador a
# recip='dcordero@iconcologia.net'

# fn_mail_body "${from}" "${recip}" "${nas}"| ${msmtp} ${recip}
# Envio mail a la cuenta compartida de administradores

#recip='pandora_admin@iconcologia.net'
#fn_mail_body "${from}" "${recip}" "${nas}"| ${msmtp} ${recip}

done

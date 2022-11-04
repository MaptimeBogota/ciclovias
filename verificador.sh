#!/bin/bash

# Este script descarga las relaciones de las ciclovías, y las compara con una
# versión anterior. Esto para identificar cambios dañinos.
#
# Autor: Andrés Gómez - AngocA
# Version: 20221103

set -euo pipefail

# Activar para depuración.
#set -xv

LOG_FILE=output.log
CICLOVIA_IDS=ciclovias_ids.txt
QUERY_FILE=query.txt
HISTORIC_FILES_DIR=history
RESTRICTIONS_IDS=restricciones_ids.txt
WAIT_TIME=5
REPORT=report.txt
REPORT_CONTENT=reportContent.txt
MAILS="angoca@yahoo.com,civil.melo@gmail.com"

echo "$(date) Starting process" >> ${LOG_FILE}

# Chequea prerequisitos.
## git
git --version > /dev/null 2>&1
if [ ${?} -ne 0 ] ; then
 echo "ERROR: Falta instalar git."
 exit 1
fi
## wget
wget --version > /dev/null 2>&1
if [ ${?} -ne 0 ] ; then
 echo "ERROR: Falta instalar wget."
 exit 1
fi

# Prepara el entorno.
mkdir -p ${HISTORIC_FILES_DIR} > /dev/null
cd ${HISTORIC_FILES_DIR}
git init >> ../${LOG_FILE} 2>&1
git config user.email "maptime.bogota@gmail.com"
git config user.name "Bot Chequeo ciclovias"
cd - > /dev/null
rm -f ${REPORT_CONTENT}

cat << EOF > ${REPORT}
Subject: Detección de diferencias en ciclovías de Bogotá
From: botCicloviaMaptimeBogota@osm-test

Reporte de modificaciones en ciclovías de Bogotá en OpenStreetMap.

Hora de inicio: $(date).

EOF

# Genera un archivo con todas las relaciones de cada ciclovía.
cat << EOF > ${CICLOVIA_IDS}
13772026
13430826
13772121
5655561
13772248
13772271
13775199
13772392
13772393
13772394
13775428
13775750
13776012
13776094
14290720
EOF

# Itera sobre cada relación de ciclovía, verificando si han habido cambios.
echo "Procesando segmentos de ciclovías..."
while read -r ID ; do
 echo "Procesando relación con id ${ID}."
 echo "Procesando relación con id ${ID}." >> ${LOG_FILE}

 # Define el query Overpass para un id específico de ciclovía.
 cat << EOF > ${QUERY_FILE}
[out:json];
rel(${ID});
(._;>;);
out; 
EOF
 cat ${QUERY_FILE} >> ${LOG_FILE}

 # Obtiene la geometría de un id específico de ciclovía.
 set +e
 wget -O "ciclovia-${ID}.json" --post-file="${QUERY_FILE}" "https://overpass-api.de/api/interpreter" >> ${LOG_FILE} 2>&1

 RET=${?}
 set -e
 if [ ${RET} -ne 0 ] ; then
  echo "WARN: Falló la descarga de la relación ${ID}."
  continue
 fi
 
 # Elimina la línea de fecha de OSM
 sed -i'' -e '/"timestamp_osm_base":/d' "ciclovia-${ID}.json"
 rm -f "ciclovia-${ID}.json-e"

 # Procesa el archivo descargado.
 if [ -r "${HISTORIC_FILES_DIR}/ciclovia-${ID}.json" ] ; then
  # Si hay un archivo histórico, lo compara con ese para ver diferencias.
  set +e
  diff "${HISTORIC_FILES_DIR}/ciclovia-${ID}.json" "ciclovia-${ID}.json"
  RET=${?}
  set -e
  if [ ${RET} -ne 0 ] ; then
   mv "ciclovia-${ID}.json" "${HISTORIC_FILES_DIR}/"
   cd "${HISTORIC_FILES_DIR}/"
   git commit "ciclovia-${ID}.json" -m "Nueva versión de ciclovía ${ID}."
   cd - > /dev/null
   echo "* Revisar https://osm.org/relation/${ID}" >> ${REPORT_CONTENT}
  else
   rm "ciclovia-${ID}.json"
  fi
 else
  # Si no hay archivo histórico, copia este archivo como histórico.
  mv "ciclovia-${ID}.json" "${HISTORIC_FILES_DIR}/"
  cd "${HISTORIC_FILES_DIR}/"
  git add "ciclovia-${ID}.json"
  git commit "ciclovia-${ID}.json" -m "Versión inicial de ciclovía ${ID}." >> "../${LOG_FILE}" 2>&1
  cd - > /dev/null
 fi

 # Espera entre requests para evitar errores.
 echo "Esperando ${WAIT_TIME} segundos entre requests..."
 sleep ${WAIT_TIME}

done < ${CICLOVIA_IDS}

# Itera sobre cada restricción de ciclovía.
echo "Obtiene los ids de las restricciones"
cat << EOF > "${QUERY_FILE}"
[out:csv(::id)];
(
  relation["restriction:conditional"]["name"="Ciclovia"];
);
out ids;
EOF
set +e
wget -O "${RESTRICTIONS_IDS}" --post-file="${QUERY_FILE}" "https://overpass-api.de/api/interpreter" >> "${LOG_FILE}" 2>&1
RET=${?}
set -e
if [ ${RET} -ne 0 ] ; then
 echo "ERROR: Falló la descarga de los ids."

else
 tail -n +2 "${RESTRICTIONS_IDS}" > "${RESTRICTIONS_IDS}.tmp" ; mv "${RESTRICTIONS_IDS}.tmp" "${RESTRICTIONS_IDS}"

 # Procesando restricciones.
 while read -r ID ; do
  echo "Procesando relación con id ${ID}." 
  echo "Procesando relación con id ${ID}." >> "${LOG_FILE}"

  # Define el query Overpass para un id específico de restricción de giro.
  cat << EOF > "${QUERY_FILE}"
[out:json];
rel(${ID});
(._;>;);
out; 
EOF
  cat "${QUERY_FILE}" >> "${LOG_FILE}"

  # Obtiene la geometría de un id específico de restricción de giro.
  set +e
  wget -O "giro-${ID}.json" --post-file="${QUERY_FILE}" "https://overpass-api.de/api/interpreter" >> "${LOG_FILE}" 2>&1
  RET=${?}
  set -e
  if [ ${RET} -ne 0 ] ; then
   echo "WARN: Falló la descarga de la relación ${ID}."
   continue
  fi
  
  # Elimina la línea de fecha de OSM
  sed -i'' -e '/"timestamp_osm_base":/d' "giro-${ID}.json"
  rm -f "giro-${ID}.json-e"
 
  # Procesa el archivo descargado.
  if [ -r "${HISTORIC_FILES_DIR}/giro-${ID}.json" ] ; then
   # Si hay un archivo histórico, lo compara con ese para ver diferencias.
   set +e
   diff "${HISTORIC_FILES_DIR}/giro-${ID}.json" "giro-${ID}.json"
   RET=${?}
   set -e
   if [ ${RET} -ne 0 ] ; then
    mv "giro-${ID}.json" "${HISTORIC_FILES_DIR}/"
    cd "${HISTORIC_FILES_DIR}/"
    git commit "giro-${ID}.json" -m "Nueva versión de giro ${ID}."
    cd - > /dev/null
    echo "* Revisar https://osm.org/relation/${ID}" >> ${REPORT_CONTENT}
   else
    rm "giro-${ID}.json"
   fi
  else
   # Si no hay archivo histórico, copia este archivo como histórico.
   mv "giro-${ID}.json" "${HISTORIC_FILES_DIR}/"
   cd "${HISTORIC_FILES_DIR}/"
   git add "giro-${ID}.json"
   git commit "giro-${ID}.json" -m "Versión inicial de giro ${ID}." >> "../${LOG_FILE}" 2>&1
   cd - > /dev/null
  fi
 
  # Espera entre requests para evitar errores.
  echo "Esperando ${WAIT_TIME} segundos entre requests..."
  sleep ${WAIT_TIME}
 
 done < "${RESTRICTIONS_IDS}"
fi

if [ -f "${REPORT_CONTENT}" ] ; then
 echo "$(date) Sending mail" >> ${LOG_FILE}
 cat "${REPORT_CONTENT}" >> ${REPORT}
 echo >> ${REPORT}
 echo "Hora de fin: $(date)" >> ${REPORT}
 echo >> ${REPORT}
 echo "Este reporte fue creado por medio de el script verificador: https://github.com/MaptimeBogota/ciclovias" >> ${REPORT}
 sendmail -v "${MAILS}" < ${REPORT}
fi

# Borra archivos temporales
rm -f "${QUERY_FILE}" "${CICLOVIA_IDS}" "${RESTRICTIONS_IDS}" "${REPORT}"

echo "$(date) Finishing process" >> ${LOG_FILE}
echo "$(date) =================" >> ${LOG_FILE}


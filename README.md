# Ciclovías
Mecanismo para controlar la calidad de la ciclovía.
Las ciclovías se componen de segmentos de vías y de restricciones de giro.

Este mecanismo es un script en Bash que se puede correr en cualquier máquina Linux.
Usa overpass para traer las relaciones de los segmentos de vías y las restricciones de giro.
Después compara los datos recuperados con una versión previamente guardada en git.
Si encuentra diferencias envía un reporte a algunas personas por medio de mail.

Este repositorio hace parte del proyecto de mapeo de ciclovías en OSM: https://wiki.openstreetmap.org/wiki/Colombia/Project-Ciclov%C3%ADas

## Instalación en Ubuntu

```
sudo apt -y install mutt
sudo apt -y install sendmail
sudo apt -y install postfix
```

Poner el FQDN 127.0.0.1 localhost.localdomain


###  Programación desde cron

```

# Corre el verificador de ciclovias todos los dias.
0 2 * * * cd ciclovia ; ./verificador.sh

# Borra logs viejos de la ciclovia.
0 0 * * * find ~/ciclovia/ -maxdepth 1 -type f -name "*.log*" -mtime +15 -exec rm {} \;
0 0 * * * find ~/ciclovia/ -maxdepth 1 -type f -name "*.json" -mtime +15 -exec rm {} \;
0 0 * * * find ~/ciclovia/ -maxdepth 1 -type f -name "*.txt*" -mtime +15 -exec rm {} \;
```

# Ciclovías
Mecanismo para controlar la calidad de la ciclovía.
Las ciclovías se componen de segmentos de vías y de restricciones de giro.

Este mecanismo es un script en Bash que se puede correr en cualquier máquina Linux.
Usa overpass para traer las relaciones de los segmentos de vías y las restricciones de giro.
Después compara los datos recuperados con una versión previamente guardada en git.
Si encuentra diferencias envía un reporte a algunas personas por medio de mail.


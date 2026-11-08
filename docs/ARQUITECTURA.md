
# Proyecto III - Paradigmas de Programacion

## Pipeline Funcional-Logico con Haskell, Prolog y UI

### 1. Descripcion general

Este proyecto implementa un pipeline que integra dos
paradigmas de programacion:

- Programacion funcional mediante Haskell.
- Programacion logica mediante SWI-Prolog.

El sistema recibe un archivo de texto estructurado
llamado problema.txt, interpreta su contenido,
construye un modelo intermedio y valida los datos.

Posteriormente genera automaticamente una base de
conocimiento Prolog, un archivo de consultas, un
reporte de validacion y una interfaz HTML.

El dominio seleccionado es el academico.

### 2. Objetivo general

Desarrollar un sistema capaz de transformar una
descripcion textual de un problema academico en
una base de conocimiento logica, ejecutable y
visualizable mediante una interfaz web.

### 3. Arquitectura del sistema

El pipeline sigue las siguientes etapas:

1. Lectura del archivo problema.txt.
2. Interpretacion del contenido con Parser.hs.
3. Construccion del modelo intermedio con Domain.hs.
4. Validacion de los datos con Validation.hs.
5. Generacion de Prolog mediante PrologGenerator.hs.
6. Construccion de la interfaz con HtmlGenerator.hs.
7. Coordinacion de la ejecucion desde Main.hs.

Todos los archivos generados dependen del contenido
del archivo de entrada.

### 4. Modulos Haskell

#### 4.1. Domain.hs

Define los tipos de datos utilizados para representar
las entidades, relaciones y reglas del problema.

Tipos principales:

- TipoEntidad.
- Entidad.
- TipoRelacion.
- Relacion.
- ReglaSolicitada.
- Problema.

El modelo intermedio permite trabajar con
estructuras de datos en lugar de realizar
simples reemplazos de texto.

#### 4.2. Parser.hs

Interpreta el archivo de entrada y separa
su contenido en secciones.

Reconoce:

- ENTIDADES.
- RELACIONES.
- REGLAS_SOLICITADAS.

Funciones principales:

- parsearProblema.
- procesarLinea.
- procesarEntidad.
- procesarRelacion.
- procesarRegla.
- validarSecciones.

Utiliza funciones puras y acumulacion de estados
mediante foldl.

#### 4.3. Validation.hs

Comprueba que los datos interpretados sean
coherentes con el dominio academico.

Funciones principales:

- validarProblema.
- validarEntidades.
- validarRelacion.
- validarRelacionesDuplicadas.
- validarReglas.
- tieneErrores.
- generarReporte.

Las incidencias se clasifican como errores
o advertencias.

#### 4.4. PrologGenerator.hs

Transforma el modelo intermedio en codigo Prolog.

Funciones principales:

- generarConocimiento.
- generarConsultas.
- generarEntidad.
- generarRelacion.
- generarRegla.
- atomoProlog.

El generador evita hechos duplicados y
conserva los numeros de linea originales
mediante comentarios de trazabilidad.

#### 4.5. HtmlGenerator.hs

Construye automaticamente una interfaz web
a partir del modelo intermedio.

Funciones principales:

- generarHtml.
- seccionEntidades.
- seccionRelaciones.
- seccionCodigo.
- seccionValidacion.
- escaparHtml.

La interfaz contiene:

- Estadisticas academicas.
- Entidades detectadas.
- Relaciones generadas.
- Hechos y reglas Prolog.
- Consultas sugeridas.
- Reporte de validacion.

#### 4.6. Main.hs

Coordina todas las etapas del pipeline.

Funciones principales:

- main.
- prepararDirectorios.
- procesarProblema.
- reportarErroresParser.
- limpiarSalidas.

Permite procesar el archivo predeterminado
o proporcionar otra ruta de entrada.

### 5. Dominio academico

El sistema trabaja con tres tipos de entidades:

- Estudiante.
- Curso.
- Docente.

Relaciones:

- lleva(Estudiante, Curso).
- imparte(Docente, Curso).

### 6. Reglas Prolog

#### 6.1. companero/2

Determina si dos estudiantes distintos
estan matriculados en un mismo curso.

#### 6.2. curso_con_docente/2

Relaciona un curso con el docente que lo imparte.

#### 6.3. comparte_docente/2

Determina si dos estudiantes comparten al menos
un docente, aunque lleven cursos diferentes.

### 7. Validaciones

El sistema permite detectar:

- Entidades duplicadas.
- Relaciones duplicadas.
- Entidades inexistentes.
- Tipos incorrectos en relaciones.
- Formatos invalidos.
- Secciones obligatorias ausentes.
- Secciones repetidas.
- Reglas desconocidas.
- Reglas solicitadas repetidas.

Cuando existen errores graves, el sistema
detiene la generacion de productos ejecutables.

Cuando existen advertencias, puede continuar
y registrar las incidencias en el reporte.

### 8. Archivos generados

El pipeline produce:

- data/output/conocimiento.pl
- data/output/consultas.pl
- data/output/reporte_validacion.txt
- web/index.html

Estos archivos se regeneran automaticamente
a partir del problema de entrada.

### 9. Ejecucion

Desde la carpeta principal del proyecto
se utiliza el siguiente comando:

    runghc -ihaskell\src haskell\src\Main.hs

Para procesar otro archivo:

    runghc -ihaskell\src haskell\src\Main.hs tests\test07_segundo_problema.txt

### 10. Pruebas realizadas

Se prepararon trece escenarios principales:

1. Archivo academico valido.
2. Entidades y relaciones duplicadas.
3. Entidad inexistente.
4. Formato invalido.
5. Seccion obligatoria ausente.
6. Regla desconocida.
7. Segundo problema academico.
8. Relaciones con tipos incorrectos.
9. Secciones repetidas.
10. Nombres con caracteres especiales.
11. Eliminacion de duplicados Prolog.
12. Recuperacion despues de errores.
13. Consultas logicas del segundo problema.

Estas pruebas permiten verificar el parsing,
las validaciones, la generacion de resultados
y la integracion con SWI-Prolog.

### 11. Tecnologias utilizadas

- Haskell.
- GHC 9.10.3.
- Cabal.
- SWI-Prolog.
- HTML y CSS.
- Doxygen.
- Visual Studio Code.

### 12. Conclusiones tecnicas

El proyecto demuestra la integracion entre
la programacion funcional y la programacion logica.

Haskell permite transformar datos mediante
funciones puras y estructuras tipadas.

Prolog permite realizar inferencias mediante
hechos y reglas logicas.

La interfaz HTML facilita la visualizacion
del conocimiento generado.

El pipeline permite procesar diferentes
archivos de entrada sin modificar manualmente
el codigo fuente ni la interfaz.

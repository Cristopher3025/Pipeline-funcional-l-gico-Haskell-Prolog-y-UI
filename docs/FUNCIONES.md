
# Referencia tecnica de funciones

## Proyecto III - Pipeline Funcional-Logico

Este documento describe los tipos de datos y las funciones
principales que conforman el sistema desarrollado en Haskell.

El proyecto integra programacion funcional con Haskell,
programacion logica con SWI-Prolog y una interfaz HTML.

---

# 1. Modulo Domain.hs

## 1.1. Responsabilidad

Domain.hs define el modelo intermedio utilizado para
representar la informacion del dominio academico.

Su objetivo es transformar conceptos del problema en
estructuras de datos propias de Haskell.

Este modulo no realiza operaciones de entrada/salida.

## 1.2. TipoEntidad

```haskell
data TipoEntidad
    = Estudiante
    | Curso
    | Docente
    deriving (Eq, Show)
```

Representa las tres categorias admitidas.

Los constructores determinan que tipos de entidades
pueden existir dentro del problema academico.

La derivacion Eq permite comparar los valores,
mientras que Show permite representarlos como texto.

## 1.3. Entidad

```haskell
data Entidad = Entidad
    { tipoEntidad :: TipoEntidad
    , nombreEntidad :: String
    , lineaEntidad :: Int
    } deriving (Eq, Show)
```

Representa una entidad declarada en el archivo.

Campos:

- tipoEntidad: categoria de la entidad.
- nombreEntidad: identificador textual.
- lineaEntidad: numero de linea de origen.

Ejemplo:

```haskell
Entidad Estudiante "Ana" 3
```

El numero de linea permite conservar trazabilidad.

## 1.4. TipoRelacion

```haskell
data TipoRelacion
    = Lleva
    | Imparte
    deriving (Eq, Show)
```

Representa las relaciones admitidas por el dominio.

Lleva relaciona estudiantes con cursos.

Imparte relaciona docentes con cursos.

## 1.5. Relacion

```haskell
data Relacion = Relacion
    { tipoRelacion :: TipoRelacion
    , argumentos :: [String]
    , lineaRelacion :: Int
    } deriving (Eq, Show)
```

Almacena una relacion del problema.

Ejemplo:

```haskell
Relacion Lleva ["Ana", "Paradigmas"] 12
```

El campo argumentos contiene los nombres de
las entidades relacionadas.

## 1.6. ReglaSolicitada

Representa las reglas logicas disponibles:

- Companeros.
- CursoConDocente.
- ComparteDocente.

Utilizar constructores evita generar reglas
arbitrarias a partir de texto libre.

## 1.7. Problema

Agrupa:

- Lista de entidades.
- Lista de relaciones.
- Lista de reglas solicitadas.

Es la estructura principal que utilizan
los generadores y las validaciones.

---

# 2. Modulo Parser.hs

## 2.1. Responsabilidad

Parser.hs interpreta el contenido estructurado
de problema.txt y construye un valor Problema.

Utiliza funciones puras para procesar las lineas.

## 2.2. limpiar

```haskell
limpiar :: String -> String
```

Entrada: cadena de texto.

Salida: cadena sin espacios iniciales ni finales.

Esta funcion facilita interpretar declaraciones
con espacios adicionales.

## 2.3. separarPrimero

```haskell
separarPrimero :: Char -> String
              -> Maybe (String, String)
```

Recibe:

- Un caracter separador.
- Una cadena de texto.

Devuelve:

- Just con dos fragmentos si encuentra el separador.
- Nothing si no lo encuentra.

Ejemplo:

```haskell
separarPrimero ':' "estudiante: Ana"
```

Resultado:

```haskell
Just ("estudiante", "Ana")
```

## 2.4. identificarSeccion

```haskell
identificarSeccion :: String -> Maybe Seccion
```

Reconoce los encabezados:

- ENTIDADES.
- RELACIONES.
- REGLAS_SOLICITADAS.

Devuelve Nothing si el texto no corresponde
a un encabezado conocido.

## 2.5. identificarEntidad

```haskell
identificarEntidad :: String -> Maybe TipoEntidad
```

Convierte una palabra textual en un constructor
del tipo TipoEntidad.

Por ejemplo, "estudiante" se convierte en Estudiante.

## 2.6. identificarRelacion

```haskell
identificarRelacion :: String -> Maybe TipoRelacion
```

Reconoce las relaciones lleva e imparte.

## 2.7. identificarRegla

```haskell
identificarRegla :: String -> Maybe ReglaSolicitada
```

Reconoce las reglas permitidas del dominio.

## 2.8. procesarEntidad

```haskell
procesarEntidad :: Int -> String
                -> EstadoParser -> EstadoParser
```

Recibe:

- Numero de linea.
- Contenido textual.
- Estado actual del parser.

Devuelve un nuevo estado.

Si la declaracion es correcta, incorpora una entidad.

Si tiene un formato incorrecto, registra un error.

## 2.9. procesarRelacion

```haskell
procesarRelacion :: Int -> String
                 -> EstadoParser -> EstadoParser
```

Interpreta declaraciones como:

```text
lleva: Ana, Paradigmas
```

Comprueba la sintaxis y la cantidad de argumentos.

La existencia y los tipos de las entidades
se comprueban posteriormente en Validation.hs.

## 2.10. procesarRegla

```haskell
procesarRegla :: Int -> String
              -> EstadoParser -> EstadoParser
```

Interpreta una regla solicitada.

Si la regla es desconocida, registra un error.

## 2.11. procesarLinea

```haskell
procesarLinea :: EstadoParser
              -> (Int, String)
              -> EstadoParser
```

Es una de las funciones principales del parser.

Analiza una linea considerando la seccion activa.

Reconoce:

- Encabezados.
- Entidades.
- Relaciones.
- Reglas.
- Comentarios.
- Lineas vacias.
- Secciones repetidas.

Devuelve un nuevo estado sin modificar
directamente el estado anterior.

## 2.12. validarSecciones

```haskell
validarSecciones :: EstadoParser -> [String]
```

Comprueba que aparezcan las tres secciones
obligatorias del archivo de entrada.

Devuelve una lista de mensajes de error.

## 2.13. parsearProblema

```haskell
parsearProblema :: String
                -> Either [String] Problema
```

Es la funcion publica principal del modulo.

Recibe el contenido del archivo como String.

Utiliza foldl para procesar todas las lineas.

Devuelve:

- Right Problema si la interpretacion es correcta.
- Left [String] cuando existen errores.

El tipo Either permite representar explicitamente
una operacion que puede tener exito o fallar.

---

# 3. Modulo Validation.hs

## 3.1. Responsabilidad

Validation.hs realiza las comprobaciones semanticas
sobre el modelo intermedio.

Distingue entre errores y advertencias.

## 3.2. Severidad

```haskell
data Severidad = Error | Advertencia
```

Permite clasificar las incidencias.

Los errores impiden generar resultados ejecutables.

Las advertencias informan situaciones como duplicados.

## 3.3. Incidencia

Contiene:

- Severidad.
- Numero de linea.
- Mensaje descriptivo.

Ejemplo:

```haskell
Incidencia Error 9 "Entidad inexistente"
```

## 3.4. existeEntidad

```haskell
existeEntidad :: [Entidad]
              -> TipoEntidad
              -> String
              -> Bool
```

Comprueba si existe una entidad con un nombre
y un tipo determinados.

Utiliza any para buscar una coincidencia.

## 3.5. validarEntidades

```haskell
validarEntidades :: [Entidad] -> [Incidencia]
```

Detecta entidades repetidas.

Compara tanto el tipo como el nombre.

Genera advertencias cuando encuentra duplicados.

## 3.6. validarRelacion

```haskell
validarRelacion :: [Entidad]
                -> Relacion
                -> [Incidencia]
```

Comprueba la coherencia de los argumentos.

Para Lleva:

- El primer argumento debe ser estudiante.
- El segundo argumento debe ser curso.

Para Imparte:

- El primer argumento debe ser docente.
- El segundo argumento debe ser curso.

Si una referencia no cumple estos requisitos,
genera una incidencia de tipo Error.

## 3.7. validarRelacionesDuplicadas

```haskell
validarRelacionesDuplicadas
    :: [Relacion] -> [Incidencia]
```

Identifica relaciones equivalentes.

Compara el tipo y los argumentos.

No considera el numero de linea al determinar
si dos relaciones son duplicadas.

## 3.8. validarReglas

```haskell
validarReglas
    :: [ReglaSolicitada] -> [Incidencia]
```

Detecta solicitudes repetidas de reglas logicas.

Utiliza nub para identificar valores unicos.

## 3.9. validarProblema

```haskell
validarProblema :: Problema -> [Incidencia]
```

Es la funcion principal del modulo.

Coordina las validaciones de:

- Entidades.
- Relaciones.
- Relaciones duplicadas.
- Reglas solicitadas.

Devuelve una lista de incidencias.

## 3.10. tieneErrores

```haskell
tieneErrores :: [Incidencia] -> Bool
```

Determina si existe al menos una incidencia
con severidad Error.

Se utiliza en Main.hs para decidir si el
pipeline puede continuar.

## 3.11. generarReporte

```haskell
generarReporte :: [Incidencia] -> String
```

Convierte las incidencias en texto legible.

El contenido generado se guarda posteriormente
en reporte_validacion.txt.

---

# 4. Modulo PrologGenerator.hs

## 4.1. Responsabilidad

PrologGenerator.hs transforma el modelo intermedio
en hechos, reglas y consultas Prolog.

No necesita ejecutar Prolog durante la generacion.

## 4.2. atomoProlog

```haskell
atomoProlog :: String -> String
```

Convierte nombres de entidades en atomos Prolog.

Agrega comillas y escapa caracteres especiales,
incluyendo apostrofes y barras invertidas.

Ejemplo:

```text
José O'Connor
```

Se convierte en:

```prolog
'José O''Connor'
```

Esto permite generar codigo Prolog valido.

## 4.3. generarEntidad

```haskell
generarEntidad :: Entidad -> String
```

Produce un hecho Prolog a partir de una entidad.

Incluye un comentario con el numero de linea.

## 4.4. generarRelacion

```haskell
generarRelacion :: Relacion -> String
```

Produce un hecho Prolog correspondiente
a una relacion academica.

## 4.5. generarRegla

```haskell
generarRegla :: ReglaSolicitada -> String
```

Selecciona una plantilla Prolog segun
el constructor de la regla solicitada.

Las reglas disponibles son:

- companero/2.
- curso_con_docente/2.
- comparte_docente/2.

## 4.6. generarConocimiento

```haskell
generarConocimiento :: Problema -> String
```

Construye el contenido completo de conocimiento.pl.

Incluye:

- Encabezado.
- Hechos de entidades.
- Hechos de relaciones.
- Reglas logicas.

Utiliza nub y nubBy para evitar duplicados.

## 4.7. generarConsultas

```haskell
generarConsultas :: Problema -> String
```

Produce el contenido de consultas.pl.

Incluye consultas generales y consultas
correspondientes a las reglas solicitadas.

Las consultas sugeridas se escriben como
comentarios para que puedan ejecutarse manualmente.

---

# 5. Modulo HtmlGenerator.hs

## 5.1. Responsabilidad

HtmlGenerator.hs construye una interfaz
visual a partir del modelo intermedio.

La pagina no contiene entidades escritas
manualmente en su codigo fuente.

## 5.2. escaparHtml

```haskell
escaparHtml :: String -> String
```

Convierte caracteres especiales en entidades HTML.

Por ejemplo:

- & se transforma en &amp;.
- < se transforma en &lt;.
- > se transforma en &gt;.

Evita que el contenido del archivo de entrada
sea interpretado como etiquetas HTML.

## 5.3. entidadesUnicas

```haskell
entidadesUnicas :: Problema -> [Entidad]
```

Elimina entidades repetidas de la visualizacion.

## 5.4. relacionesUnicas

```haskell
relacionesUnicas :: Problema -> [Relacion]
```

Elimina relaciones equivalentes de la interfaz.

## 5.5. contar

```haskell
contar :: TipoEntidad -> [Entidad] -> Int
```

Cuenta entidades de un tipo especifico.

Permite calcular las estadisticas del panel.

## 5.6. tarjeta

```haskell
tarjeta :: String -> Int -> String -> String
```

Genera una tarjeta HTML con:

- Titulo.
- Cantidad.
- Icono.

## 5.7. filaEntidad

```haskell
filaEntidad :: Entidad -> String
```

Construye una fila HTML con el nombre,
el tipo y el numero de linea.

## 5.8. filaRelacion

```haskell
filaRelacion :: Relacion -> String
```

Construye una fila HTML con los argumentos,
el tipo de relacion y su linea de origen.

## 5.9. seccionEntidades

```haskell
seccionEntidades :: Problema -> String
```

Genera la tabla completa de entidades.

## 5.10. seccionRelaciones

```haskell
seccionRelaciones :: Problema -> String
```

Genera la tabla de relaciones academicas.

## 5.11. seccionCodigo

```haskell
seccionCodigo :: String -> String
              -> String -> String
```

Permite mostrar texto generado en bloques
de codigo dentro de la interfaz.

Se utiliza para presentar conocimiento.pl
y las consultas sugeridas.

## 5.12. seccionValidacion

```haskell
seccionValidacion :: [Incidencia] -> String
```

Genera la seccion que muestra el resultado
de las validaciones.

## 5.13. generarHtml

```haskell
generarHtml :: Problema -> [Incidencia] -> String
```

Es la funcion principal del modulo.

Recibe:

- Modelo intermedio.
- Lista de incidencias.

Devuelve el documento HTML completo.

La interfaz contiene estadisticas, tablas,
reglas, consultas y reporte de validacion.

---

# 6. Modulo Main.hs

## 6.1. Responsabilidad

Main.hs representa el punto de entrada del programa.

Coordina los modulos y administra la lectura
y escritura de archivos.

## 6.2. prepararDirectorios

```haskell
prepararDirectorios :: IO ()
```

Crea las carpetas necesarias para guardar
los archivos generados.

## 6.3. limpiarSalidas

```haskell
limpiarSalidas :: IO ()
```

Elimina productos generados anteriormente
cuando una ejecucion falla.

Evita que los archivos antiguos se confundan
con resultados del problema actual.

## 6.4. reportarErroresParser

```haskell
reportarErroresParser :: [String] -> IO ()
```

Construye el reporte de errores sintacticos,
elimina salidas obsoletas y detiene la ejecucion.

## 6.5. procesarProblema

```haskell
procesarProblema :: String -> IO ()
```

Coordina el procesamiento del texto.

Ejecuta:

1. Parsing.
2. Validacion.
3. Generacion del reporte.
4. Generacion de Prolog.
5. Generacion de consultas.
6. Generacion de HTML.

Si existen errores graves, detiene el proceso.

## 6.6. main

```haskell
main :: IO ()
```

Es el punto de entrada del programa.

Obtiene la ruta de entrada y coordina
la ejecucion completa.

Utiliza IO porque realiza operaciones
de lectura y escritura de archivos.

---

# 7. Integracion de los modulos

El pipeline completo funciona de esta manera:

1. Main.hs lee el archivo de entrada.
2. Parser.hs interpreta su contenido.
3. Domain.hs proporciona las estructuras del modelo.
4. Validation.hs comprueba los datos.
5. PrologGenerator.hs construye la base logica.
6. HtmlGenerator.hs genera la interfaz.
7. Main.hs escribe los resultados.

Las transformaciones principales se realizan
mediante funciones puras.

Las operaciones de entrada y salida se
concentran principalmente en Main.hs.

---

# 8. Conceptos funcionales utilizados

## 8.1. Tipos algebraicos

Permiten representar distintas alternativas
mediante constructores definidos por el programador.

Ejemplo:

```haskell
data TipoRelacion = Lleva | Imparte
```

## 8.2. Pattern matching

Permite seleccionar comportamientos
segun la estructura de un valor.

Se utiliza en el parser y los generadores.

## 8.3. Inmutabilidad

Las funciones no modifican directamente
los valores existentes.

Producen nuevos resultados.

## 8.4. foldl

Permite recorrer una lista acumulando
un estado de procesamiento.

Se utiliza para interpretar el archivo linea por linea.

## 8.5. map y concatMap

Permiten transformar listas de valores.

Se utilizan para generar hechos Prolog
y fragmentos HTML.

## 8.6. filter

Permite seleccionar elementos que
cumplen una condicion.

Se utiliza en validaciones y estadisticas.

## 8.7. Either

Representa operaciones que pueden
devolver un resultado o un error.

El parser utiliza:

```haskell
Either [String] Problema
```

## 8.8. Maybe

Representa resultados opcionales.

Permite indicar que un valor puede
estar presente o ausente.

## 8.9. IO

Representa operaciones que interactuan
con el entorno externo.

Se utiliza para leer archivos,
escribir resultados y mostrar mensajes.

---

# 9. Conclusion tecnica

La arquitectura modular separa las responsabilidades
de interpretacion, validacion, generacion y ejecucion.

El modelo intermedio permite transformar los datos
sin depender directamente del formato textual.

Las funciones puras facilitan las pruebas
y la comprension del codigo.

La integracion con Prolog permite aplicar
reglas logicas sobre los hechos generados.

La interfaz HTML permite visualizar los resultados.

El sistema puede procesar distintos archivos
academicos sin modificar manualmente los
generadores ni la interfaz.

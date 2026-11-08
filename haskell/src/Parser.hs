
module Parser
    ( parsearProblema
    ) where

import Domain
import Data.Char (isSpace)
import Data.List (stripPrefix)

-- ============================================================
-- PROYECTO III - PARADIGMAS DE PROGRAMACION
-- MODULO: Parser
-- DESCRIPCION:
-- Interpreta un archivo de texto estructurado y construye
-- un modelo intermedio utilizando los tipos de Domain.hs.
-- ============================================================

-- Secciones permitidas en el archivo de entrada.
data Seccion
    = SinSeccion
    | SeccionEntidades
    | SeccionRelaciones
    | SeccionReglas
    deriving (Eq, Show)

-- Estado utilizado durante la interpretacion.
data EstadoParser = EstadoParser
    { seccionActual :: Seccion
    , seccionesVistas :: [Seccion]
    , entidadesLeidas :: [Entidad]
    , relacionesLeidas :: [Relacion]
    , reglasLeidas :: [ReglaSolicitada]
    , erroresParser :: [String]
    }

-- Estado inicial del parser.
estadoInicial :: EstadoParser
estadoInicial = EstadoParser
    { seccionActual = SinSeccion
    , seccionesVistas = []
    , entidadesLeidas = []
    , relacionesLeidas = []
    , reglasLeidas = []
    , erroresParser = []
    }

-- ============================================================
-- FUNCIONES AUXILIARES
-- ============================================================

-- Elimina espacios al inicio y al final.
limpiar :: String -> String
limpiar = reverse . dropWhile isSpace
        . reverse . dropWhile isSpace

-- Divide una cadena en la primera aparicion de un separador.
separarPrimero :: Char -> String -> Maybe (String, String)
separarPrimero separador texto =
    case break (== separador) texto of
        (izquierda, _ : derecha) ->
            Just (limpiar izquierda, limpiar derecha)

        _ ->
            Nothing

-- Comprueba si un texto comienza con un prefijo.
esPrefijoDe :: String -> String -> Bool
esPrefijoDe prefijo texto =
    case stripPrefix prefijo texto of
        Just _ -> True
        Nothing -> False

-- Agrega un error al estado del parser.
agregarError :: Int -> String -> EstadoParser -> EstadoParser
agregarError numero mensaje estado =
    estado
        { erroresParser =
            erroresParser estado ++
            ["Linea " ++ show numero ++ ": " ++ mensaje]
        }

-- ============================================================
-- IDENTIFICACION DE SECCIONES
-- ============================================================

-- Identifica los encabezados permitidos.
identificarSeccion :: String -> Maybe Seccion
identificarSeccion "[ENTIDADES]" =
    Just SeccionEntidades

identificarSeccion "[RELACIONES]" =
    Just SeccionRelaciones

identificarSeccion "[REGLAS_SOLICITADAS]" =
    Just SeccionReglas

identificarSeccion _ =
    Nothing

-- ============================================================
-- IDENTIFICACION DE ENTIDADES
-- ============================================================

-- Convierte un nombre textual en un tipo de entidad.
identificarEntidad :: String -> Maybe TipoEntidad
identificarEntidad "estudiante" =
    Just Estudiante

identificarEntidad "curso" =
    Just Curso

identificarEntidad "docente" =
    Just Docente

identificarEntidad _ =
    Nothing

-- ============================================================
-- IDENTIFICACION DE RELACIONES
-- ============================================================

-- Convierte un nombre textual en un tipo de relacion.
identificarRelacion :: String -> Maybe TipoRelacion
identificarRelacion "lleva" =
    Just Lleva

identificarRelacion "imparte" =
    Just Imparte

identificarRelacion _ =
    Nothing

-- ============================================================
-- IDENTIFICACION DE REGLAS
-- ============================================================

-- Reconoce las reglas logicas del dominio academico.
identificarRegla :: String -> Maybe ReglaSolicitada
identificarRegla "companeros" =
    Just Companeros

identificarRegla "curso_con_docente" =
    Just CursoConDocente

identificarRegla "comparte_docente" =
    Just ComparteDocente

identificarRegla _ =
    Nothing

-- ============================================================
-- PROCESAMIENTO DE ENTIDADES
-- ============================================================

-- Interpreta una declaracion de entidad.
--
-- Ejemplo:
-- estudiante: Ana
--
-- Resultado:
-- Entidad Estudiante "Ana" numeroLinea

procesarEntidad :: Int -> String -> EstadoParser -> EstadoParser
procesarEntidad numero texto estado =
    case separarPrimero ':' texto of

        Just (tipo, nombre) ->
            case identificarEntidad tipo of

                Just tipoValido
                    | not (null nombre) ->
                        estado
                            { entidadesLeidas =
                                entidadesLeidas estado ++
                                [Entidad tipoValido nombre numero]
                            }

                _ ->
                    agregarError numero
                        "Tipo de entidad desconocido o nombre vacio"
                        estado

        Nothing ->
            agregarError numero
                "Formato de entidad invalido"
                estado

-- ============================================================
-- PROCESAMIENTO DE RELACIONES
-- ============================================================

-- Interpreta una declaracion de relacion.
--
-- Ejemplo:
-- lleva: Ana, Paradigmas
--
-- Resultado:
-- Relacion Lleva ["Ana", "Paradigmas"] numeroLinea

procesarRelacion :: Int -> String -> EstadoParser -> EstadoParser
procesarRelacion numero texto estado =
    case separarPrimero ':' texto of

        Just (tipo, contenido) ->
            case ( identificarRelacion tipo
                 , separarPrimero ',' contenido
                 ) of

                (Just relacion, Just (origen, destino))
                    | not (null origen)
                    , not (null destino)
                    , ',' `notElem` destino ->
                        estado
                            { relacionesLeidas =
                                relacionesLeidas estado ++
                                [Relacion relacion
                                    [origen, destino] numero]
                            }

                _ ->
                    agregarError numero
                        "Relacion desconocida o argumentos invalidos"
                        estado

        Nothing ->
            agregarError numero
                "Formato de relacion invalido"
                estado

-- ============================================================
-- PROCESAMIENTO DE REGLAS
-- ============================================================

-- Interpreta una regla solicitada.
procesarRegla :: Int -> String -> EstadoParser -> EstadoParser
procesarRegla numero texto estado =
    case identificarRegla texto of

        Just regla ->
            estado
                { reglasLeidas =
                    reglasLeidas estado ++ [regla]
                }

        Nothing ->
            agregarError numero
                ("Regla no reconocida: " ++ texto)
                estado

-- ============================================================
-- PROCESAMIENTO DE LINEAS
-- ============================================================

-- Procesa una linea de acuerdo con la seccion activa.
--
-- Tambien identifica:
-- * Lineas vacias.
-- * Comentarios.
-- * Encabezados desconocidos.
-- * Secciones repetidas.
-- * Contenido fuera de una seccion.

procesarLinea :: EstadoParser -> (Int, String) -> EstadoParser
procesarLinea estado (numero, contenido) =
    let
        texto = limpiar contenido
    in
        if null texto || "#" `esPrefijoDe` texto
        then
            estado

        else
            case identificarSeccion texto of

                Just nuevaSeccion ->
                    if nuevaSeccion `elem` seccionesVistas estado
                    then
                        -- CORRECCION:
                        -- Registra el encabezado repetido, pero
                        -- actualiza la seccion activa para evitar
                        -- interpretar mal las siguientes lineas.
                        agregarError numero
                            "Seccion repetida"
                            (estado
                                { seccionActual = nuevaSeccion })

                    else
                        estado
                            { seccionActual = nuevaSeccion
                            , seccionesVistas =
                                seccionesVistas estado ++
                                [nuevaSeccion]
                            }

                Nothing ->
                    if "[" `esPrefijoDe` texto
                    then
                        agregarError numero
                            "Encabezado de seccion desconocido"
                            estado

                    else
                        case seccionActual estado of

                            SinSeccion ->
                                agregarError numero
                                    "Contenido fuera de una seccion"
                                    estado

                            SeccionEntidades ->
                                procesarEntidad numero texto estado

                            SeccionRelaciones ->
                                procesarRelacion numero texto estado

                            SeccionReglas ->
                                procesarRegla numero texto estado

-- ============================================================
-- VALIDACION DE SECCIONES OBLIGATORIAS
-- ============================================================

-- Detecta secciones que no aparecen en el archivo.
validarSecciones :: EstadoParser -> [String]
validarSecciones estado =
    [ "Falta la seccion: " ++ nombre
    | (seccion, nombre) <-
        [ (SeccionEntidades, "[ENTIDADES]")
        , (SeccionRelaciones, "[RELACIONES]")
        , (SeccionReglas, "[REGLAS_SOLICITADAS]")
        ]
    , seccion `notElem` seccionesVistas estado
    ]

-- ============================================================
-- FUNCION PRINCIPAL
-- ============================================================

-- Convierte el contenido del archivo en un Problema.
--
-- Right Problema:
--     La interpretacion fue exitosa.
--
-- Left [String]:
--     Se encontraron errores de formato o estructura.

parsearProblema :: String -> Either [String] Problema
parsearProblema contenido =
    let
        -- Agrega un numero a cada linea.
        lineas =
            zip [1..] (lines contenido)

        -- Procesa todas las lineas utilizando foldl.
        estadoFinal =
            foldl procesarLinea estadoInicial lineas

        -- Reune errores encontrados y secciones faltantes.
        errores =
            erroresParser estadoFinal ++
            validarSecciones estadoFinal

        -- Construye el modelo intermedio.
        problema =
            Problema
                { entidades =
                    entidadesLeidas estadoFinal

                , relaciones =
                    relacionesLeidas estadoFinal

                , reglasSolicitadas =
                    reglasLeidas estadoFinal
                }
    in
        if null errores
        then
            Right problema
        else
            Left errores

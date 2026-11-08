
module Validation
    ( Severidad(..)
    , Incidencia(..)
    , validarProblema
    , tieneErrores
    , generarReporte
    ) where

import Domain
import Data.List (nub)

-- Nivel de gravedad de una incidencia.
data Severidad
    = Error
    | Advertencia
    deriving (Eq, Show)

-- Representa un problema detectado.
data Incidencia = Incidencia
    { severidad :: Severidad
    , lineaIncidencia :: Int
    , mensajeIncidencia :: String
    } deriving (Eq, Show)

-- Crea una incidencia.
crearIncidencia :: Severidad -> Int -> String -> Incidencia
crearIncidencia nivel numero mensaje =
    Incidencia nivel numero mensaje

-- Busca si existe una entidad del tipo indicado.
existeEntidad :: [Entidad] -> TipoEntidad -> String -> Bool
existeEntidad lista tipo nombre =
    any coincide lista
  where
    coincide entidad =
        tipoEntidad entidad == tipo &&
        nombreEntidad entidad == nombre

-- Detecta entidades duplicadas.
validarEntidades :: [Entidad] -> [Incidencia]
validarEntidades lista = revisar [] lista
  where
    revisar _ [] = []

    revisar anteriores (actual:resto) =
        let
            duplicada =
                any
                    (\e ->
                        tipoEntidad e == tipoEntidad actual &&
                        nombreEntidad e == nombreEntidad actual)
                    anteriores

            incidencias =
                if duplicada
                then
                    [crearIncidencia
                        Advertencia
                        (lineaEntidad actual)
                        ("Entidad duplicada: " ++
                         nombreEntidad actual)]
                else []
        in
            incidencias ++
            revisar (actual:anteriores) resto

-- Comprueba las referencias de una relacion.
validarRelacion :: [Entidad] -> Relacion -> [Incidencia]
validarRelacion lista relacion =
    case (tipoRelacion relacion, argumentos relacion) of

        (Lleva, [estudiante, curso]) ->
            comprobar Estudiante estudiante ++
            comprobar Curso curso

        (Imparte, [docente, curso]) ->
            comprobar Docente docente ++
            comprobar Curso curso

        _ ->
            [crearIncidencia
                Error
                (lineaRelacion relacion)
                "Relacion con argumentos invalidos"]
  where
    comprobar tipo nombre =
        if existeEntidad lista tipo nombre
        then []
        else
            [crearIncidencia
                Error
                (lineaRelacion relacion)
                ("No existe una entidad de tipo " ++
                 show tipo ++ " con nombre: " ++ nombre)]

-- Detecta relaciones repetidas.
validarRelacionesDuplicadas :: [Relacion] -> [Incidencia]
validarRelacionesDuplicadas lista = revisar [] lista
  where
    revisar _ [] = []

    revisar anteriores (actual:resto) =
        let
            duplicada =
                any
                    (\r ->
                        tipoRelacion r == tipoRelacion actual &&
                        argumentos r == argumentos actual)
                    anteriores

            incidencias =
                if duplicada
                then
                    [crearIncidencia
                        Advertencia
                        (lineaRelacion actual)
                        ("Relacion duplicada: " ++
                         show (tipoRelacion actual) ++ " " ++
                         show (argumentos actual))]
                else []
        in
            incidencias ++
            revisar (actual:anteriores) resto

-- Comprueba si hay reglas repetidas.
validarReglas :: [ReglaSolicitada] -> [Incidencia]
validarReglas reglas =
    [crearIncidencia
        Advertencia
        0
        ("Regla solicitada repetida: " ++ show regla)
    | regla <- nub reglas
    , length (filter (== regla) reglas) > 1
    ]

-- Ejecuta todas las validaciones semanticas.
validarProblema :: Problema -> [Incidencia]
validarProblema problema =
    let
        listaEntidades = entidades problema
        listaRelaciones = relaciones problema
        listaReglas = reglasSolicitadas problema
    in
        validarEntidades listaEntidades ++
        concatMap
            (validarRelacion listaEntidades)
            listaRelaciones ++
        validarRelacionesDuplicadas listaRelaciones ++
        validarReglas listaReglas

-- Determina si existe algun error grave.
tieneErrores :: [Incidencia] -> Bool
tieneErrores =
    any (\incidencia -> severidad incidencia == Error)

-- Convierte una incidencia en texto.
formatearIncidencia :: Incidencia -> String
formatearIncidencia incidencia =
    let
        ubicacion =
            if lineaIncidencia incidencia > 0
            then "Linea " ++ show (lineaIncidencia incidencia)
            else "General"
    in
        "[" ++ show (severidad incidencia) ++ "] " ++
        ubicacion ++ ": " ++ mensajeIncidencia incidencia

-- Construye el contenido del reporte.
generarReporte :: [Incidencia] -> String
generarReporte incidencias =
    unlines $
        [ "REPORTE DE VALIDACION"
        , "====================="
        , ""
        ] ++
        if null incidencias
        then ["Sin errores ni advertencias."]
        else map formatearIncidencia incidencias

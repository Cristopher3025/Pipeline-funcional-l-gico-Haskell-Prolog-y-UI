
module PrologGenerator
    ( generarConocimiento
    , generarConsultas
    ) where

import Domain
import Data.List (nub, nubBy)

-- Convierte un nombre en un atomo Prolog seguro.
-- Escapa apostrofes, barras invertidas y controles.
atomoProlog :: String -> String
atomoProlog texto =
    "'" ++ concatMap escapar texto ++ "'"
  where
    escapar '\'' = "''"
    escapar '\\' = "\\\\"
    escapar '\n' = "\\n"
    escapar '\r' = "\\r"
    escapar '\t' = "\\t"
    escapar caracter = [caracter]

-- Convierte el tipo Haskell en un predicado Prolog.
nombreEntidadProlog :: TipoEntidad -> String
nombreEntidadProlog Estudiante = "estudiante"
nombreEntidadProlog Curso = "curso"
nombreEntidadProlog Docente = "docente"

-- Convierte una relacion en un predicado Prolog.
nombreRelacionProlog :: TipoRelacion -> String
nombreRelacionProlog Lleva = "lleva"
nombreRelacionProlog Imparte = "imparte"

-- Comprueba si dos entidades representan
-- la misma declaracion logica.
mismaEntidad :: Entidad -> Entidad -> Bool
mismaEntidad a b =
    tipoEntidad a == tipoEntidad b &&
    nombreEntidad a == nombreEntidad b

-- Comprueba si dos relaciones son equivalentes.
mismaRelacion :: Relacion -> Relacion -> Bool
mismaRelacion a b =
    tipoRelacion a == tipoRelacion b &&
    argumentos a == argumentos b

-- Genera un hecho Prolog para una entidad.
generarEntidad :: Entidad -> String
generarEntidad entidad =
    unlines
        [ "% linea " ++ show (lineaEntidad entidad) ++
          ": entidad " ++ nombreEntidadProlog (tipoEntidad entidad)
        , nombreEntidadProlog (tipoEntidad entidad) ++
          "(" ++ atomoProlog (nombreEntidad entidad) ++ ")."
        , ""
        ]

-- Genera un hecho Prolog para una relacion.
generarRelacion :: Relacion -> String
generarRelacion relacion =
    case argumentos relacion of
        [primero, segundo] ->
            unlines
                [ "% linea " ++ show (lineaRelacion relacion) ++
                  ": relacion " ++
                  nombreRelacionProlog (tipoRelacion relacion)
                , nombreRelacionProlog (tipoRelacion relacion) ++
                  "(" ++ atomoProlog primero ++
                  ", " ++ atomoProlog segundo ++ ")."
                , ""
                ]

        _ -> ""

-- Genera una regla Prolog segun la solicitud.
generarRegla :: ReglaSolicitada -> String
generarRegla Companeros =
    unlines
        [ "% Dos estudiantes distintos llevan el mismo curso."
        , "companero(X, Y) :-"
        , "    lleva(X, Curso),"
        , "    lleva(Y, Curso),"
        , "    X \\= Y."
        , ""
        ]

generarRegla CursoConDocente =
    unlines
        [ "% Relacion entre un curso y su docente."
        , "curso_con_docente(Curso, Docente) :-"
        , "    imparte(Docente, Curso)."
        , ""
        ]

generarRegla ComparteDocente =
    unlines
        [ "% Dos estudiantes tienen al menos un docente comun."
        , "comparte_docente(X, Y) :-"
        , "    lleva(X, Curso1),"
        , "    lleva(Y, Curso2),"
        , "    imparte(Docente, Curso1),"
        , "    imparte(Docente, Curso2),"
        , "    X \\= Y."
        , ""
        ]

-- Construye el contenido completo de conocimiento.pl.
-- Recibe un problema previamente validado.
generarConocimiento :: Problema -> String
generarConocimiento problema =
    let
        entidadesUnicas =
            nubBy mismaEntidad (entidades problema)

        relacionesUnicas =
            nubBy mismaRelacion (relaciones problema)

        reglasUnicas =
            nub (reglasSolicitadas problema)

        encabezado =
            unlines
                [ "% ========================================"
                , "% PROYECTO III - PARADIGMAS"
                , "% BASE DE CONOCIMIENTO GENERADA"
                , "% Dominio: Academico"
                , "% ========================================"
                , ""
                , "% Permite consultar predicados aun sin hechos declarados."
                , ":- dynamic estudiante/1, curso/1, docente/1, lleva/2, imparte/2."
                , ""
                ]

        hechosEntidades =
            concatMap generarEntidad entidadesUnicas

        hechosRelaciones =
            concatMap generarRelacion relacionesUnicas

        reglas =
            concatMap generarRegla reglasUnicas

    in
        encabezado ++
        "% ENTIDADES\n\n" ++
        hechosEntidades ++
        "% RELACIONES\n\n" ++
        hechosRelaciones ++
        "% REGLAS\n\n" ++
        reglas

-- Genera consultas sugeridas segun las reglas.
consultaRegla :: ReglaSolicitada -> String
consultaRegla Companeros =
    "% ?- companero(X, Y).\n"

consultaRegla CursoConDocente =
    "% ?- curso_con_docente(Curso, Docente).\n"

consultaRegla ComparteDocente =
    "% ?- comparte_docente(X, Y).\n"

-- Construye el contenido de consultas.pl.
generarConsultas :: Problema -> String
generarConsultas problema =
    let
        reglasUnicas =
            nub (reglasSolicitadas problema)

        encabezado =
            unlines
                [ "% CONSULTAS SUGERIDAS"
                , "% Proyecto III - Paradigmas"
                , ""
                , ":- ensure_loaded('conocimiento.pl')."
                , ""
                , "% Consultas generales:"
                , "% ?- estudiante(X)."
                , "% ?- curso(X)."
                , "% ?- docente(X)."
                , "% ?- lleva(Estudiante, Curso)."
                , "% ?- imparte(Docente, Curso)."
                , ""
                , "% Consultas de reglas solicitadas:"
                ]
    in
        encabezado ++
        concatMap consultaRegla reglasUnicas

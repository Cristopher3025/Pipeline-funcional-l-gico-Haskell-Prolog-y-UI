
module Main where

import Parser
import Validation
import PrologGenerator
import HtmlGenerator

import System.Directory
    ( createDirectoryIfMissing
    , doesFileExist
    , removeFile
    )

import System.Environment (getArgs)
import System.Exit (exitFailure)
import Control.Exception (IOException, try)
import Control.Monad (when)
import System.IO (IOMode(WriteMode), hPutStr, hSetEncoding, utf8, withFile)

-- Ubicaciones de los archivos generados.
rutaConocimiento :: FilePath
rutaConocimiento = "data/output/conocimiento.pl"

rutaConsultas :: FilePath
rutaConsultas = "data/output/consultas.pl"

rutaReporte :: FilePath
rutaReporte = "data/output/reporte_validacion.txt"

rutaHtml :: FilePath
rutaHtml = "web/index.html"

-- Escribe las salidas en UTF-8 independientemente de la consola de Windows.
-- Evita errores al generar HTML y Prolog con caracteres Unicode.
escribirUtf8 :: FilePath -> String -> IO ()
escribirUtf8 ruta contenido =
    withFile ruta WriteMode $ \archivo -> do
        hSetEncoding archivo utf8
        hPutStr archivo contenido

-- Prepara las carpetas de salida.
prepararDirectorios :: IO ()
prepararDirectorios = do
    createDirectoryIfMissing True "data/output"
    createDirectoryIfMissing True "web"

-- Elimina solamente los productos generados.
-- Evita conservar salidas antiguas tras una ejecucion fallida.
limpiarSalidas :: IO ()
limpiarSalidas = do
    mapM_ eliminarSiExiste
        [ rutaConocimiento
        , rutaConsultas
        , rutaHtml
        ]
  where
    eliminarSiExiste ruta = do
        existe <- doesFileExist ruta
        when existe (removeFile ruta)

-- Guarda los errores de interpretacion.
reportarErroresParser :: [String] -> IO ()
reportarErroresParser errores = do
    limpiarSalidas

    let reporte = unlines $
            [ "REPORTE DE VALIDACION"
            , "====================="
            , ""
            , "Errores de interpretacion:"
            ] ++ errores

    escribirUtf8 rutaReporte reporte

    putStrLn reporte
    putStrLn "Pipeline detenido: entrada invalida."
    exitFailure

-- Genera los archivos a partir del modelo validado.
procesarProblema :: String -> IO ()
procesarProblema contenido =
    case parsearProblema contenido of

        Left errores ->
            reportarErroresParser errores

        Right problema -> do
            let incidencias = validarProblema problema

            escribirUtf8 rutaReporte
                (generarReporte incidencias)

            if tieneErrores incidencias
            then do
                limpiarSalidas

                putStrLn "Se encontraron errores semanticos."
                putStrLn (generarReporte incidencias)
                putStrLn "Pipeline detenido."
                exitFailure

            else do
                escribirUtf8 rutaConocimiento
                    (generarConocimiento problema)

                escribirUtf8 rutaConsultas
                    (generarConsultas problema)

                escribirUtf8 rutaHtml
                    (generarHtml problema incidencias)

                putStrLn "[OK] conocimiento.pl generado."
                putStrLn "[OK] consultas.pl generado."
                putStrLn "[OK] index.html generado."
                putStrLn "[OK] reporte_validacion.txt generado."
                putStrLn ""
                putStrLn "Pipeline completado correctamente."

-- Punto de entrada del programa.
main :: IO ()
main = do
    putStrLn "========================================"
    putStrLn "   PROYECTO III - PARADIGMAS"
    putStrLn "   Pipeline Haskell + Prolog + UI"
    putStrLn "========================================"
    putStrLn ""

    argumentos <- getArgs

    let rutaEntrada =
            case argumentos of
                [] -> "data/input/problema.txt"
                [ruta] -> ruta
                _ -> ""

    if null rutaEntrada
    then do
        putStrLn "Uso: programa [ruta_problema.txt]"
        exitFailure
    else do
        prepararDirectorios

        putStrLn ("[1/4] Leyendo: " ++ rutaEntrada)

        resultado <- try (readFile rutaEntrada >>= \texto ->
            length texto `seq` return texto)
            :: IO (Either IOException String)

        case resultado of
            Left errorLectura -> do
                limpiarSalidas
                escribirUtf8 rutaReporte
                    ("Error leyendo el archivo: " ++
                     show errorLectura ++ "\n")

                putStrLn "No se pudo leer el archivo de entrada."
                exitFailure

            Right contenido -> do
                putStrLn "[2/4] Interpretando y validando..."
                putStrLn "[3/4] Generando productos..."
                procesarProblema contenido
                putStrLn "[4/4] Proceso finalizado."

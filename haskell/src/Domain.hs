
module Domain where

-- Tipos de entidades permitidas en el dominio academico.
data TipoEntidad
    = Estudiante
    | Curso
    | Docente
    deriving (Eq, Show)

-- Representa una entidad identificada en problema.txt.
data Entidad = Entidad
    { tipoEntidad :: TipoEntidad
    , nombreEntidad :: String
    , lineaEntidad :: Int
    } deriving (Eq, Show)

-- Relaciones admitidas por el dominio academico.
data TipoRelacion
    = Lleva
    | Imparte
    deriving (Eq, Show)

-- Representa una relacion del archivo de entrada.
data Relacion = Relacion
    { tipoRelacion :: TipoRelacion
    , argumentos :: [String]
    , lineaRelacion :: Int
    } deriving (Eq, Show)

-- Reglas logicas que puede solicitar el usuario.
data ReglaSolicitada
    = Companeros
    | CursoConDocente
    | ComparteDocente
    deriving (Eq, Show)

-- Modelo intermedio del problema completo.
data Problema = Problema
    { entidades :: [Entidad]
    , relaciones :: [Relacion]
    , reglasSolicitadas :: [ReglaSolicitada]
    } deriving (Eq, Show)

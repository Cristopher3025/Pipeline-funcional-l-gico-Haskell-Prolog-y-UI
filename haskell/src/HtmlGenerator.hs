
module HtmlGenerator
    ( generarHtml
    ) where

import Domain
import Validation
import PrologGenerator
import Data.List (nub, nubBy)

-- Escapa caracteres especiales antes de colocarlos
-- dentro de elementos HTML.
escaparHtml :: String -> String
escaparHtml = concatMap escapar
  where
    escapar '&'  = "&amp;"
    escapar '<'  = "&lt;"
    escapar '>'  = "&gt;"
    escapar '"'  = "&quot;"
    escapar '\'' = "&#39;"
    escapar c    = [c]

-- Obtiene el nombre visible de una entidad.
nombreTipo :: TipoEntidad -> String
nombreTipo Estudiante = "Estudiante"
nombreTipo Curso = "Curso"
nombreTipo Docente = "Docente"

nombreRelacion :: TipoRelacion -> String
nombreRelacion Lleva = "Lleva"
nombreRelacion Imparte = "Imparte"

-- Elimina entidades logicas repetidas.
entidadesUnicas :: Problema -> [Entidad]
entidadesUnicas problema =
    nubBy iguales (entidades problema)
  where
    iguales a b =
        tipoEntidad a == tipoEntidad b &&
        nombreEntidad a == nombreEntidad b

-- Elimina relaciones logicas repetidas.
relacionesUnicas :: Problema -> [Relacion]
relacionesUnicas problema =
    nubBy iguales (relaciones problema)
  where
    iguales a b =
        tipoRelacion a == tipoRelacion b &&
        argumentos a == argumentos b

-- Cuenta entidades de un tipo determinado.
contar :: TipoEntidad -> [Entidad] -> Int
contar tipo lista =
    length (filter ((== tipo) . tipoEntidad) lista)

-- Genera una tarjeta de estadisticas.
tarjeta :: String -> Int -> String -> String
tarjeta titulo cantidad icono =
    concat
        [ "<article class='stat-card'>"
        , "<div class='stat-top'><img class='stat-icon' src='assets/icons/", icono
        , ".png' alt='' aria-hidden='true' loading='lazy'>"
        , "<span class='stat-index'>Dato verificado</span></div>"
        , "<span class='stat-value'>", show cantidad, "</span>"
        , "<span class='stat-label'>", escaparHtml titulo, "</span>"
        , "<span class='stat-foot'>Modelo intermedio</span>"
        , "</article>"
        ]

-- Genera una fila de entidad.
filaEntidad :: Entidad -> String
filaEntidad entidad =
    concat
        [ "<tr><td>"
        , escaparHtml (nombreEntidad entidad)
        , "</td><td><span class='tag'>"
        , escaparHtml (nombreTipo (tipoEntidad entidad))
        , "</span></td><td>"
        , show (lineaEntidad entidad)
        , "</td></tr>"
        ]

-- Genera una fila de relacion.
filaRelacion :: Relacion -> String
filaRelacion relacion =
    case argumentos relacion of
        [origen, destino] ->
            concat
                [ "<tr><td>"
                , escaparHtml origen
                , "</td><td><span class='tag blue'>"
                , escaparHtml (nombreRelacion (tipoRelacion relacion))
                , "</span></td><td>"
                , escaparHtml destino
                , "</td><td>"
                , show (lineaRelacion relacion)
                , "</td></tr>"
                ]
        _ -> ""

-- Tabla completa de entidades.
seccionEntidades :: Problema -> String
seccionEntidades problema =
    concat
        [ "<section class='panel' id='entidades'>"
        , "<div class='panel-heading'><h2><img class='panel-icon' src='assets/icons/entidades.png' alt=''>Entidades</h2>"
        , "<span class='pill'>Modelo intermedio</span></div>"
        , "<div class='table-wrap'><table>"
        , "<thead><tr><th>Nombre</th><th>Tipo</th>"
        , "<th>Linea</th></tr></thead><tbody>"
        , concatMap filaEntidad (entidadesUnicas problema)
        , "</tbody></table></div></section>"
        ]

-- Tabla completa de relaciones.
seccionRelaciones :: Problema -> String
seccionRelaciones problema =
    concat
        [ "<section class='panel' id='relaciones'>"
        , "<div class='panel-heading'><h2><img class='panel-icon' src='assets/icons/relaciones.png' alt=''>Relaciones</h2>"
        , "<span class='pill'>Hechos detectados</span></div>"
        , "<div class='table-wrap'><table>"
        , "<thead><tr><th>Origen</th><th>Relacion</th>"
        , "<th>Destino</th><th>Linea</th></tr></thead><tbody>"
        , concatMap filaRelacion (relacionesUnicas problema)
        , "</tbody></table></div></section>"
        ]

-- Seccion que muestra un bloque de codigo.
seccionCodigo :: String -> String -> String -> String
seccionCodigo identificador titulo contenido =
    concat
        [ "<section class='panel' id='", identificador, "'>"
        , "<div class='panel-heading'><h2><img class='panel-icon' src='assets/icons/"
        , if identificador == "conocimiento" then "hechos.png' alt=''>" else "reglas.png' alt=''>"
        , escaparHtml titulo
        , "</h2><span class='pill'>Generado automaticamente</span></div>"
        , "<pre><code>"
        , escaparHtml contenido
        , "</code></pre></section>"
        ]

-- Muestra errores y advertencias.
seccionValidacion :: [Incidencia] -> String
seccionValidacion incidencias =
    let
        clase =
            if tieneErrores incidencias
            then "error"
            else "success"
    in
        concat
            [ "<section class='panel' id='validacion'>"
            , "<div class='panel-heading'><h2>Validacion</h2>"
            , "<span class='pill ", clase, "'>Reporte</span></div>"
            , "<pre class='report'>"
            , escaparHtml (generarReporte incidencias)
            , "</pre></section>"
            ]

-- Estilos CSS de la interfaz.
estilos :: String
estilos = unlines
    [ ":root{color-scheme:dark;--bg:#07111f;--sidebar:#0a1829;"
    , "--surface:#101f32;--surface2:#14283f;--line:#28405a;"
    , "--muted:#9bb1c9;--text:#f3f7ff;--blue:#70baff;--gold:#f7c975;}"
    , "*{box-sizing:border-box;}html{scroll-behavior:smooth;}"
    , "body{margin:0;background:var(--bg);color:var(--text);"
    , "font:15px/1.6 'Segoe UI',system-ui,-apple-system,sans-serif;}"
    , "body:before{content:'';position:fixed;inset:0;pointer-events:none;"
    , "background:radial-gradient(ellipse at 72% -18%,#153b62 0%,transparent 49%);"
    , "opacity:.6;z-index:-1;}a{color:inherit;text-decoration:none;}"
    , "a:focus-visible,input:focus-visible{outline:2px solid var(--gold);outline-offset:4px;}"
    , ".skip-link{position:absolute;top:-80px;left:20px;z-index:12;"
    , "background:var(--gold);color:#061527;padding:9px 15px;border-radius:8px;}"
    , ".skip-link:focus{top:12px;}"
    , ".layout{display:flex;min-height:100vh;}"
    , ".sidebar{width:260px;flex-shrink:0;background:rgba(10,24,41,.96);"
    , "border-right:1px solid #213c56;padding:34px 20px 26px;"
    , "position:sticky;top:0;height:100vh;display:flex;flex-direction:column;}"
    , ".brand-row{display:flex;align-items:center;gap:12px;margin-bottom:10px;}"
    , ".brand-mark{display:grid;place-items:center;width:46px;height:46px;"
    , "border-radius:14px;background:linear-gradient(135deg,#266bb9,#123457);"
    , "color:#fff;font-size:24px;border:1px solid #4d95d0;"
    , "box-shadow:0 8px 30px #0a5a9b33;}"
    , ".brand{font-weight:800;letter-spacing:-.4px;font-size:19px;line-height:1.15;}"
    , ".brand small{display:block;font-size:10px;letter-spacing:2.1px;"
    , "font-weight:700;color:var(--gold);margin-top:4px;}"
    , ".subtitle{font-size:12px;color:var(--muted);margin:3px 0 32px 58px;}"
    , ".nav-label{font-size:10px;font-weight:800;letter-spacing:2px;"
    , "color:#7290ad;margin:0 12px 12px;text-transform:uppercase;}"
    , ".nav a{display:flex;align-items:center;gap:12px;padding:12px 14px;"
    , "border-radius:12px;color:#acc1d8;margin:4px 0;transition:.22s ease;"
    , "border:1px solid transparent;font-size:13px;font-weight:600;}"
    , ".nav a .nav-icon{font-size:18px;width:22px;text-align:center;}"
    , ".nav a:hover,.nav a.active{background:#18324f;color:#fff;"
    , "border-color:#2b5275;transform:translateX(3px);}"
    , ".nav a.active:before{content:'';width:3px;height:19px;"
    , "background:var(--gold);border-radius:9px;margin-left:-9px;}"
    , ".sidebar-bottom{margin-top:auto;border:1px solid #2a4861;"
    , "border-radius:15px;padding:16px;background:linear-gradient(135deg,#132e48,#0d2237);}"
    , ".sidebar-bottom strong{display:block;color:#e7f3ff;font-size:13px;}"
    , ".sidebar-bottom span{display:block;color:#8eabc7;font-size:11px;margin-top:4px;}"
    , ".main{flex:1;min-width:0;max-width:1640px;padding:34px clamp(20px,4vw,64px) 24px;"
    , "margin:0 auto;width:100%;}"
    , ".topbar{display:flex;justify-content:space-between;align-items:center;"
    , "gap:12px;margin-bottom:28px;color:#93aec7;font-size:12px;}"
    , ".breadcrumb{letter-spacing:.5px;}.breadcrumb b{color:#e6f1ff;}"
    , ".live{display:inline-flex;align-items:center;gap:9px;border:1px solid #315b6f;"
    , "border-radius:999px;background:#123943;padding:7px 13px;color:#a7f4d1;font-weight:700;}"
    , ".live:before{content:'';width:7px;height:7px;border-radius:50%;"
    , "background:#50ecac;box-shadow:0 0 0 4px #50ecac22;}"
    , ".hero{position:relative;overflow:hidden;isolation:isolate;"
    , "background:linear-gradient(110deg,#123d68 0%,#153d63 52%,#102b4b 100%);"
    , "border:1px solid #3d678f;border-radius:24px;padding:clamp(25px,4vw,47px);"
    , "box-shadow:0 24px 65px #0004;margin-bottom:26px;min-height:268px;"
    , "display:flex;align-items:center;}"
    , ".hero:before{content:'';position:absolute;inset:0;z-index:-1;"
    , "background:linear-gradient(90deg,transparent 65%,#427cb322),"
    , "radial-gradient(circle at 85% 42%,#448ec655,transparent 34%);}"
    , ".hero-copy{max-width:690px;position:relative;z-index:2;}"
    , ".eyebrow{display:inline-flex;align-items:center;gap:7px;"
    , "text-transform:uppercase;font-size:11px;font-weight:800;letter-spacing:2px;"
    , "color:#ffdd92;margin-bottom:13px;}"
    , ".eyebrow:before{content:'';width:25px;height:2px;background:var(--gold);}"
    , "h1{font-size:clamp(29px,4vw,49px);line-height:1.12;letter-spacing:-1.8px;"
    , "margin:0 0 15px;font-weight:800;max-width:700px;}"
    , ".intro{color:#c8ddf0;max-width:560px;margin:0 0 20px;font-size:14px;}"
    , ".hero-chip{display:inline-block;border:1px solid #ffffff42;"
    , "border-radius:999px;padding:7px 12px;color:#e5f3ff;font-size:11px;"
    , "background:#ffffff14;font-weight:700;letter-spacing:.2px;}"
    , ".hero-art{position:absolute;right:7%;top:50%;transform:translateY(-50%);"
    , "width:220px;height:220px;border-radius:50%;display:grid;place-items:center;"
    , "font-size:100px;color:#f9da9c;background:radial-gradient(circle,#ffffff25,#ffffff06 64%,transparent 65%);"
    , "border:1px solid #ffffff30;box-shadow:0 0 0 20px #ffffff08,0 0 0 50px #ffffff05;}"
    , ".section-caption{display:flex;justify-content:space-between;align-items:center;"
    , "margin:5px 0 15px;gap:12px;}"
    , ".section-caption h2{font-size:19px;margin:0;font-weight:750;}"
    , ".section-caption span{font-size:12px;color:var(--muted);}"
    , ".stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));"
    , "gap:16px;margin-bottom:34px;}"
    , ".stat-card{background:linear-gradient(145deg,#152c45,#102136);"
    , "border:1px solid #2a4865;border-radius:19px;padding:21px 23px;"
    , "display:flex;flex-direction:column;position:relative;overflow:hidden;"
    , "box-shadow:0 13px 33px #0002;transition:transform .25s,border-color .25s,box-shadow .25s;}"
    , ".stat-card:hover{transform:translateY(-6px);border-color:#4b87bb;"
    , "box-shadow:0 22px 42px #0005;}"
    , ".stat-card:after{content:'';position:absolute;right:-33px;bottom:-60px;"
    , "width:130px;height:130px;border:1px solid #ffffff0d;border-radius:50%;}"
    , ".stat-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:15px;}"
    , ".stat-icon{display:grid;place-items:center;width:45px;height:45px;"
    , "border-radius:13px;background:#20476e;color:#b5ddff;font-size:22px;}"
    , ".stat-card:nth-child(2) .stat-icon{background:#3b3530;color:#f8d58b;}"
    , ".stat-card:nth-child(3) .stat-icon{background:#26463f;color:#92ecd0;}"
    , ".stat-card:nth-child(4) .stat-icon{background:#3c3154;color:#c7b0ff;}"
    , ".stat-spark{color:#658eaf;font-size:18px;}"
    , ".stat-value{font-size:39px;line-height:1.05;font-weight:800;letter-spacing:-1.6px;}"
    , ".stat-label{color:#e1ebf8;font-size:14px;margin-top:7px;font-weight:700;}"
    , ".stat-foot{color:#839cb4;font-size:11px;margin-top:8px;}"
    , ".panel{background:linear-gradient(160deg,#12243a,#0f1e30);"
    , "border:1px solid #2a4058;border-radius:20px;padding:26px;"
    , "margin-bottom:23px;box-shadow:0 12px 32px #0002;scroll-margin-top:22px;}"
    , ".panel-heading{display:flex;justify-content:space-between;align-items:center;"
    , "gap:12px;margin-bottom:20px;}h2{font-size:19px;margin:0;font-weight:750;}"
    , ".pill,.tag{display:inline-flex;align-items:center;border-radius:999px;"
    , "padding:5px 11px;background:#223c57;color:#bbd9f4;font-size:11px;font-weight:700;}"
    , ".pill{border:1px solid #365675;}.tag.blue{background:#1c4968;color:#8dd3ff;}"
    , ".pill.success{color:#a1efcd;background:#174238;border-color:#327662;}"
    , ".pill.error{color:#ffc1c1;background:#502d35;border-color:#87505a;}"
    , ".table-wrap{overflow-x:auto;border:1px solid #294057;border-radius:14px;}"
    , "table{width:100%;border-collapse:collapse;text-align:left;}"
    , "th{font-size:10px;letter-spacing:1.3px;text-transform:uppercase;"
    , "background:#1a3149;color:#91b5d9;font-weight:800;}"
    , "th,td{padding:14px 18px;border-bottom:1px solid #253b52;}"
    , "tbody tr:last-child td{border-bottom:0;}"
    , "tbody tr{transition:background .18s;}tbody tr:hover{background:#21405b88;}"
    , "td{font-size:13px;color:#e1efff;}td:first-child{font-weight:650;}"
    , "pre{background:#071525;border:1px solid #29435d;border-radius:14px;"
    , "color:#b7e4ff;padding:23px;overflow-x:auto;font:12px/1.8 Consolas,monospace;"
    , "max-height:540px;tab-size:4;}"
    , ".report{white-space:pre-wrap;color:#c8dfed;}"
    , "footer{margin-top:35px;padding:20px 0 10px;border-top:1px solid #274058;"
    , "display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;"
    , "color:#7d9bb8;font-size:11px;}footer strong{color:#b6d2e9;}"
    , ".reveal{animation:rise .65s both;}"
    , "@keyframes rise{from{opacity:0;transform:translateY(14px);}"
    , "to{opacity:1;transform:translateY(0);}}"
    , "@media(max-width:1200px){.hero-art{right:3%;opacity:.35;}"
    , ".hero-copy{max-width:680px;}.sidebar{width:230px;}}"
    , "@media(max-width:900px){.stats{grid-template-columns:repeat(2,minmax(0,1fr));}"
    , ".main{padding:24px;}.hero-art{opacity:.2;}}"
    , "@media(max-width:650px){.layout{display:block;}"
    , ".sidebar{position:relative;width:100%;height:auto;padding:17px 18px;}"
    , ".subtitle,.sidebar-bottom,.nav-label{display:none;}"
    , ".brand-row{margin:0 0 12px;}.nav{display:flex;gap:4px;overflow-x:auto;}"
    , ".nav a{white-space:nowrap;padding:8px 10px;font-size:11px;}"
    , ".nav a:hover,.nav a.active{transform:none;}.nav a.active:before{display:none;}"
    , ".nav a .nav-icon{font-size:15px;width:auto;}"
    , ".main{padding:16px;}.topbar{margin:4px 0 17px;}"
    , ".hero{min-height:260px;padding:25px;}.hero-art{display:none;}"
    , "h1{font-size:31px;}.panel{padding:17px;}.panel-heading{align-items:flex-start;}"
    , ".pill{font-size:10px;}.stats{gap:10px;}.stat-card{padding:16px;}"
    , ".stat-value{font-size:33px;}th,td{padding:12px;}}"
    , "@media(prefers-reduced-motion:reduce){*,*:before,*:after{"
    , "animation:none!important;transition:none!important;scroll-behavior:auto!important;}}"
    ]

-- Resalta la seccion visible en el menu, sin dependencias externas.
comportamiento :: String
comportamiento = unlines
    [ "(function(){"
    , "var links=[].slice.call(document.querySelectorAll('.nav a'));"
    , "if(!('IntersectionObserver' in window))return;"
    , "var observer=new IntersectionObserver(function(entries){"
    , "entries.forEach(function(entry){if(!entry.isIntersecting)return;"
    , "links.forEach(function(a){var current=a.getAttribute('href')==='#'+entry.target.id;"
    , "a.classList.toggle('active',current);"
    , "if(current)a.setAttribute('aria-current','location');"
    , "else a.removeAttribute('aria-current');});});"
    , "},{rootMargin:'-12% 0px -70% 0px',threshold:0});"
    , "document.querySelectorAll('main[id],section[id]').forEach(function(s){observer.observe(s);});"
    , "})();"
    ]

-- Construye la pagina HTML completa.
generarHtml :: Problema -> [Incidencia] -> String
generarHtml problema incidencias =
    let
        listaEntidades = entidadesUnicas problema
        listaRelaciones = relacionesUnicas problema

        conocimiento = generarConocimiento problema
        consultas = generarConsultas problema

        estadisticas =
            concat
                [ "<div class='stats'>"
                , tarjeta "Estudiantes"
                    (contar Estudiante listaEntidades) "estudiantes"
                , tarjeta "Cursos"
                    (contar Curso listaEntidades) "cursos"
                , tarjeta "Docentes"
                    (contar Docente listaEntidades) "docentes"
                , tarjeta "Relaciones"
                    (length listaRelaciones) "conexiones"
                , "</div>"
                ]

        navegacion =
            concat
                [ "<aside class='sidebar'>"
                , "<div class='brand-row'><span class='brand-mark'"
                , " aria-hidden='true'>AL</span>"
                , "<div class='brand'>Academic Logic"
                , "<small>PROYECTO UNIVERSITARIO</small></div></div>"
                , "<div class='subtitle'>Paradigmas de Programacion</div>"
                , "<div class='nav-label'>MODULOS DEL SISTEMA</div>"
                , "<nav class='nav' aria-label='Secciones principales'>"
                , "<a class='active' href='#resumen'><img class='nav-icon'"
                , " src='assets/icons/resumen.png' alt=''>Resumen</a>"
                , "<a href='#entidades'><img class='nav-icon'"
                , " src='assets/icons/entidades.png' alt=''>Entidades</a>"
                , "<a href='#relaciones'><img class='nav-icon'"
                , " src='assets/icons/relaciones.png' alt=''>Relaciones</a>"
                , "<a href='#conocimiento'><img class='nav-icon'"
                , " src='assets/icons/conocimiento.png' alt=''>Conocimiento</a>"
                , "<a href='#consultas'><img class='nav-icon'"
                , " src='assets/icons/consultas.png' alt=''>Consultas</a>"
                , "<a href='#validacion'><img class='nav-icon'"
                , " src='assets/icons/validacion.png' alt=''>Validacion</a>"
                , "</nav><div class='sidebar-bottom'>"
                , "<strong>Proyecto III / UNA</strong>"
                , "<span>Haskell &middot; SWI-Prolog &middot; HTML</span>"
                , "</div></aside>"
                ]
    in
        concat
            [ "<!DOCTYPE html>\n"
            , "<html lang='es'><head>"
            , "<meta charset='UTF-8'>"
            , "<meta name='viewport' "
            , "content='width=device-width, initial-scale=1'>"
            , "<meta name='theme-color' content='#0a1829'>"
            , "<meta name='description' content='Panel academico generado "
            , "automaticamente con Haskell y SWI-Prolog'>"
            , "<title>Academic Logic | Sistema academico</title>"
            , "<style>", estilos, "</style>"
            , "<link rel='stylesheet' href='assets/una-ui.css'>"
            , "</head><body>"
            , "<a class='skip-link' href='#resumen'>Ir al contenido</a>"
            , "<div class='layout'>"
            , navegacion
            , "<main class='main' id='resumen'>"
            , "<div class='topbar'><div class='breadcrumb'>"
            , "UNIVERSIDAD NACIONAL <span aria-hidden='true'> / </span>"
            , "<b>Proyecto III</b></div>"
            , "<span class='live'>Ejecucion correcta</span></div>"
            , "<header class='hero reveal'><div class='hero-copy'>"
            , "<div class='eyebrow'>PANEL DE CONTROL / CONOCIMIENTO</div>"
            , "<h1>Modelo academico</h1>"
            , "<p class='intro'>Una vista clara de las entidades, relaciones "
            , "y reglas logicas generadas a partir del archivo de entrada.</p>"
            , "<span class='hero-chip'>Datos sincronizados con Haskell</span>"
            , "</div><div class='hero-art' aria-hidden='true'>"
            , "<span>HASKELL</span><i>&rarr;</i><span>PROLOG</span>"
            , "</div></header>"
            , "<div class='section-caption'><h2>Resumen general</h2>"
            , "<span>Indicadores del problema procesado</span></div>"
            , estadisticas
            , seccionEntidades problema
            , seccionRelaciones problema
            , seccionCodigo "conocimiento"
                "Hechos y reglas Prolog" conocimiento
            , seccionCodigo "consultas"
                "Consultas sugeridas" consultas
            , seccionValidacion incidencias
            , "<footer><span><strong>Academic Logic</strong> &middot; "
            , "Proyecto III - Paradigmas de Programacion</span>"
            , "<span>Justin Rojas &middot; Cristopher Ure&#241;a &middot; "
            , "Anthony Villalobos</span></footer>"
            , "</main></div><script>", comportamiento, "</script>"
            , "</body></html>"
            ]

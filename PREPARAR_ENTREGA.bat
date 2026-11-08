@echo off
setlocal
cd /d "%~dp0"

echo ========================================
echo  PROYECTO III - PREPARAR ENTREGA
echo ========================================
echo.

echo [1/3] Verificando compilacion...
ghc -fno-code -ihaskell\src haskell\src\Main.hs
if errorlevel 1 goto :error

echo.
echo [2/3] Regenerando archivos desde data/input/problema.txt...
runghc -ihaskell\src haskell\src\Main.hs
if errorlevel 1 goto :error

echo.
echo [3/3] Actualizando documentacion Doxygen...
doxygen docs\Doxyfile
if errorlevel 1 goto :error

echo.
echo Archivos listos. Puedes abrir:
echo   web\index.html
echo   docs\html\index.html
echo.
pause
exit /b 0

:error
echo.
echo ERROR: Revisa los mensajes anteriores antes de crear el ZIP de entrega.
pause
exit /b 1

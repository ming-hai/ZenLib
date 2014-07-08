@ECHO OFF
REM Script taken from MPC-HC, https://github.com/mpc-hc/mpc-hc


SETLOCAL

PUSHD %~dp0

IF NOT DEFINED COVDIR SET "COVDIR=H:\progs\thirdparty\cov-analysis-win64-7.5.0"
IF DEFINED COVDIR IF NOT EXIST "%COVDIR%" (
  ECHO.
  ECHO ERROR: Coverity not found in "%COVDIR%"
  GOTO End
)


CALL "%VS120COMNTOOLS%..\..\VC\vcvarsall.bat" x86
IF %ERRORLEVEL% NEQ 0 (
  ECHO vcvarsall.bat call failed.
  GOTO End
)


:Cleanup
IF EXIST "cov-int" RD /q /s "cov-int"
IF EXIST "ZenLib.lzma" DEL "ZenLib.lzma"
IF EXIST "ZenLib.tar"  DEL "ZenLib.tar"
IF EXIST "ZenLib.tgz"  DEL "ZenLib.tgz"


:Main
SET MSBUILD_SWITCHES=/nologo /consoleloggerparameters:Verbosity=minimal /maxcpucount^
 /nodeReuse:true /target:ZenLib:Rebuild /property:Configuration="Release";Platform=%1

"%COVDIR%\bin\cov-build.exe" --dir cov-int MSBuild "..\MSVC2013\ZenLib_MSVC.sln" %MSBUILD_SWITCHES%Win32
"%COVDIR%\bin\cov-build.exe" --dir cov-int MSBuild "..\MSVC2013\ZenLib_MSVC.sln" %MSBUILD_SWITCHES%x64


:tar
tar --version 1>&2 2>NUL || (ECHO. & ECHO ERROR: tar not found & GOTO SevenZip)
tar caf "ZenLib.lzma" "cov-int"
GOTO End


:SevenZip
CALL :SubDetectSevenzipPath

rem Coverity is totally bogus with lzma...
rem And since I cannot replicate the arguments with 7-Zip, just use tar/gzip.
IF EXIST "%SEVENZIP%" (
  "%SEVENZIP%" a -ttar "ZenLib.tar" "cov-int"
  "%SEVENZIP%" a -tgzip "ZenLib.tgz" "ZenLib.tar"
  IF EXIST "ZenLib.tar" DEL "ZenLib.tar"
  GOTO End
)


:SubDetectSevenzipPath
FOR %%G IN (7z.exe) DO (SET "SEVENZIP_PATH=%%~$PATH:G")
IF EXIST "%SEVENZIP_PATH%" (SET "SEVENZIP=%SEVENZIP_PATH%" & EXIT /B)

FOR %%G IN (7za.exe) DO (SET "SEVENZIP_PATH=%%~$PATH:G")
IF EXIST "%SEVENZIP_PATH%" (SET "SEVENZIP=%SEVENZIP_PATH%" & EXIT /B)

FOR /F "tokens=2*" %%A IN (
  'REG QUERY "HKLM\SOFTWARE\7-Zip" /v "Path" 2^>NUL ^| FIND "REG_SZ" ^|^|
   REG QUERY "HKLM\SOFTWARE\Wow6432Node\7-Zip" /v "Path" 2^>NUL ^| FIND "REG_SZ"') DO SET "SEVENZIP=%%B\7z.exe"
EXIT /B


:End
POPD
ECHO. & ECHO Press any key to close this window...
PAUSE >NUL
ENDLOCAL
EXIT /B

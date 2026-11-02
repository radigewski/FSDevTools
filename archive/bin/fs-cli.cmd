@echo off
set java_cmd=%JAVA_HOME%\bin\java
set javap_cmd=%JAVA_HOME%\bin\javap
set script_path=%~dp0
set CLI_DIR=%script_path:~0,-4%

REM DETERMINE JAVA CLASS VERSION
for /f "tokens=*" %%a in ('call "%javap_cmd%" -verbose java.lang.Object ^| findstr major') do set BYTECODE_VERSION=%%a
for /f "tokens=3 delims= " %%A in ("%BYTECODE_VERSION%") do set /a BYTECODE_VERSION=%%A
set VM_ARGS=
if %BYTECODE_VERSION% gtr 52  (
  set VM_ARGS=--add-opens=java.base/sun.reflect.annotation=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED
)

REM SELECT FIRSTSPIRIT RUNTIME JAR
REM The api-lib directory may contain one fs-isolated-runtime jar per server version
REM (e.g. fs-isolated-runtime-5.2.260513.jar). The newest one is put on the classpath;
REM on a version mismatch the cli downloads the matching jar and restarts itself with it.
set "FS_CLI_CLASSPATH=%CLI_DIR%\lib\*"
set "API_LIB_JAR="
if exist "%CLI_DIR%\api-lib\" (
  for /f "delims=" %%f in ('dir /b /a-d /on "%CLI_DIR%\api-lib\fs-isolated-runtime-*.jar" 2^>nul') do set "API_LIB_JAR=%CLI_DIR%\api-lib\%%f"
)
if defined API_LIB_JAR set "FS_CLI_CLASSPATH=%FS_CLI_CLASSPATH%;%API_LIB_JAR%"
if defined API_LIB_JAR if exist "%CLI_DIR%\lib\fs-isolated-runtime*.jar" (
  echo WARNING: found fs-isolated-runtime jar in 'lib' AND 'api-lib' - the jar in 'lib' takes precedence. Remove it from 'lib' to use the versioned jars from 'api-lib'. 1>&2
)

REM EXECUTE CLI
call "%java_cmd%" %VM_ARGS% -Xmx512m -Dlog4j.configurationFile="%CLI_DIR%conf/log4j2.xml" -cp "%FS_CLI_CLASSPATH%" com.espirit.moddev.cli.Main %*

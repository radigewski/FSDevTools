#!/bin/sh
JAVACMD="$JAVA_HOME/bin/java";

# Tries to use readlink or realpath. If not installed, falls back to no conversion.
my_realpath() {
    readlink -f "$1" 2>/dev/null || realpath "$1" 2>/dev/null || echo "$1"
}

FS_CLI_DIR="$( cd "$(dirname "$(my_realpath "$0")")/../" ; pwd -P )/"

BYTECODE_VERSION=$("${JAVA_HOME}"/bin/javap -verbose java.lang.Object | grep major | cut -d " " -f5)
if [ "${BYTECODE_VERSION}" -gt 52 ]; then
  VM_ARGS="--add-opens=java.base/sun.reflect.annotation=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED"
fi

# SELECT FIRSTSPIRIT RUNTIME JAR
# The api-lib directory may contain one fs-isolated-runtime jar per server version
# (e.g. fs-isolated-runtime-5.2.260513.jar). The newest one is put on the classpath;
# on a version mismatch the cli downloads the matching jar and restarts itself with it.
FS_CLI_CLASSPATH="${FS_CLI_DIR}lib/*"
API_LIB_JAR=$(ls "${FS_CLI_DIR}api-lib/"fs-isolated-runtime-*.jar 2>/dev/null | sort | tail -n 1)
if [ -n "$API_LIB_JAR" ]; then
  FS_CLI_CLASSPATH="${FS_CLI_CLASSPATH}:${API_LIB_JAR}"
  if ls "${FS_CLI_DIR}lib/"fs-isolated-runtime*.jar >/dev/null 2>&1; then
    echo "WARNING: found fs-isolated-runtime jar in 'lib' AND 'api-lib' - the jar in 'lib' takes precedence. Remove it from 'lib' to use the versioned jars from 'api-lib'." >&2
  fi
fi

$JAVACMD $VM_ARGS -Xmx512m -Dlog4j.configurationFile="${FS_CLI_DIR}conf/log4j2.xml" -cp "$FS_CLI_CLASSPATH" com.espirit.moddev.cli.Main "$@";
RETVAL=$?;
exit ${RETVAL};

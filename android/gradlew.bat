@if "%DEBUG%"=="" @echo off
rem
rem Gradle startup script for Windows
rem

setlocal

rem Find the Java executable
if defined JAVA_HOME (
    set "JAVACMD=%JAVA_HOME%/bin/java.exe"
) else (
    set "JAVACMD=java"
)

if not exist "%JAVACMD%" (
    echo ERROR: JAVA_HOME is not set correctly. 1>&2
    exit /b 1
)

set "APP_HOME=%~dp0"
set "CLASSPATH=%APP_HOME%gradle\wrapper\gradle-wrapper.jar"

"%JAVACMD%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

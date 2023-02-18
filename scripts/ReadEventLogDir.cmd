@ECHO OFF

SET LogDir=%~1
IF "%LogDir%"=="" (SET /P LogDir="Input the event log files directory path: ")

SET PS1_PATH=%~dp0ReadEventLogDir.ps1
@ECHO ON
powershell -ExecutionPolicy Bypass -File "%PS1_PATH%" -LogDir %LogDir%

@ECHO OFF
SET LogDir=
SET PS1_PATH=

@PAUSE

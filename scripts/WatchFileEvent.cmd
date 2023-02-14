@ECHO OFF

SET WatchingDir=%~1
IF "%WatchingDir%"=="" (SET /P WatchingDir="Input the watching directory path: ")

SET FilteredName=%~2
IF "%FilteredName%"=="" (SET /P FilteredName="Input a filtered name: ")

SET PS1_PATH=%~dp0WatchFileEvent.ps1
@ECHO ON
powershell -ExecutionPolicy Bypass -File "%PS1_PATH%" -WatchingDir %WatchingDir% -FilteredName "%FilteredName%"

@ECHO OFF
SET FilteredName=
SET WatchingDir=
SET PS1_PATH=

@PAUSE

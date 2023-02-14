<#
.Synopsis
Watch a directory and write event info on log files.

.Description
Watch a directory and write event info on log files.

.Parameter WatchingDir
The watched folder path.

.Parameter FilteredName
The file name to be watching. e.g.: "*.xls*"

.Parameter FilterdEvents
Event names to be handled. Default is all events `@("Created", "Changed", "Renamed", "Deleted")`.

.Parameter IncludesSubdir
Whether to include subfolders as watched or not. Default is `$False`.

.Parameter LogDir
The foler path to write log files. Default is `%TEMP%\PSWatchFileEvent_{GUID}`.

.Parameter LogFileName
the log file name.

.Parameter LogFileEncoding
Default is "utf-8"

.Parameter DotIntervalSec
The second of displaying processing dot interval.

.Example
PS> Watch-FileEventStream -WatchingDir "C:\notes" -FilteredName "*.xls*"
#>
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

function Watch-FileEventStream {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [ValidateScript({ (Get-Item $_).PSIsContainer })]
        [String] $WatchingDir,

        [Parameter(Position = 1)]
        [String] $FilteredName = "*",

        [Parameter(Position = 2)]
        [String[]] $FilteredEvents = @("Created", "Changed", "Renamed", "Deleted"),

        [Parameter(Position = 3)]
        [Boolean] $IncludesSubdir = $False,

        [Parameter(Position = 4)]
        [String] $LogDir = ($env:TEMP | Join-Path -ChildPath "PSWatchFileEvent_$($([System.Guid]::NewGuid().Guid))"),

        [Parameter(Position = 5)]
        [String] $LogFileName = ((Get-Date -Format "yyyyMMddTHHmmssK").Replace(':', '') + ".txt"),

        [Parameter(Position = 6)]
        [String] $LogFileEncoding = "utf-8",

        [Parameter(Position = 7)]
        [Int16] $DotIntervalSec = 3
    )
    Process {
        # Checking the arguments
        . {
            Write-Host "`$WatchingDir: $($WatchingDir)"
            Write-Host "`$DotIntervalSec: $($DotIntervalSec)"
            Write-Host "`$FilteredName: $($FilteredName)"
            Write-Host "`$FilteredEvents: $($FilteredEvents)"
            Write-Host "`$IncludesSubdir: $($IncludesSubdir)"
            Write-Host "`$LogDir: $($LogDir)"
            Write-Host "`$LogFileName: $($LogFileName)"
            Write-Host "`$LogFileEncoding: $($LogFileEncoding)"
        }

        $global:streamWriter = [LogWriter]::new($LogDir, $LogFileName, $LogFileEncoding)

        # FileSystemWatcher for the watching files
        # https://docs.microsoft.com/ja-jp/dotnet/api/system.io.filesystemwatcher?view=net-5.0
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $WatchingDir
        $watcher.Filter = $FilteredName
        $watcher.IncludeSubdirectories = $IncludesSubdir

        # action to execute after an event triggered
        $registerAction = {
            try {
                Write-Host "!" -NoNewline

                # $currentDate = Get-Date
                # $dt = $currentDate.ToString("yyyyMMddTHHmmssK").Replace(':', '')
                $dt = $Event.TimeGenerated.ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")

                $changeType = $Event.SourceEventArgs.ChangeType
                Write-Host "[info] $($dt) $($changeType) Event" -ForegroundColor Cyan

                $evPath = $Event.SourceEventArgs.FullPath
                Write-Host "[info] filepath: $($evPath)"

                $oldPath = $Event.SourceEventArgs.OldFullPath
                Write-Host "[info] renamed filepath: $($oldPath)"

                $global:streamWriter.WriteLog($dt, $changeType, $oldPath, $evPath)
            }
            catch {
                Write-Host "[error] $($_.Exception.Message)"
            }
        }

        # Add event handler jobs
        $handlers = . {
            if ($FilteredEvents.Contains("Created")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $registerAction -SourceIdentifier FSCreated
            }

            if ($FilteredEvents.Contains("Changed")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $registerAction -SourceIdentifier FSChanged
            }

            if ($FilteredEvents.Contains("Renamed")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $registerAction -SourceIdentifier FSRenamed
            }

            if ($FilteredEvents.Contains("Deleted")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $registerAction -SourceIdentifier FSDeleted
            }
        }

        # Start the watching
        Write-Host "[info] Start watching for changes to `"$($WatchingDir)`""
        $watcher.EnableRaisingEvents = $true

        try {
            do {
                Wait-Event -Timeout $intervalSec
                Write-Host "." -NoNewline
            } while ($true)
        }
        finally {
            Write-Host "[info] Stop watching for changes to `"$WatchingDir`""

            # This gets executed when user presses CTRL+C
            # Remove the stream writer
            $streamWriter.Close()

            # Remove the event handlers
            if ($FilteredEvents.Contains("Created")) {
                Unregister-Event -SourceIdentifier FSCreated
            }

            if ($FilteredEvents.Contains("Changed")) {
                Unregister-Event -SourceIdentifier FSChanged
            }

            if ($FilteredEvents.Contains("Renamed")) {
                Unregister-Event -SourceIdentifier FSRenamed
            }

            if ($FilteredEvents.Contains("Deleted")) {
                Unregister-Event -SourceIdentifier FSDeleted
            }

            # Remove background jobs
            $handlers | Remove-Job

            # Remove filesystemwatcher
            $FileSystemWatcher.EnableRaisingEvents = $false
            $FileSystemWatcher.Dispose()
        }

        return $streamWriter.logFilePath
    }
}

class LogWriter {
    [string] $logFilePath
    [object] $streamWriter

    LogWriter(
        [string] $logDir,
        [string] $logFilename,
        [string] $encoding = "utf-8"
    ){
        # Creating the folder
        Write-Host "[info] Tha path of log directory is `"$($logDir)`""
        [System.IO.Directory]::CreateDirectory($logDir)

        # Setting the log file path
        $this.logFilePath = Join-Path -Path $logDir -ChildPath $logFilename

        # StreamWriter for the log file
        # https://learn.microsoft.com/en-us/dotnet/api/system.io.streamwriter?view=net-7.0
        $enc = [Text.Encoding]::GetEncoding($encoding)
        $this.streamWriter = New-Object System.IO.StreamWriter($this.logFilePath, $true, $enc)
    }

    WriteLog(
        [string] $dateString,
        [string] $changeType,
        [string] $oldPath,
        [string] $evPath
    ){
        $str = "$($dateString): [$($changeType)] `"$($oldPath)`" > `"$($evPath)`""
        $this.streamWriter.WriteLine($str)
    }

    Close(){
        $this.streamWriter.Close()
    }
}

Export-ModuleMember -Function Watch-FileEventStream
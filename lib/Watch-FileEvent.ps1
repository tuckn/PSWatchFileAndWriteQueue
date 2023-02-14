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
Event names to be handled. The default is all events `@("Created", "Changed", "Renamed", "Deleted")`.

.Parameter IncludesSubdir
If specified this switch to include subfolders as be watched.

.Parameter LogDir
The folder path to writing log files. The default is `%TEMP%\PSWatchFileEvent_{GUID}`.

.Parameter LogFileNamePrefix
A prefix of the log file name. The default is "".

.Parameter LogFileEncoding
The default is "utf8" (UTF8 with BOM).
If your PowerShell is less than 6, when you can only use "unknown, string, unicode, bigendianunicode, utf8, utf7, utf32, ascii, default, oem".

[Out-File (Microsoft.PowerShell.Utility) - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file?view=powershell-7.3#-encoding)

.Parameter DotIntervalSec
The second of displaying processing dot interval.

.Example
PS> Watch-FileEvent -WatchingDir "C:\notes" -FilteredName "*.xls*"
#>
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

function Watch-FileEvent {
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
        [switch] $IncludesSubdir,

        [Parameter(Position = 4)]
        [String] $LogDir = ($env:TEMP | Join-Path -ChildPath "PSWatchFileEvent_$($([System.Guid]::NewGuid().Guid))"),

        [Parameter(Position = 5)]
        [String] $LogFileNamePrefix = "",

        [Parameter(Position = 6)]
        [String] $LogFileEncoding = "utf8",

        [Parameter(Position = 7)]
        [Int16] $DotIntervalSec = 3
    )
    Process {
        # Checking the arguments
        # . {
        #     Write-Host "`$WatchingDir: $($WatchingDir)"
        #     Write-Host "`$FilteredName: $($FilteredName)"
        #     Write-Host "`$FilteredEvents: $($FilteredEvents)"
        #     Write-Host "`$IncludesSubdir: $($IncludesSubdir)"
        #     Write-Host "`$LogDir: $($LogDir)"
        #     Write-Host "`$LogFileNamePrefix: $($LogFileNamePrefix)"
        #     Write-Host "`$LogFileEncoding: $($LogFileEncoding)"
        #     Write-Host "`$DotIntervalSec: $($DotIntervalSec)"
        # }

        # Creating the log folder
        Write-Host "[info] Tha path of log directory is `"$($LogDir)`""
        [System.IO.Directory]::CreateDirectory($LogDir) | Out-Null

        # FileSystemWatcher for the watching files
        # https://docs.microsoft.com/ja-jp/dotnet/api/system.io.filesystemwatcher?view=net-5.0
        [System.IO.FileSystemWatcher] $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $WatchingDir
        $watcher.Filter = $FilteredName
        $watcher.IncludeSubdirectories = $IncludesSubdir

        # NOTE
        # An action passed to `Register-ObjectEvent` has their own local scope. Therefore, all variables defined in the current scope, such as the arguments of this function, are null in the action. Therefore, it is necessary to define the variables used in the action in PSObject and pass it as the argument `-MessageData` of `Register-ObjectEvent`.
        [PSCustomObject] $msgData = New-Object -TypeName PSObject -Property @{
            LogDirPath = $LogDir
            LogFileNamePrefix = $LogFileNamePrefix
            LogFileEncoding = $LogFileEncoding
        }

        # action to execute after an event triggered
        $registerAction = {
            try {
                Write-Host "!"

                # Shorthand
                [String] $logDir = $event.MessageData.LogDirPath
                [String] $qFileNamePrefix = $event.MessageData.LogFileNamePrefix
                [String] $enc = $event.MessageData.LogFileEncoding
                [System.IO.WatcherChangeTypes] $changeType = $event.SourceEventArgs.ChangeType
                [String] $evPath = $event.SourceEventArgs.FullPath
                [String] $oldPath = $event.SourceEventArgs.OldFullPath

                # Setting the log file path
                [String] $dt = $event.TimeGenerated.ToString("yyyyMMddTHHmmss.ffffff")
                [String] $qFileName = "$($qFileNamePrefix)$($dt).txt"
                [String] $qFilePath = Join-Path -Path $logDir -ChildPath $qFileName

                # DATETIME [EVENT_NAME] FILE_PATH < OLD_PATH
                [String] $evLogStr = "$($dt) [$($changeType)] `"$($evPath)`" < `"$($oldPath)`""

                Write-Host "[info] $($evLogStr)"

                $evLogStr | Out-File -LiteralPath $qFilePath -Append -Encoding $enc
            }
            catch {
                Write-Host "[error] $($_.Exception.Message)"
            }
        }

        # Add event handler jobs
        $handlers = . {
            if ($FilteredEvents.Contains("Created")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $registerAction -MessageData $msgData -SourceIdentifier FSCreated
            }

            if ($FilteredEvents.Contains("Changed")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $registerAction -MessageData $msgData -SourceIdentifier FSChanged
            }

            if ($FilteredEvents.Contains("Renamed")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $registerAction -MessageData $msgData -SourceIdentifier FSRenamed
            }

            if ($FilteredEvents.Contains("Deleted")) {
                Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $registerAction -MessageData $msgData -SourceIdentifier FSDeleted
            }
        }

        # Start the watching
        Write-Host "[info] Start watching for changes to `"$($WatchingDir)`""
        $watcher.EnableRaisingEvents = $true

        try {
            do {
                Wait-Event -Timeout $DotIntervalSec
                Write-Host "." -NoNewline
            } while ($true)
        }
        finally {
            Write-Host "[info] Stop watching for changes to `"$WatchingDir`""

            # Remove the event handlers
            . {
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
            }

            # Remove background jobs
            $handlers | Remove-Job

            # Remove filesystemwatcher
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
        }

        return $LogDir
    }
}

Export-ModuleMember -Function Watch-FileEvent
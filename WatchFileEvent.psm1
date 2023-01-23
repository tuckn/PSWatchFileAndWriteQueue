<#
.Synopsis
Watch a directory and write event info on queue files.

.Description
Watch a directory and write event info on queue files.

.Parameter WatchingDir
The watched folder path.

.Parameter FilteredName
The file name to be watching. e.g.: "*.xls*"

.Parameter FilterdEvents
Event names to be handled. Default is all events `@("Created", "Changed", "Renamed", "Deleted")`.

.Parameter IncludesSubdir
Whether to include subfolders as watched or not. Default is `$False`.

.Parameter QueueDir
The foler path to write queue files. Default is `%TEMP%\Queue_{GUID}`.

.Parameter QueueFileNamePrefix
A prefix of the queue file name. Default is "".

.Parameter QueueFileEncoding
Default is "utf8" (UTF8 with BOM).
If your PoweShell less than 6 when you can only use "unknown,string,unicode,bigendianunicode,utf8,utf7,utf32,ascii,default,oem".

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
        [String] $WatchingDir,

        [Parameter(Position = 1)]
        [String] $FilteredName = "*",

        [Parameter(Position = 2)]
        [String[]] $FilteredEvents = @("Created", "Changed", "Renamed", "Deleted"),

        [Parameter(Position = 3)]
        [Boolean] $IncludesSubdir = $False,

        [Parameter(Position = 4)]
        [String] $QueueDir = ($env:TEMP | Join-Path -ChildPath "Queue_$($([System.Guid]::NewGuid().Guid))"),

        [Parameter(Position = 5)]
        [String] $QueueFileNamePrefix = "",

        [Parameter(Position = 6)]
        [String] $QueueFileEncoding = "utf8",

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
        #     Write-Host "`$QueueDir: $($QueueDir)"
        #     Write-Host "`$QueueFileNamePrefix: $($QueueFileNamePrefix)"
        #     Write-Host "`$QueueFileEncoding: $($QueueFileEncoding)"
        #     Write-Host "`$DotIntervalSec: $($DotIntervalSec)"
        # }

        if (-not((Get-Item $WatchingDir).PSIsContainer)) {
            Write-Error "`$WatchingDir is not a folder. $($WatchingDir)"
            exit 1
        }

        # Creating the queue folder
        Write-Host "[info] Tha path of queue directory is `"$($QueueDir)`""
        [System.IO.Directory]::CreateDirectory($QueueDir) | Out-Null

        # FileSystemWatcher for the watching files
        # https://docs.microsoft.com/ja-jp/dotnet/api/system.io.filesystemwatcher?view=net-5.0
        [System.IO.FileSystemWatcher] $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $WatchingDir
        $watcher.Filter = $FilteredName
        $watcher.IncludeSubdirectories = $IncludesSubdir

        # NOTE
        # An action passed to `Register-ObjectEvent` has their own local scope. Therefore, all variables defined in the current scope, such as the arguments of this function, are null in the action. Therefore, it is necessary to define the variables used in the action in PSObject and pass it as the argument `-MessageData` of `Register-ObjectEvent`.
        [PSCustomObject] $msgData = New-Object -TypeName PSObject -Property @{
            QueueDirPath = $QueueDir
            QueueFileNamePrefix = $QueueFileNamePrefix
            QueueFileEncoding = $QueueFileEncoding
        }

        # action to execute after an event triggered
        $registerAction = {
            try {
                Write-Host "!"

                # Shorthand
                [String] $queueDir = $event.MessageData.QueueDirPath
                [String] $qFileNamePrefix = $event.MessageData.QueueFileNamePrefix
                [String] $enc = $event.MessageData.QueueFileEncoding
                [System.IO.WatcherChangeTypes] $changeType = $event.SourceEventArgs.ChangeType
                [String] $evPath = $event.SourceEventArgs.FullPath
                [String] $oldPath = $event.SourceEventArgs.OldFullPath

                # Setting the queue file path
                [String] $dt = $event.TimeGenerated.ToString("yyyyMMddTHHmmss.ffffff")
                [String] $qFileName = "$($qFileNamePrefix)$($dt).txt"
                [String] $qFilePath = Join-Path -Path $queueDir -ChildPath $qFileName

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

        return $QueueDir
    }
}

Export-ModuleMember -Function Watch-FileEvent
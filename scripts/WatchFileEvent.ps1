using module "..\WatchFileEvent.psm1"

Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
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

$ErrorActionPreference = "Continue"
Set-StrictMode -Version 3.0

$params = @{
    WatchingDir = $WatchingDir
    FilteredName = $FilteredName
    FilteredEvents = $FilteredEvents
    IncludesSubdir = $IncludesSubdir
    LogDir = $LogDir
    LogFileNamePrefix = $LogFileNamePrefix
    LogFileEncoding = $LogFileEncoding
    DotIntervalSec = $DotIntervalSec
}

Watch-FileEvent @params
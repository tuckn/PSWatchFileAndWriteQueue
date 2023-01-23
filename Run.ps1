using module ".\WatchFileEvent.psm1"

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

$ErrorActionPreference = "Continue"
Set-StrictMode -Version 3.0

Watch-FileEvent `
    -WatchingDir "$WatchingDir" `
    -FilteredName $FilteredName `
    -FilteredEvents $FilteredEvents `
    -IncludesSubdir $IncludesSubdir `
    -QueueDir $QueueDir `
    -QueueFileNamePrefix $QueueFileNamePrefix `
    -QueueFileEncoding $QueueFileEncoding `
    -DotIntervalSec $DotIntervalSec
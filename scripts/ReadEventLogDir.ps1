using module "..\WatchFileEvent.psm1"

Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [String] $LogDir
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Version 3.0

$params = @{
    LogDir = $LogDir
}

Read-EventLogDir @params
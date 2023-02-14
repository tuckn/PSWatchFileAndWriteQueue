<#
.Synopsis
Read info on Excel files from a directory and update records in a database file.

.Description
Read info on Excel files from a directory and update records in a database file.

The required module is below.
[dfinke/ImportExcel: PowerShell module to import/export Excel spreadsheets, without Excel](https://github.com/dfinke/ImportExcel)

If a Excel file is open when an error will occur. -> Failed retrieving Excel workbook information

.Parameter LogDir
The directory path to writing log files.
#>
using namespace System.Collections.Generic # PowerShell 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

function Read-EventLogDir {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [ValidateScript({ (Get-Item $_).PSIsContainer })]
        [String] $LogDir
    )
    Process {
        # Checking the arguments
        . {
            Write-Host "`$LogDir: $($LogDir)"
        }

        # Read all log files
        $logFiles = Get-ChildItem -Path $LogDir

        $evLogs = [List[PSCustomObject]]::new()

        foreach ($f in $logFiles) {
            foreach ($line in [System.IO.File]::ReadLines($f.FullName)) {
                $line -match "(\d{8}T\d{6}\.\d{6})\s+\[(\w+)\]\s+""([^""]+)""\s+<\s+""([^""]*)""" | Out-Null
                $evLogs.Add([PSCustomObject]@{
                    DateTime = $Matches[1]
                    Event = $Matches[2]
                    FilePath = $Matches[3]
                    FilePathBeforeRename = $Matches[4]
                })
            }
        }

        $evLogs
    }
}

Export-ModuleMember -Function Read-EventLogDir
foreach ($dir in @('lib')) {
    Get-ChildItem -Path "$($PSScriptRoot)\$($dir)\*.ps1" | ForEach-Object { . $_.FullName }
}
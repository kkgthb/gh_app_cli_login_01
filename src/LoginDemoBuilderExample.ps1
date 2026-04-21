$sourceCodeFolderPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, 'modules', 'LoginDemo'))
$buildOutputFolderPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '.ignoreme', 'LoginDemo'))
$current_date = Get-Date -AsUTC
$calver = [String][Version]::New(
    $null, `
        $null, `
        $current_date.ToString('yyyyMMdd'), `
        '9' + $current_date.ToString('hhmmssff')
)

$buildParams = @{
    SourcePath               = $sourceCodeFolderPath 
    OutputDirectory          = $buildOutputFolderPath 
    VersionedOutputDirectory = $true
    Version                  = $calver
}

Build-Module @buildParams

function ConvertTo-Base64Url {
    param([byte[]] $Bytes)
    [Convert]::ToBase64String($Bytes) -replace '\+', '-' -replace '/', '_' -replace '=', ''
}
function New-GitHubAppJwt {
    param(
        [Parameter(Mandatory)] [string] $AppId,
        [Parameter(Mandatory)] [string] $PrivateKeyPem
    )
    $header       = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes('{"alg":"RS256","typ":"JWT"}'))
    $now          = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $payload      = ConvertTo-Base64Url ([Text.Encoding]::UTF8.GetBytes(
        "{`"iat`":$($now - 60),`"exp`":$($now + 540),`"iss`":`"$AppId`"}"
    ))
    $signingInput = "$header.$payload"

    $rsa = [System.Security.Cryptography.RSA]::Create()
    try {
        $rsa.ImportFromPem($PrivateKeyPem)
        $signature = ConvertTo-Base64Url ($rsa.SignData(
            [Text.Encoding]::UTF8.GetBytes($signingInput),
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        ))
    }
    finally {
        $rsa.Dispose()
    }

    return "$signingInput.$signature"
}
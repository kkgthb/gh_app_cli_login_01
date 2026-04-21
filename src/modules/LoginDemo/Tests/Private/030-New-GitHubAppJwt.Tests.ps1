# Module must be loaded at script scope so it exists during Pester's discovery phase,
# which is when InModuleScope is evaluated (before BeforeAll ever runs).
# Dependencies are dot-sourced in the same order ModuleBuilder uses: alphabetical,
# so ConvertTo-Base64Url (020) is defined before New-GitHubAppJwt (030).
Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
$script:base64UrlPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '020-ConvertTo-Base64Url.ps1'))
$script:ephemeralModulePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '030-New-GitHubAppJwt.ps1'))
$m = New-Module -Name 'MyEphemeralModule' -ArgumentList $script:base64UrlPath, $script:ephemeralModulePath -ScriptBlock {
    param($m020Path, $modulePath)
    . $m020Path
    . $modulePath
}
$m | Import-Module -Global -Force

Describe "Testing script internals -- it should create JWTs" {
    InModuleScope 'MyEphemeralModule' {
        BeforeAll {
            function ConvertFrom-Base64Url([string] $Value) {
                $padded = ($Value -replace '-', '+' -replace '_', '/').PadRight(
                    [Math]::Ceiling($Value.Length / 4) * 4, '=')
                [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($padded))
            }
            $rsa = [System.Security.Cryptography.RSA]::Create(2048)
            $script:TestPrivateKeyPem = $rsa.ExportRSAPrivateKeyPem()
            $rsa.Dispose()
        }
        It 'returns a three-part dot-delimited string' {
            $jwt = New-GitHubAppJwt -ClientId 'app123' -PrivateKeyPem $script:TestPrivateKeyPem
            $parts = $jwt -split '\.'
            $parts.Count | Should -Be 3
        }
        It 'uses RS256 in the header' {
            $jwt = New-GitHubAppJwt -ClientId 'app123' -PrivateKeyPem $script:TestPrivateKeyPem
            $header = ConvertFrom-Base64Url (($jwt -split '\.')[0]) | ConvertFrom-Json
            $header.alg | Should -Be 'RS256'
            $header.typ | Should -Be 'JWT'
        }
        It 'sets iss to the provided ClientId' {
            $jwt = New-GitHubAppJwt -ClientId 'my-app-42' -PrivateKeyPem $script:TestPrivateKeyPem
            $payload = ConvertFrom-Base64Url (($jwt -split '\.')[1]) | ConvertFrom-Json
            $payload.iss | Should -Be 'my-app-42'
        }
        It 'produces a 600-second window between iat and exp' {
            # iat = now-60, exp = now+540 → exp-iat is always 600 regardless of clock
            $jwt = New-GitHubAppJwt -ClientId 'app1' -PrivateKeyPem $script:TestPrivateKeyPem
            $payload = ConvertFrom-Base64Url (($jwt -split '\.')[1]) | ConvertFrom-Json
            ($payload.exp - $payload.iat) | Should -Be 600
        }
        It 'produces a non-empty signature segment' {
            $jwt = New-GitHubAppJwt -ClientId 'app1' -PrivateKeyPem $script:TestPrivateKeyPem
            ($jwt -split '\.')[2] | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
}
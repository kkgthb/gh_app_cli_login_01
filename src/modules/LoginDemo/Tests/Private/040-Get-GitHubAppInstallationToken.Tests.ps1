# Module must be loaded at script scope so it exists during Pester's discovery phase,
# which is when InModuleScope is evaluated (before BeforeAll ever runs).
# Dependencies are dot-sourced in the same order ModuleBuilder uses: alphabetical.
Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
$script:base64UrlPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '020-ConvertTo-Base64Url.ps1'))
$script:jwtPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '030-New-GitHubAppJwt.ps1'))
$script:ephemeralModulePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '040-Get-GitHubAppInstallationToken.ps1'))
$m = New-Module -Name 'MyEphemeralModule' -ArgumentList $script:base64UrlPath, $script:jwtPath, $script:ephemeralModulePath -ScriptBlock {
    param($m020Path, $m030Path, $modulePath)
    . $m020Path
    . $m030Path
    . $modulePath
}
$m | Import-Module -Global -Force

Describe "Testing script internals -- it should get tokens" {
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
        
        BeforeEach {
            Mock Invoke-RestMethod { [pscustomobject]@{ token = 'ghs_faketoken123' } } # TODO:  still 401s out when mock commented out
        }

        It 'calls the correct GitHub API endpoint' {
            Get-GitHubAppInstallationToken -AppId 'app1' -ClientId 'client1' -InstallationId '99' -PrivateKeyPem $script:TestPrivateKeyPem
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Uri -eq 'https://api.github.com/app/installations/99/access_tokens'
            }
        }

        It 'sends a POST request' {
            Get-GitHubAppInstallationToken -AppId 'app1' -ClientId 'client1' -InstallationId '99' -PrivateKeyPem $script:TestPrivateKeyPem
            Should -Invoke Invoke-RestMethod -ParameterFilter { $Method -eq 'Post' }
        }

        It 'sends a Bearer JWT in the Authorization header' {
            Get-GitHubAppInstallationToken -AppId 'app1' -ClientId 'client1' -InstallationId '99' -PrivateKeyPem $script:TestPrivateKeyPem
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Headers.Authorization -match '^Bearer .+\..+\..+$'
            }
        }

        It 'sends the correct GitHub API version header' {
            Get-GitHubAppInstallationToken -AppId 'app1' -ClientId 'client1' -InstallationId '99' -PrivateKeyPem $script:TestPrivateKeyPem
            Should -Invoke Invoke-RestMethod -ParameterFilter {
                $Headers['X-GitHub-Api-Version'] -eq '2022-11-28'
            }
        }

        It 'returns the token from the API response' {
            $result = Get-GitHubAppInstallationToken -AppId 'app1' -ClientId 'client1' -InstallationId '99' -PrivateKeyPem $script:TestPrivateKeyPem
            $result | Should -Be 'ghs_faketoken123'
        }

        It 'throws when the API response has no token' {
            Mock Invoke-RestMethod { [pscustomobject]@{ token = $null } }
            {
                Get-GitHubAppInstallationToken -AppId 'app1' -ClientId 'client1' -InstallationId '99' -PrivateKeyPem $script:TestPrivateKeyPem
            } | Should -Throw 'GitHub API did not return an access token.'
        }
    }
}

AfterAll {
    Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
}
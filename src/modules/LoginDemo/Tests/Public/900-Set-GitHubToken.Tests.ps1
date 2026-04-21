# Module must be loaded at script scope so it exists during Pester's discovery phase,
# which is when InModuleScope is evaluated (before BeforeAll ever runs).
# Dependencies are dot-sourced in the same order ModuleBuilder uses: alphabetical.
Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
$script:testEnvPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '010-Test-Envs.ps1'))
$script:base64UrlPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '020-ConvertTo-Base64Url.ps1'))
$script:jwtPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '030-New-GitHubAppJwt.ps1'))
$script:getTokenPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', '040-Get-GitHubAppInstallationToken.ps1'))
$script:ephemeralModulePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Public', '900-Set-GitHubToken.ps1'))
$m = New-Module -Name 'MyEphemeralModule' -ArgumentList $script:testEnvPath, $script:base64UrlPath, $script:jwtPath, $script:getTokenPath, $script:ephemeralModulePath -ScriptBlock {
    param($m010Path, $m020Path, $m030Path, $m040Path, $modulePath)
    . $m010Path
    . $m020Path
    . $m030Path
    . $m040Path
    . $modulePath
}
$m | Import-Module -Global -Force

Describe "Testing script internals -- it should write host as expected" {
    InModuleScope 'MyEphemeralModule' {
        BeforeAll {
            # Snapshot any real env vars so we can restore them after this Describe block
            $script:OriginalTfBuild = $env:TF_BUILD
        }

        AfterAll {
            $env:TF_BUILD = $script:OriginalTfBuild
        }

        BeforeEach {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_pem', [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_pem', 'User'), 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_id', 'User'), 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_installation_id', 'User'), 'Process')
            Mock Invoke-RestMethod { [pscustomobject]@{ token = 'ghs_faketoken123' } } # Note:  TODO ... when I commented this mock out, Invoke-RestMethod got a 401 unauthorized error.  Bummer.
            Mock Write-Host {}
            Remove-Item Env:\TF_BUILD -ErrorAction 'Ignore'
        }

        Context 'when running in Azure Pipelines (TF_BUILD=True)' {
            BeforeEach { $env:TF_BUILD = 'True' }

            It 'emits a ##vso setvariable command for GITHUB_TOKEN' {
                Set-GitHubToken
                Should -Invoke Write-Host -ParameterFilter {
                    $Object -match '##vso\[task\.setvariable variable=GITHUB_TOKEN;issecret=true\]'
                }
            }

            It 'includes the token value in the ##vso command' {
                Set-GitHubToken
                Should -Invoke Write-Host -ParameterFilter { $Object -like '*ghs_faketoken123' }
            }

            It 'does not return a value (token stays inside the ADO command)' {
                $result = Set-GitHubToken
                $result | Should -BeNullOrEmpty
            }
        }

        Context 'when running locally (TF_BUILD not set)' {
            AfterEach { Remove-Item Env:\GITHUB_TOKEN -ErrorAction Ignore }

            It 'does not emit a ##vso command' {
                Set-GitHubToken
                Should -Invoke Write-Host -ParameterFilter { $Object -notmatch '##vso' }
            }

            It 'sets $env:GITHUB_TOKEN in the current process' {
                Set-GitHubToken
                $env:GITHUB_TOKEN | Should -Be 'ghs_faketoken123'
            }

            It 'does not write the token value to stdout' {
                Set-GitHubToken
                Should -Invoke Write-Host -ParameterFilter { $Object -notmatch 'ghs_faketoken123' }
            }

            It 'does not return a value' {
                $result = Set-GitHubToken
                $result | Should -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
    Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
}
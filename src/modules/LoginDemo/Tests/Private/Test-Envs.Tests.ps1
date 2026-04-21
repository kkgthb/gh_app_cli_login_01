# Module must be loaded at script scope so it exists during Pester's discovery phase,
# which is when InModuleScope is evaluated (before BeforeAll ever runs).
Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
$script:ephemeralModulePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', 'Test-Envs.ps1'))
Write-Host($script:ephemeralModulePath)
$m = New-Module -Name 'MyEphemeralModule' -ArgumentList $script:ephemeralModulePath -ScriptBlock {
    param($modulePath)
    . $modulePath
}
$m | Import-Module -Global -Force

Describe "Testing script internals -- it should validate environment variables" {
    InModuleScope 'MyEphemeralModule' {
        It "validates proper variables set" {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_org_name', 'HelloWorldOrg', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', '12345', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', '54321', 'Process')
            { Test-Envs } | Should -Not -Throw
        }
        It "catches missing org name" {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_org_name', $null, 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', '12345', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', '54321', 'Process')
            { Test-Envs } | Should -Throw 'Required environment variable DEMOS_my_gh_org_name is not set.'
        }
        It "catches missing app ID" {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_org_name', 'HelloWorldOrg', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', $null, 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', '54321', 'Process')
            { Test-Envs } | Should -Throw 'Required environment variable DEMOS_my_gh_app_id is not set.'
        }
        It "catches non-numeric app ID" {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_org_name', 'HelloWorldOrg', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', 'NonNumericAppId', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', '54321', 'Process')
            { Test-Envs } | Should -Throw "DEMOS_my_gh_app_id must be numeric. Got: 'NonNumericAppId'"
        }
        It "catches missing installation ID" {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_org_name', 'HelloWorldOrg', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', '12345', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', $null, 'Process')
            { Test-Envs } | Should -Throw 'Required environment variable DEMOS_my_gh_app_installation_id is not set.'
        }
        It "catches non-numeric installation ID" {
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_org_name', 'HelloWorldOrg', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_id', '12345', 'Process')
            [Environment]::SetEnvironmentVariable('DEMOS_my_gh_app_installation_id', 'NonNumericInstallationId', 'Process')
            { Test-Envs } | Should -Throw "DEMOS_my_gh_app_installation_id must be numeric. Got: 'NonNumericInstallationId'"
        }
    }
}

AfterAll {
    Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
}
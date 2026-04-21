# Module must be loaded at script scope so it exists during Pester's discovery phase,
# which is when InModuleScope is evaluated (before BeforeAll ever runs).
Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
$script:ephemeralModulePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Private', 'ConvertTo-Base64Url.ps1'))
Write-Host($script:ephemeralModulePath)
$m = New-Module -Name 'MyEphemeralModule' -ArgumentList $script:ephemeralModulePath -ScriptBlock {
    param($modulePath)
    . $modulePath
}
$m | Import-Module -Global -Force

Describe "Testing script internals -- it should convert to Base64 URLs" {
    InModuleScope 'MyEphemeralModule' {
        It 'strips base64 padding characters' {
            $result = ConvertTo-Base64Url ([byte[]]@(0x00))
            $result | Should -Not -Match '='
        }

        It 'replaces + with - and / with _' {
            # bytes 0xFB 0xFF produce +// in standard base64
            $result = ConvertTo-Base64Url ([byte[]]@(0xFB, 0xFF))
            $result | Should -Not -Match '[+/]'
        }

        It 'encodes the standard RS256 JWT header to the well-known value' {
            $bytes = [Text.Encoding]::UTF8.GetBytes('{"alg":"RS256","typ":"JWT"}')
            $result = ConvertTo-Base64Url $bytes
            $result | Should -Be 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9'
        }
    }
}

AfterAll {
    Remove-Module -Name 'MyEphemeralModule' -Force -ErrorAction SilentlyContinue
}
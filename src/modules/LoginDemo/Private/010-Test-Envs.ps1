function Test-Envs {

    <#
    .NOTES
        Author: Katie Kodes
        Date: 2026-04-21
        Company: Katie Kodes
    #>

    [CmdletBinding()]
    Param (
        [Parameter(
            ValueFromPipeline,
            HelpMessage = 'The name whom you would like to greet'
        )]
        [ValidateNotNullOrWhiteSpace()]
        [string[]]$Name = 'World'
    ) # end Param

    Begin {
        # Validate DEMOS_my_gh_org_name environment variable
        $GhOrgName = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_org_name')
        If (-not $GhOrgName) { Throw 'Required environment variable DEMOS_my_gh_org_name is not set.' }
        # Validate DEMOS_my_gh_app_id environment variable
        $GhAppId = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_id')
        If (-not $GhAppId) { Throw 'Required environment variable DEMOS_my_gh_app_id is not set.' }
        If ($GhAppId -notmatch '\A\d+\z') { Throw "DEMOS_my_gh_app_id must be numeric. Got: '$GhAppId'" }
        # Validate DEMOS_my_gh_app_installation_id environment variable
        $GhInstallId = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_installation_id')
        If (-not $GhInstallId) { Throw 'Required environment variable DEMOS_my_gh_app_installation_id is not set.' }
        If ($GhInstallId -notmatch '\A\d+\z') { Throw "DEMOS_my_gh_app_installation_id must be numeric. Got: '$GhInstallId'" }
    } # end BEGIN

    Process {} # end PROCESS

    End {} # end END

} #Test-Envs
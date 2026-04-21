function Set-GitHubToken {
    # Validate the environment variables are in place (throws an error if not).
    Test-Envs

    # Get the token
    $getTokenParams = @{
        AppId          = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_id')
        ClientId       = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_client_id')
        InstallationId = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_installation_id')
        PrivateKeyPem  = [Environment]::GetEnvironmentVariable('DEMOS_my_gh_app_pem')
    }
    $token = Get-GitHubAppInstallationToken @getTokenParams
    
    If ([Environment]::GetEnvironmentVariable('TF_BUILD') -eq 'True') {
        # We must be within an Azure Pipelines, because TF_BUILD is set to "True".
        # Therefore, we will use ADO syntax to set the job-level GITHUB_TOKEN variable; issecret masks it in all subsequent log output.
        Write-Host "##vso[task.setvariable variable=GITHUB_TOKEN;issecret=true]$token"
    }
    Else {
        # Set the process environment variable directly — keeps the token out of stdout
        [Environment]::SetEnvironmentVariable('GITHUB_TOKEN', $token, 'Process')
        Write-Host 'GITHUB_TOKEN set in the current process environment (not in Azure Pipelines; value is not printed).'
    }

    # Clean up "$token" variable
    $token = $null
}
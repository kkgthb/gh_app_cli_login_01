function Get-GitHubAppInstallationToken {
    param(
        [Parameter(Mandatory)] [string] $AppId,
        [Parameter(Mandatory)] [string] $InstallationId,
        [Parameter(Mandatory)] [string] $PrivateKeyPem
    )
    $jwt = New-GitHubAppJwt -AppId $AppId -PrivateKeyPem $PrivateKeyPem

    $restMethodParams = @{
        Uri        = "https://api.github.com/app/installations/$InstallationId/access_tokens"
        Method     = 'Post'
        TimeoutSec = 30
        Headers    = @{
            Authorization          = "Bearer $jwt"
            Accept                 = 'application/vnd.github+json'
            'X-GitHub-Api-Version' = '2022-11-28'
        }
    }
    $response = Invoke-RestMethod @restMethodParams

    if (-not $response.token) { throw 'GitHub API did not return an access token.' }
    return $response.token
}
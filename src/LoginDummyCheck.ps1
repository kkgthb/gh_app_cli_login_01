# Hooray; it works!
gh api "/orgs/$([Environment]::GetEnvironmentVariable('DEMOS_my_gh_org_name'))" `
    --jq '{login, name, description}' `
    --header "Authorization: Bearer $([Environment]::GetEnvironmentVariable('GITHUB_TOKEN'))"

# Hooray, got "repository_selection" of "selected" but 0 repositories & an empty list, just like I configured the app!
gh api '/installation/repositories' `
    --header "Authorization: Bearer $([Environment]::GetEnvironmentVariable('GITHUB_TOKEN'))"

# Requires Members:read.  Interestingly, does not 403; returns empty list.
gh api "/orgs/$([Environment]::GetEnvironmentVariable('DEMOS_my_gh_org_name'))/members" `
    --header "Authorization: Bearer $([Environment]::GetEnvironmentVariable('GITHUB_TOKEN'))"

# Should only display public repos, if there are any
gh api "/orgs/$([Environment]::GetEnvironmentVariable('DEMOS_my_gh_org_name'))/repos" `
    --header "Authorization: Bearer $([Environment]::GetEnvironmentVariable('GITHUB_TOKEN'))"

# Installation tokens are not user tokens — /user is always meaningless here, should 403 with "Resource not accessible by integration"
gh api /user `
    --header "Authorization: Bearer $([Environment]::GetEnvironmentVariable('GITHUB_TOKEN'))"
# Script to create Azure DevOps variable groups using REST API and a PAT
# Run once during project setup. Fill in all parameters before executing.

param(
    [string]$org = "<your-ado-org>",
    [string]$project = "<your-ado-project>",
    [string]$pat = "<your-pat>",
    [string]$spnServiceConnection = "<your-service-connection-name>",
    [string]$environmentUrl = "<your-environment-url>"
)

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$headers = @{Authorization = "Basic $base64AuthInfo"}

# Look up project ID
$projectInfo = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/projects/$($project)?api-version=7.0" -Headers $headers
$projectId = $projectInfo.id

function New-VariableGroup($name, $variables) {
    $body = @{
        "name"      = $name
        "type"      = "Vsts"
        "variables" = $variables
        "variableGroupProjectReferences" = @(
            @{
                "name"             = $name
                "description"      = ""
                "projectReference" = @{ "id" = $projectId; "name" = $project }
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/distributedtask/variablegroups?api-version=7.0" `
        -Method Post `
        -ContentType "application/json" `
        -Headers $headers `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    Write-Host "Created variable group: $($response.name) (id: $($response.id))"
}

# Generic Variables
New-VariableGroup "Generic Variables" @{
    "SPNServiceConnection"      = @{ "value" = $spnServiceConnection; "isSecret" = $false }
    "ConnectionReferenceTokens" = @{ "value" = ""; "isSecret" = $false }
    "EnvironmentVariableTokens" = @{ "value" = ""; "isSecret" = $false }
}

# DEV Environment Variables
New-VariableGroup "DEV Environment Variables" @{
    "EnvironmentURL" = @{ "value" = $environmentUrl; "isSecret" = $false }
}

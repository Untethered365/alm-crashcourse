# Script to create an Azure DevOps service connection using REST API and a PAT
# Run once during project setup. Fill in all parameters before executing.

param(
    [string]$org = "<your-ado-org>",
    [string]$project = "<your-ado-project>",
    [string]$pat = "<your-pat>",
    [string]$serviceConnectionName = "<your-service-connection-name>",
    [string]$tenantId = "<your-tenant-id>",
    [string]$appId = "<your-app-id>",
    [string]$clientSecret = "<your-client-secret>"
)

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# Get the project ID from the project name
$projectInfo = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/projects/$($project)?api-version=7.0" -Headers @{Authorization = "Basic $base64AuthInfo"}
$projectId = $projectInfo.id

$body = @{
    "authorization" = @{
        "parameters" = @{
            "authenticationType" = "spnKey"
            "serviceprincipalid" = $appId
            "serviceprincipalkey" = $clientSecret
            "tenantid" = $tenantId
        }
        "scheme" = "ServicePrincipal"
    }
    "data" = @{
        "subscriptionId" = ""
        "subscriptionName" = ""
        "environment" = "AzureCloud"
        "scopeLevel" = "Tenant"
        "creationMode" = "Manual"
    }
    "name" = $serviceConnectionName
    "type" = "AzureRM"
    "url" = "https://management.azure.com/"
    "isShared" = $false
    "isReady" = $true
    "serviceEndpointProjectReferences" = @(
        @{
            "name" = $serviceConnectionName
            "description" = ""
            "projectReference" = @{ "id" = $projectId; "name" = $project }
        }
    )
} | ConvertTo-Json -Depth 10

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
$response = Invoke-RestMethod -Uri "https://dev.azure.com/$org/_apis/serviceendpoint/endpoints?api-version=7.0" `
    -Method Post `
    -ContentType "application/json" `
    -Headers @{Authorization = "Basic $base64AuthInfo"} `
    -Body $bodyBytes

Write-Host "Service connection creation response:"
$response

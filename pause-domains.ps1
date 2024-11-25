param(
    [string]$mode,
    [switch]$dryRun,
    [switch]$Help
)

# Display help information
if ($Help) {
    Write-Host "Usage: .\pause-domains.ps1 <mode> [-dryRun] [-Help]"
    Write-Host ""
    Write-Host "Pause or unpause all domains in account"
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "  mode                   'pause' or 'unpause'"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -dryRun                Perform a dry run without making any changes."
    Write-Host "  -Help                  Display this help message."
    Write-Host ""
    Write-Host "If the MXG_API_KEY environment variable is not set, you will be prompted for your API key."
    exit
}

# Check for required argument
if (-not $mode) {
    Write-Host "Error: Missing required argument 'mode'."
    exit
}

# Validate mode
if ($mode -ne "pause" -and $mode -ne "unpause") {
    Write-Host "Error: Invalid mode. Must be 'pause' or 'unpause'."
    exit
}

if ($dryRun) {
	Write-Host "================ DRY RUN! No changes will be made ================="
}

# Check for API key in environment variable
$apiKey = [System.Environment]::GetEnvironmentVariable("MXG_API_KEY")
if (-not $apiKey) {
    Write-Host "The MXG_API_KEY environment variable is not set."
    $apiKey = Read-Host "Enter your MXGuardian API key to continue: "
    if (-not $apiKey) {
        Write-Host "No API key provided. Exiting."
        exit
    }
}

# API base URL
$baseUrl = [System.Environment]::GetEnvironmentVariable("MXG_API_URL")
if (-not $baseUrl) {
	$baseUrl = "https://secure.mxguardian.net/api/v1"
}

# Function to make API calls
function Invoke-APIRequest {
    param (
        [string]$url,
        [string]$method = 'GET',
        [string]$body = $null
    )
    $headers = @{
        "Authorization" = "Bearer $script:apiKey";
        "Content-Type" = "application/json";
        "Accept" = "application/json"
    }

    try {
        if ($body) {
            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method $method -Body $body
        } else {
            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method $method
        }

        return $response
    } catch {
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Host "HTTP Error: $statusCode - $statusDescription"
        } else {
            Write-Host "An error occurred: $_"
        }
        exit
    }
}

# Get the list of domains
$domainListUrl = "$baseUrl/domains"
$response = Invoke-APIRequest -url $domainListUrl
$domainList = $response.results

# Iterate over the domains
foreach ($d in $domainList) {
    $domainName = $d.domain_name

    if ( $mode -eq "pause" ) {
        Write-Host "Pausing $domainName..."
        $domain_onhold = 1;
    } elseif ( $mode -eq "unpause" ) {
        Write-Host "Unpausing $domainName..."
        $domain_onhold = 0;
    }

    $url = "$baseUrl/domains/$domainName"
    $body = '{"domain_onhold":' + $domain_onhold + '}'
    if (-not $dryRun) {
        Invoke-APIRequest -url $url -method 'PATCH' -body $body
    }

}


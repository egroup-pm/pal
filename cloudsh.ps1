<#
.SYNOPSIS
    Sets the Azure Partner Administration Link (PAL) relationship on all enabled subscriptions using Cloud Shell.

.DESCRIPTION
    This script is designed for use in Azure Cloud Shell. It automatically discovers all enabled subscriptions available to your
    owner account. It then ensures the Az.ManagementPartner module is installed (using the -Scope CurrentUser flag) and iterates over each subscription.
    For each subscription it attempts to switch context (skipping those where context switching fails due to tenant or subscription issues)
    and then invokes New-AzManagementPartner with a fixed PartnerId (317881).

.EXAMPLE
    In Cloud Shell, simply run:
    .\Set-AzurePAL-CloudShell.ps1
#>

# Ensure the Az.ManagementPartner module is installed in Cloud Shell (using current user scope)
if (-not (Get-Module -ListAvailable -Name Az.ManagementPartner)) {
    Write-Output "Az.ManagementPartner module not found. Installing it..."
    Install-Module -Name Az.ManagementPartner -Force -Scope CurrentUser -AllowClobber
}
Import-Module Az.ManagementPartner -Force

# Discover all enabled subscriptions for the current account
$subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }

if (-not $subscriptions) {
    Write-Error "No enabled subscriptions found."
    exit
}

# Fixed PartnerId for the PAL relationship
$partnerId = "317881"

foreach ($sub in $subscriptions) {
    Write-Output "Processing subscription: $($sub.Name) ($($sub.Id))"
    try {
        # Attempt to switch context to the subscription; if it fails, skip this subscription.
        Select-AzSubscription -SubscriptionId $sub.Id -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to set context for subscription $($sub.Id). Skipping. Error: $_"
        continue
    }
    
    try {
        Write-Output "Setting PAL relationship with PartnerId '$partnerId' for subscription $($sub.Id)..."
        New-AzManagementPartner -PartnerId $partnerId
        Write-Output "Successfully set PAL relationship for subscription $($sub.Id)."
    }
    catch {
        Write-Error "Error processing subscription $($sub.Id): $_"
    }
}

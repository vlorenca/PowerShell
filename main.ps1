Write-Host "Applying firewall rules..."

function New-CustomFirewallRule {
    param (
        [string]$RuleName,
        [string]$ProgramPath,
        [string]$Direction = "Outbound",
        [string]$Action = "Block"
    )

    # Remove existing rule if it exists
    if (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue) {
        Write-Host "Existing rule found. Removing..."
        Remove-NetFirewallRule -DisplayName $RuleName
    }

    Write-Host "Creating firewall rule: $RuleName"
    New-NetFirewallRule `
        -DisplayName $RuleName `
        -Direction $Direction `
        -Program $ProgramPath `
        -Action $Action `
        -Profile Any `
        -Enabled True
}

# Example rule
New-CustomFirewallRule `
    -RuleName "Block Example App" `
    -ProgramPath "C:\Program Files\ExampleApp\example.exe"

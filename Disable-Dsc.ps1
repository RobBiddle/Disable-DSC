<#
.SYNOPSIS
    Stop DSC & Set DSC LCM to Push Mode with a blank configuration.
    Useful for temporarily disabling a DSC Pull Mode Node during troubleshooting
.EXAMPLE
    PS C:\> . .\Disable-DSC.ps1
.NOTES
    Robert D. Biddle
    https://github.com/RobBiddle/Disable-DSC
#>

[CmdletBinding()]
param ()

[DSCLocalConfigurationManager()]
configuration DisableDSC
{
    Node $env:COMPUTERNAME
    {
        Settings {
            RefreshMode = 'Push'
        }
    }
}

DisableDSC

function Stop-DscProcess {
    # Find the process that is hosting the DSC engine
    $dscProcessID = Get-WmiObject msft_providers | Where-Object {
        $_.provider -like 'dsccore'
    } | Select-Object -ExpandProperty HostProcessIdentifier
    # Stop the process
    if ($dscProcessID) {
        Write-Output "Stopping DSC LCM Process with ID: $dscProcessID"
        Get-Process -Id $dscProcessID | Stop-Process -Force -ErrorAction SilentlyContinue
    }

}

while (Stop-DscProcess) {
    Start-Sleep -Milliseconds 100
    Stop-DscProcess
}

Remove-DscConfigurationDocument -Stage Current, Pending, Previous
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path .\DisableDSC -force

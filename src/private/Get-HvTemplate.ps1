function Get-HVTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
    }
    
    process {
        if(-not (Test-Path "$PSScriptRoot\..\templates\$Name.psd1"))
        {
            Write-Error "Unable to find template with name '$Name'" -ErrorAction Stop
        }

        Import-PowerShellDataFile -Path "$PSScriptRoot\..\templates\$Name.psd1" -ErrorAction Stop
    }
    
    end {
    }
}
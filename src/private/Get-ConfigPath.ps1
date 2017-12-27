function Get-ConfigPath
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]] $Key,

        [Parameter()]
        [hashtable] $ModuleConfig = $(Import-PowerShellDataFile -Path "$PSScriptRoot\..\config\module.psd1" )
    )
    
    begin
    {
    }
    
    process
    {
        $PathHash = $ModuleConfig.Paths

        if (-not $PSBoundParameters.ContainsKey('Key'))
        {
            $PathHash.Base # Write-Output
            return
        }

        $output = [System.Text.StringBuilder]::new()
        $null = $output.Append($PathHash.Base)

        foreach ($k in $Key)
        {
            if ($PathHash.$k -is [hashtable])
            {
                $null = $output.Append("\$($PathHash.$k.Base)")
                $PathHash = $PathHash.$k
            }
            elseif ($PathHash.$k -is [string])
            {
                $null = $output.Append("\$($PathHash.$k)")
                $output.ToString() # Write-Output
                return # No where else to go
            }
        }

        $output.ToString() # Write-Output (catch-all)
    }
    
    end
    {
    }
}
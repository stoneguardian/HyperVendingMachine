function Get-AllConfigPaths
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable] $PathHash = $(Import-PowerShellDataFile -Path "$PSScriptRoot\..\config\module.psd1" ),

        [Parameter()]
        [string] $CurrentBase = ''
    )
    
    begin
    {
    }
    
    process
    {
        if ([string]::IsNullOrEmpty($CurrentBase)) # Assume first round
        {
            if (-not $PathHash.ContainsKey('Base'))
            {
                Write-Error 'Root must contain "Base"-key' -ErrorAction Stop 
            }

            $CurrentBase = $PathHash.Base
        }

        $CurrentBase # Write-Output

        foreach ($key in $($PathHash.Keys | Where-Object { $_ -ne 'Base' }))
        {
            if ($PathHash.$key -is [string])
            {
                "$CurrentBase\$($PathHash.$key)"
            }
            elseif ($PathHash.$key -is [hashtable])
            {
                if (-not $PathHash.$key.ContainsKey('Base'))
                {
                    Write-Warning -Message "'$key'-hashtable does not contain key 'Base', it will be ignored"
                    continue
                }

                Get-AllConfigPaths -PathHash $PathHash.$key -CurrentBase "$CurrentBase\$($PathHash.$key.Base)"
            }
        }
            
    }
    
    end
    {
    }
}
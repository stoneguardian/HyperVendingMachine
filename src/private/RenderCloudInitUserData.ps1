function RenderCloudInitUserData
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $VMName,

        [Parameter()]
        [string] $Domain = [string]::Empty,

        [Parameter()]
        [hashtable] $UserData = @{ },

        [Parameter()]
        [hashtable] $ModuleConfigUserData = (Import-Configuration)['CloudInitDefaults']['UserData']
    )
    
    begin
    {
        # Keys that won't be updated if passed by the user and it already exists in
        # $out_userData (aka the module configration-defaults)
        $_keyBlacklist = 'package_upgrade', 'power_state', 'hostname', 'fqdn'
    }
    
    process
    {
        $out_userData = $ModuleConfigUserData

        $out_userData['hostname'] = $VMName.ToLower()

        if ([string]::IsNullOrEmpty($Domain))
        {
            $out_userData['fqdn'] = $VMName.ToLower()
        }
        else
        {
            $out_userData['fqdn'] = "$($VMName.ToLower()).$($Domain.ToLower())"
        }

        # List of keys not in the module configuration-defaults
        $keysToAdd = $UserData.Keys.Where{ $_ -notin $out_userData.Keys }
        Write-Debug "keysToAdd: $($keysToAdd -join ',')"

        # List of keys that exist in the module configuration-defaults, and that are not on the blacklist
        $keysToUpdate = $UserData.Keys.Where{ ($_ -notin $keysToAdd) -and ($_ -notin $_keyBlacklist) }
        Write-Debug "keysToUpdate: $($keysToUpdate -join ',')"

        foreach ($key in $keysToAdd)
        {
            $out_userData[$key] = $UserData[$key]
        }

        foreach ($key in $keysToUpdate)
        {
            if ($out_userData[$key] -is [System.Collections.IList])
            {
                # Concatenate the two lists
                $out_userData[$key] = @($out_userData[$key]) + @($UserData[$key])
            }
            else 
            {
                # Overwrite if not list (and not on blacklist)
                $out_userData[$key] = $UserData[$key]
            }
        }

        # Do not remove '#cloud-config'...
        @"
$('#cloud-config')
$($out_userData | ConvertTo-Yaml)
"@ # Write-Output 
        
    }
    
    end
    {
        
    }
}
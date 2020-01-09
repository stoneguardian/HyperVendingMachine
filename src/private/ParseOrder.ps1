function ParseOrder
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable] $Order
    )
    
    begin
    {
        $MandatoryKeys = @('VMName')
    }
    
    process
    {
        $missingMandatoryKeys = $MandatoryKeys.Where{ $_ -notin $Order.Keys }
        if ($missingMandatoryKeys.Count -ne 0)
        {
            Write-Error -Message "Information missing from order: `n - $($missingMandatoryKeys -join "`n - ")" -ErrorAction Stop
        }

        if ($Order.ContainsKey('Memory'))
        {
            $Order['Memory'] = [VMParserMemory]::new($Order['Memory']).ToHashtable()
        }

        if ($Order.ContainsKey('Disks'))
        {
            if (($Order['Disks'] -is [string]) -or ($Order['Disks'] -is [int]) -or ($Order['Disks'] -is [long]))
            {
                $Order['Disks'] = @(@{
                        Size = $Order['Disks']
                    })
            }

            $_disks = foreach ($disk in @($Order['Disks']))
            {
                if (-not $disk.ContainsKey('Size'))
                {
                    Write-Error -Message "Missing required disk-info: `n - Size" -ErrorAction Stop
                }

                # Ensure size is in bytes
                $disk['Size'] = [long]$disk['Size']

                if (-not $disk.ContainsKey('System'))
                {
                    $disk['System'] = $false
                }

                # If this is the system disk, use VM-name
                if ((-not $disk.ContainsKey('Name')) -and ($disk['System'] -eq $true))
                {
                    
                    $disk['Name'] = $Order['VMName']
                }
                # If not then genereate a random name
                elseif (-not $disk.ContainsKey('Name'))
                {
                    $disk['Name'] = [Guid]::NewGuid()
                }

                [hashtable]$disk # Write-Output
            }

            $_systemdiskCount = ($_disks).Where{ $_.System -eq $true }.Count
            if ($_systemdiskCount -gt 1)
            {
                Write-Error -Message "Only one 'System' disk is permitted in an order, found $_systemdiskCount" -ErrorAction Stop
            }

            # Ensure 'System'-disk is first in output-list
            $_systemDisk = @($_disks).Where{ $_.System -eq $true }
            $_otherDisks = @($_disks).Where{ $_.System -ne $true }

            $Order['Disks'] = @($_systemDisk + $_otherDisks)
        }

        if (-not ($Order.ContainsKey('Image')))
        {
            $Order['Image'] = 'None'
        }

        if (-not ($Order.ContainsKey('CI_UserData')))
        {
            $Order['CI_UserData'] = @{ }
        }

        if (-not ($Order.ContainsKey('Domain')))
        {
            $Order['Domain'] = [string]::Empty
        }

        if ($Order.ContainsKey('Network'))
        {
            if ($Order['Network'] -is [string])
            {
                $Order['Network'] = @{
                    Switch = "$($Order['Network'])"
                    Vlan   = $false
                }
            }
            elseif ($Order['Network'] -is [hashtable])
            {
                if (-not ($Order['Network'].ContainsKey('Switch')))
                {
                    Write-Error -Message "Missing value for 'Switch', it is required" -ErrorAction Stop
                }

                if (-not ($Order['Network'].ContainsKey('Vlan')))
                {
                    $Order['Network']['Vlan'] = $false
                }
            }
            else 
            {
                Write-Error -Message "'Network' can only be [string] or [hashtable], given: $($Order['Network'].GetType().Name)" -ErrorAction Stop
            }
        }

        $Order # Write-Output
    }
    
    end
    {
        
    }
}
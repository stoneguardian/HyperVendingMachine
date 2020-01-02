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

        function ParseMemory
        {
            [Parameter(Mandatory, ValueFromPipeline)]
            [hashtable] $Order

            $mandatoryKeys = @('Dynamic', 'Boot')
            $outputKeys = $mandatoryKeys + @('Min', 'Max')

            if ($Order['Memory'] -isnot [hashtable])
            {
                $Order['Memory'] = @{
                    Dynamic = $false
                    Boot    = $Order['Memory']
                }
            }

            $memoryMissingMandatoryKeys = @('Dynamic', 'Boot').Where{ $_ -notin $Order['Memory'].Keys }
            if ($memoryMissingMandatoryKeys.Count -ne 0)
            {
                Write-Error -Message "Missing required memory-information: `n - $($memoryMissingMandatoryKeys -join "`n - ")" -ErrorAction Stop
            }
            
            if ($Order['Memory']['Boot'] -isnot [long])
            {
                $Order['Memory']['Boot'] = [long]$Order['Memory']['Boot']
            }

            # "Autocomplete" missing properties or ensure correct type
            if (-not $Order['Memory'].ContainsKey('Min'))
            {
                # Default to half of boot-memory
                $Order['Memory']['Min'] = $Order['Memory']['Boot'] / 2
            }
            elseif ($Order['Memory']['Min'] -isnot [long])
            {
                $Order['Memory']['Min'] = [long]$Order['Memory']['Min']
            }

            if (-not $Order['Memory'].ContainsKey('Max'))
            {
                # Default to twice of boot-memory
                $Order['Memory']['Max'] = $Order['Memory']['Boot'] * 2
            }
            elseif ($Order['Memory']['Max'] -isnot [long])
            {
                $Order['Memory']['Max'] = [long]$Order['Memory']['Max']
            }

            $extraKeys = $Order['Memory'].Keys.Where{ $_ -notin $outputKeys }

            foreach ($key in $extraKeys)
            {
                $Order['Memory'].Remove($key)
            }
        }
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
            $Order = $Order | ParseMemory
        }
        else 
        {
            Write-Error -Message "Must contain key 'Memory'" -ErrorAction Stop
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

        $Order # Write-Output
    }
    
    end
    {
        
    }
}
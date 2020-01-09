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
            $Order['Memory'] = [VMParserMemory]::new($Order['Memory']).Build()
        }

        if ($Order.ContainsKey('Disks'))
        {
            $Order['Disks'] = [VMParserDisks]::new($Order['VMName']).WithInput($Order['Disks']).Build()
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
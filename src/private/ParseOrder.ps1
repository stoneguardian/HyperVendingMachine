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
            $vmExists = $null -ne (Get-VM -Name $vmName -ErrorAction SilentlyContinue)
            $Order['Disks'] = [VMParserDisks]::new($Order['VMName'], $vmExists).WithInput($Order['Disks']).Build()
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
            $Order['Network'] = [VMParserNetwork]::new($Order['Network']).Build()
        }

        $Order # Write-Output
    }
    
    end
    {
        
    }
}
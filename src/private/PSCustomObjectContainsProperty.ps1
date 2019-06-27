function PSCustomObjectContainsProperty
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject] $InputObject,
        
        [Parameter(Mandatory)]
        [string[]] $Name,

        [Parameter()]
        [switch] $BoolOutput
    )
    
    begin
    {
    }
    
    process
    {
        if ($BoolOutput -and $Name.Count -gt 1)
        {
            Write-Error -Message "-BoolOutput can only be used if one -Name is given"
            return
        }

        foreach ($n in $Name)
        {
            $in = $n -in $InputObject.PSObject.Properties.Name

            if ($BoolOutput)
            {
                $in
            }
            else 
            {
                # If multiple inputs return <name: bool> pair
                @{Name = $n; PropertyOnObject = $in }
            }
        }
    }
}
    
end
{
}
}
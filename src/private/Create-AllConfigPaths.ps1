function Create-AllConfigPaths
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]] $Paths
    )
    
    begin
    {
    }
    
    process
    {
        foreach ($p in $paths)
        {
            if (-not (Test-Path $p))
            {
                $null = New-Item -Path $p -ItemType Directory -Force
            }
        }
    }
    
    end
    {
    }
}
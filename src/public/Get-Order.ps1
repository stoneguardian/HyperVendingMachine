function Get-Order
{
    [CmdletBinding()]
    param (
        [parameter()]
        [ValidateSet('Pending', 'Completed')]
        [string] $Stage = 'Pending'
    )
    
    begin
    {
        $moduleConfig = Import-Configuration
    }
    
    process
    {
        if($Stage -eq 'Pending')
        {
            $dirPath = $moduleConfig.OrderBasePath
        }
        elseif($Stage -eq 'Completed')
        {
            $dirPath = "$($moduleConfig.OrderBasePath)\completed"
        }
        
        if(-not (Test-Path $dirPath))
        {
            Write-Error "Directory for '$Stage' orders does not exist"
            return
        }
        
        $files = Get-ChildItem -Path $dirPath -Filter "*.yml"

        foreach($file in $files)
        {
            Get-Content -Path $file.FullName -Raw |
                ConvertFrom-Yaml |
                ParseOrder # Write-Output
        }
    }
    
    end
    {
        
    }
}
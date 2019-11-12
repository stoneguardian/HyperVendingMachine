function Get-Template
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Name = '*', # All by default

        [Parameter()]
        [switch] $ListAvailable
    )
    
    begin
    {
        $moduleConfig = Import-Configuration
    }
    
    process
    {
        $templates = (Get-ChildItem -Path $moduleConfig.TemplateBasePath -Filter "$Name.psd1")

        if ($ListAvailable)
        {
            $templates.BaseName # Write-Output
        }
        else 
        {
            foreach ($file in $templates)
            {
                [PSCustomObject]@{
                    Name     = $file.BaseName
                    Template = Import-PowerShellDataFile -Path $file.FullName
                } # Write-Output
            }    
        }
    }
    
    end
    {
        
    }
}
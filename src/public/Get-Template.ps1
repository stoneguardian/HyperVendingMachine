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
        $templates = (Get-ChildItem -Path $moduleConfig.TemplateBasePath -Filter "$Name.yml")

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
                    Path     = $file.FullName
                    Template = Get-Content -Path $file.FullName -Raw | ConvertFrom-Yaml
                } # Write-Output
            }    
        }
    }
    
    end
    {
        
    }
}
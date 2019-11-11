function Get-Template
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Name = '*' # All by default
    )
    
    begin
    {
        $moduleConfig = Import-Configuration
    }
    
    process
    {
        (Get-ChildItem -Path $moduleConfig.TemplatePath -Filter '*.psd1').BaseName # Write-Output
    }
    
    end
    {
        
    }
}
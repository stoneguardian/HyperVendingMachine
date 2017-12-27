function Import-HvVmOrder
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable] $ModuleConfig = $(Import-PowerShellDataFile -Path "$PSScriptRoot\..\config\module.psd1" )
    )
    
    begin
    {
        $_GuidRegex = '[0-9,a-f,A-F]{8}-[0-9,a-f,A-F]{4}-[0-9,a-f,A-F]{4}-[0-9,a-f,A-F]{4}-[0-9,a-f,A-F]{12}'

        # Paths
        $incomingDir = Get-ConfigPath -Key 'Incoming', 'VMs' -ModuleConfig $ModuleConfig
        $queueNewDir = Get-ConfigPath -Key 'Enqueued', 'ToCreate' -ModuleConfig $ModuleConfig
        $queueChangeDir = Get-ConfigPath -Key 'Enqueued', 'ToChange' -ModuleConfig $ModuleConfig
        $taskDir = Get-ConfigPath -Key 'Task' -ModuleConfig $ModuleConfig
        $errorDir = Get-ConfigPath -Key 'Error' -ModuleConfig $ModuleConfig
    }
    
    process
    {
        
        $toProcess = @(Get-ChildItem -Path $incomingDir -Filter '*.json' -File)

        if ($toProcess.Count -eq 0)
        {
            return # Nothing to process
        }

        foreach ($order in $toProcess)
        { 
            if (-not ($order.BaseName -match $_GuidRegex))
            {
                Move-Item -Path $order.FullName -Destination "$errorDir\Error-NameNotGuid-$($order.Name)"
                continue # Item processed
            }

            $json_object = Get-Content $order.FullName | ConvertFrom-Json

            # convert to hashtable
            


            # Validate order
            
        }
    }
    
    end
    {
    }
}
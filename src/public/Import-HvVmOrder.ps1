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
    }
    
    process
    {
        # Paths
        $incomingDir = Get-ConfigPath -Key 'Incoming', 'VMs' -ModuleConfig $ModuleConfig
        $queueNewDir = Get-ConfigPath -Key 'Enqueued', 'ToCreate' -ModuleConfig $ModuleConfig
        $queueChangeDir = Get-ConfigPath -Key 'Enqueued', 'ToChange' -ModuleConfig $ModuleConfig
        $taskDir = Get-ConfigPath -Key 'Task' -ModuleConfig $ModuleConfig
        $errorDir = Get-ConfigPath -Key 'Error' -ModuleConfig $ModuleConfig
        $statusDir = Get-ConfigPath -Key 'Status' -ModuleConfig $ModuleConfig

        # 
        # 
        # 
        
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

            $orderStatus = @{
                Id            = $order.BaseName
                Error         = ''
                CurrentStatus = ''
                CurrentStage  = ''
            }
            $orderStatus | ConvertTo-Json | Out-File -FilePath "$statusDir\$($order.Name)"

            # Read file
            $orderObject = Get-Content $order.FullName | ConvertFrom-Json

            # Name is mandatory mandatory
            if ($null -eq ($orderObject.PSObject.Properties | Where-Object { $_.Name -eq 'Name' }))
            {
                Move-Item -Path $order.FullName -Destination "$errorDir\$($order.Name)"
                
                $orderStatus.Error = 'Order does not contain Name'
                $orderStatus | ConvertTo-Json | Out-File -FilePath "$statusDir\$($order.Name)"
                continue
            }

            # If template we need to import properties
            if ($null -ne ($orderObject.PSObject.Properties | Where-Object { $_.Name -eq 'Template' }))
            {
                try
                {
                    $template = Get-HVTemplate -Name $orderObject.Template
                }
                catch
                {
                    Move-Item -Path $order.FullName -Destination "$errorDir\$($order.Name)"
                    
                    $orderStatus.Error = $_.Exception.Message
                    $orderStatus | ConvertTo-Json | Out-File -FilePath "$statusDir\$($order.Name)"
                    continue
                }

                foreach ($key in $template.PSObject.Properties.Name)
                {
                    $orderObject.$key = $template.$key
                }
            }

            # convert to hashtable
            


            # Validate order
            

            # Queue order
            $orderObject | ConvertTo-Json -Depth 10 | Out-File -FilePath "$queueNewDir\$($order.Name)"
            $orderStatus.CurrentStage = 'Queued for creation'
            $orderStatus | ConvertTo-Json | Out-File -FilePath "$statusDir\$($order.Name)"
        }
    }
    
    end
    {
    }
}
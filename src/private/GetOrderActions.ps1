function GetOrderActions
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable] $Order
    )
    
    begin
    {
        $moduleConfiguration = Import-Configuration
        $shutdownRequired = $false
        $vmExists = $false

        

        $actions = [System.Collections.Generic.List[hashtable]]::new()
    }
    
    process
    {
        $commonFunctionParams = @{
            'Set-VM' = @{ 
                Name = $Order['VMName']
            }
        }

        # Create VM
        #$VM = Get-VM -Name $Order -ErrorAction SilentlyContinue
        $vmExists = $null -ne $VM 

        if (-not $vmExists)
        {
            $newVmParams = @{
                Name               = $Order['VMName']
                MemoryStartupBytes = $Order['Memory']['Boot']
                Path               = $moduleConfiguration['VMStoragePath']
                Generation         = 2
                NoVHD              = $true
            }

            $actions.Add(@{
                    Command    = 'NewVM'
                    Parameters = $newVmParams
                })

            $commonFunctionParams['Set-VM'] = @{
                Name                 = $Order['VMName']
                ProcessorCount       = $Order['CPUs']
                MemoryMaximumBytes   = $Order.Memory.Max
                MemoryMinimumBytes   = $Order.Memory.Min
                
                # Defaults
                AutomaticStartAction = 'Start'
                AutomaticStartDelay  = 1
                AutomaticStopAction  = 'Save'
            }

            switch ($Order.Memory.Dynamic)
            {
                $true { $commonFunctionParams['Set-VM']['DynamicMemory'] = $true }
                $false { $commonFunctionParams['Set-VM']['StaticMemory'] = $true }
            }

            $actions.Add(@{
                    Command    = 'SetVM'
                    Parameters = $commonFunctionParams['Set-VM']
                })
        }
        else 
        {
            # CPU
            if ($Order.ContainsKey('CPUs'))
            {
                if ($Order['CPUs'] -ne $VM.ProcessorCount)
                {
                    $commonFunctionParams['Set-VM']['ProcessorCount'] = $Order['CPUs']
                    $shutdownRequired = $true
                }
            }

            # Memory
            if ($Order.ContainsKey('Memory'))
            {
                if ($Order.Memory.Dynamic -ne $VM.DynamicMemoryEnabled)
                {
                    switch ($Order.Memory.Dynamic)
                    {
                        $true { $commonFunctionParams['Set-VM']['DynamicMemory'] = $true }
                        $false { $commonFunctionParams['Set-VM']['StaticMemory'] = $true }
                    }
                    $shutdownRequired = $true
                }

                if ($Order.Memory.Boot -ne $VM.MemoryStartup)
                {
                    $commonFunctionParams['Set-VM']['MemoryStartupBytes'] = $Order.Memory.Boot
                    $shutdownRequired = $true
                }

                if (($Order.Memory.Dynamic) -and ($Order.Memory.Max -ne $VM.MemoryMaximum))
                {
                    $commonFunctionParams['Set-VM']['MemoryMaximumBytes'] = $Order.Memory.Max

                    # Shutdown is only required if the new MaximumBytes-value is lower than the old value
                    if ($Order.Memory.Max -lt $VM.MemoryMaximum) { $shutdownRequired = $true }
                }

                if (($Order.Memory.Dynamic) -and ($Order.Memory.Min -ne $VM.MemoryMinimum))
                {
                    $commonFunctionParams['Set-VM']['MemoryMinimumBytes'] = $Order.Memory.Min

                    # Shutdown is only required if the new MaximumBytes-value is lower than the old value
                    if ($Order.Memory.Min -lt $VM.MemoryMinimum) { $shutdownRequired = $true }
                }
            }

            # Only take actions if parameters are set
            if ($commonFunctionParams['Set-VM'].Keys.Count -gt 1)
            {
                $addShutdownAction = ($VM.State -ne 'Off') -and $shutdownRequired
            
                if ($addShutdownAction)
                {
                    $actions.Add(@{
                            Command    = 'StopVM'
                            Parameters = @{
                                Name = $Order['VMName']
                            }
                        })
                }

                $actions.Add(@{
                        Command    = 'SetVM'
                        Parameters = $commonFunctionParams['Set-VM']
                    })

                if ($addShutdownAction)
                {
                    $actions.Add(@{
                            Command    = 'StartVM'
                            Parameters = @{
                                Name = $Order['VMName']
                            }
                        })
                }
            }
        }

        # TODO: Disk


        $actions # Write-Output
    }
    
    end
    {
        
    }
}
Describe 'Resolve-HVMOrder' {
    
    BeforeAll {
        # Create dummy "Get-VM" if Hyper-V module is not installed
        if ($null -eq (Get-Command 'Get-VM' -ErrorAction SilentlyContinue))
        {
            # "global:" required for mock to see function
            function global:Get-VM
            {
                [CmdletBinding()]
                param([string] $Name)
    
                return $null
            }
        }

        # Build module and import it
        . $PSScriptRoot/../build.ps1
    
        Import-Module $PSScriptRoot/../release/HyperVendingMachine/HyperVendingMachine.psd1 -Force

        Mock -CommandName 'Get-VM' -ModuleName HyperVendingMachine
    }

    Context 'Memory' -Tag 'Order-Mem' {
        $memTestCases = @(
            @{ 
                case = 'Minimal object (string)' 
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = '512MB'
                }
                type = [string]
            }
            @{
                case = 'Minimal object (long)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = 1073741824
                }
                type = [long]
            }
            @{
                case = 'Dynamic memory without min,max (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '512MB'
                    }
                }
                type = [hashtable]
            }
            @{
                case = 'Dynamic memory without min (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '1GB'
                        Max     = '1GB'
                    }
                }
            }
            @{
                case = 'Dynamic memory without max (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '512MB'
                        Min     = '512MB'
                    }
                }
            }
            @{
                case = 'Extra key (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = @{
                        Dynamic = $true
                        Boot    = '512MB'
                        Kake    = $true
                    }
                }
            }
        )

        $memTypeTestCases = $memTestCases.Where{ 'type' -in $_.Keys }

        It 'Accepts [<type>] as input' -TestCases $memTypeTestCases {
            param($obj)
            { $obj | Resolve-HVMOrder } # Should not throw
        }

        It 'Throws if imput is missing mandatory keys for [hashtable]' {
            { @{ VMName = 'test'; Memory = @{ Dynamic = $true } } | Resolve-HVMOrder } | Should -Throw -ExpectedMessage "*Boot"
            { @{ VMName = 'test'; Memory = @{ Boot = 1GB } } | Resolve-HVMOrder } | Should -Throw -ExpectedMessage "*Dynamic"
        }

        It 'Allways outputs a hashtable - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder
            $result.Memory | Should -BeOfType [hashtable]
        }

        It 'Allways outputs the same keys for all input - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder
            $missingKeys = @('Dynamic', 'Boot', 'Min', 'Max').Where{ $_ -notin $result.Memory.Keys }
            $missingKeys -join ', ' | Should -BeNullOrEmpty
        }

        It 'Ensures numbers are [long] - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder

            $result.Memory.Boot | Should -BeOfType [long]
            $result.Memory.Min | Should -BeOfType [long]
            $result.Memory.Max | Should -BeOfType [long]
        }

        It 'Ensures "Max" is not less than "Boot"' {
            $result = @{
                VMName = 'test'
                Memory = @{
                    Dynamic = $true
                    Boot    = 1GB
                    Max     = 512MB
                }
            }
            $result.Max | Should -Be $order.Boot
        }
    
        It 'Ensures "Min" is not greater than "Boot"' {
            $result = @{
                VMName = 'test'
                Memory = @{
                    Dynamic = $true
                    Boot    = 1GB
                    Min     = 2GB
                }
            }
            $result.Min | Should -Be $order.Boot
        }
    }

    Context 'Disk' -Tag 'Order-Disk' {
        $diskTestCases = @(
            @{ 
                case = 'Minimal object (string)' 
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = '10GB'
                }
                type = [string]
            }
            @{
                case = 'Minimal object (long)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = 5368709120
                }
                type = [long]
            }
            @{
                case = 'Single disk, hashtable, no system (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            Size = '15GB'
                        }
                    )
                }
                type = [hashtable]
            }
            @{
                case = 'Single disk, hashtable, has system (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            System = $true
                            Size   = '15GB'
                        }
                    )
                }
            }
            @{
                case = 'Multiple disks, hashtable, one has system (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            System = $true
                            Size   = '15GB'
                        }
                        @{
                            Name = 'Data'
                            Size = '20GB'
                        }
                    )
                }
                type = [hashtable[]]
            }
        )

        $diskTypeTestCases = $diskTestCases.Where{ 'type' -in $_.Keys }

        It 'Accepts [<type>] as input' -TestCases $diskTypeTestCases {
            param($obj)
            { $obj | Resolve-HVMOrder } # Should not throw
        }

        It 'Converts single value to one disk' {
            $obj = @{
                VMName = 'test' # Mandatory
                Disks  = '10GB'
            }
            $result = $obj | Resolve-HVMOrder
            #$result.Disks | Should -BeOfType [System.Object[]]
            $result.Disks | Should -BeOfType [System.Collections.Hashtable]
            $result.Disks.Count | Should -Be 1
        }

        It 'Ensures system-disk is first element in array' {
            $obj = @{
                VMName = 'test'
                Disks  = @(
                    @{
                        Size = 10GB
                    }
                    @{
                        System = $true
                        Size   = 10GB
                    }
                )
            }

            $result = $obj | Resolve-HVMOrder
            $result.Disks[0].System | Should -Be $true
        }

        It 'Throws if more than one system-disk is given' {
            $obj = @{
                VMName = 'test'
                Disks  = @(
                    @{
                        System = $true
                        Size   = 10GB
                    }
                    @{
                        System = $true
                        Size   = 10GB
                    }
                )
            }

            { $obj | Resolve-HVMOrder } | Should -Throw -ExpectedMessage "Only one*"
        }

        It 'Allways outputs an array - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder
            $result.Disks | Should -BeOfType [System.Collections.Hashtable]
        }

        It 'Throws if input is missing mandatory keys for [hashtable]' {
            { @{ VMName = 'test'; Disks = @{ Test = $true } } | Resolve-HVMOrder } | Should -Throw -ExpectedMessage "*Size"
        }

        It 'Allways outputs the same keys for all input - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder

            foreach ($disk in $result.Disks)
            {
                $missingKeys = @('System', 'Name', 'Size').Where{ $_ -notin $disk.Keys }
                $missingKeys -join ', ' | Should -BeNullOrEmpty
            }
        }

        It 'Ensures .Size is [long] - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder

            foreach ($disk in $result.Disks)
            {
                $disk.Size | Should -BeOfType [long]
            }
        }

        It 'Ensures System-disk has the same name as the VM - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | Resolve-HVMOrder
            $systemDisk = $result.Disks.Where{ $_.System } | Select-Object -First 1
            $systemDisk.Name | Should -Be $obj.VMName
        }
    }

    Context 'Image' {
        It 'Ensures .Image is "None" if no key specified' {
            $result = @{
                VMName = 'test'
            } | Resolve-HVMOrder

            $result.Image | Should -Be 'None'
        }

        It 'Passes thru value if Image-key is given' {
            $result = @{
                VMName = 'test'
                Image  = 'Ubuntu/Bionic'
            } | Resolve-HVMOrder

            $result.Image | Should -Be 'Ubuntu/Bionic'
        }
    }

    Context 'Network' -Tag 'Order-Network' {
        It 'Converts string to Switch with no VLAN set' {
            $result = @{
                VMName  = 'Test'
                Network = 'Switch-Name'
            } | Resolve-HVMOrder

            $result.Network.Switch | Should -Be 'Switch-Name'
            $result.Network.Vlan | Should -Be $false
        }

        It 'Adds missing VLAN property' {
            $result = @{
                VMName  = 'Test'
                Network = @{
                    Switch = 'Switch-Name'
                }
            } | Resolve-HVMOrder

            $result.Network.Switch | Should -Be 'Switch-Name'
            $result.Network.Vlan | Should -Be $false
        }

        It 'Errors if no switch is given' {
            $testInput = @{
                VMName  = 'Test'
                Network = @{
                    Vlan = 10
                }
            }

            { $testInput | Resolve-HVMOrder } | Should -Throw -ExpectedMessage '* Switch'
        }
    }
}
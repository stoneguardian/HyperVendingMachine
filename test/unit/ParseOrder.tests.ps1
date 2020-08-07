# Load required files
. $PSScriptRoot\..\..\src\classes\VMParserBase.ps1
. $PSScriptRoot\..\..\src\classes\VMParserMemory.ps1
. $PSScriptRoot\..\..\src\classes\VMParserDisk.ps1
. $PSScriptRoot\..\..\src\classes\VMParserNetwork.ps1
. $PSScriptRoot\..\..\src\private\ParseOrder.ps1


# ParseOrder
Describe 'ParseOrder' {
    # Mock Get-VM if command is available
    if ($null -ne (Get-Command 'Get-VM' -ErrorAction SilentlyContinue))
    {
        Mock -CommandName 'Get-VM' -MockWith {
            return $null
        }
    }
    else 
    {
        function Get-VM
        {
            [CmdletBinding()]
            param([string] $Name)
        
            return $null
        }    
    }

    Context 'Memory' {
        $memTestCases = @(
            @{ 
                case = 'Minimal object (string)' 
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = '512MB'
                }
            }
            @{
                case = 'Minimal object (long)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Memory = 1073741824
                }
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

        It 'Is hashtable - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $result.Memory | Should -BeOfType [hashtable]
        }

        It 'Adds missing properties - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $missingKeys = [VMParserMemory]::OutputMap.Keys.Where{ $_ -notin $result.Memory.Keys }
            $missingKeys -join ', ' | Should -BeNullOrEmpty
        }

        It 'Ensures numbers are [long] - <case>' -TestCases $memTestCases {
            param($obj)
            $result = $obj | ParseOrder

            $result.Memory.Boot | Should -BeOfType [long]
            $result.Memory.Min | Should -BeOfType [long]
            $result.Memory.Max | Should -BeOfType [long]
        }
    }

    Context 'Disk' {
        $diskTestCases = @(
            @{ 
                case = 'Minimal object (string)' 
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = '10GB'
                }
            }
            @{
                case = 'Minimal object (long)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = 5368709120
                }
            }
            @{
                case = 'Single disk, no system (string)'
                obj  = @{
                    VMName = 'test' # Mandatory
                    Disks  = @(
                        @{
                            Size = '15GB'
                        }
                    )
                }
            }
            @{
                case = 'Single disk (string)'
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
                case = 'Multiple disks (string)'
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
            }
        )

        It 'Converts single value to one disk' {
            $obj = @{
                VMName = 'test' # Mandatory
                Disks  = '10GB'
            }
            $result = $obj | ParseOrder
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

            $result = $obj | ParseOrder
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

            { $obj | ParseOrder } | Should -Throw "only one"
        }

        It 'Is array - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | ParseOrder
            $result.Disks | Should -BeOfType [System.Collections.Hashtable]
        }

        It 'Adds missing properties - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | ParseOrder

            foreach ($disk in $result.Disks)
            {
                $missingKeys = @('System', 'Name', 'Size').Where{ $_ -notin $disk.Keys }
                $missingKeys -join ', ' | Should -BeNullOrEmpty
            }
        }

        It 'Ensures .Size is [long] - <case>' -TestCases $diskTestCases {
            param($obj)
            $result = $obj | ParseOrder

            foreach ($disk in $result.Disks)
            {
                $disk.Size | Should -BeOfType [long]
            }
        }
    }

    Context 'Image' {
        It 'Ensures .Image is "None" if no key specified' {
            $result = @{
                VMName = 'test'
            } | ParseOrder

            $result.Image | Should -Be 'None'
        }

        It 'Passes thru value if Image-key is given' {
            $result = @{
                VMName = 'test'
                Image  = 'Ubuntu/Bionic'
            } | ParseOrder

            $result.Image | Should -Be 'Ubuntu/Bionic'
        }
    }

    Context 'Network' {
        It 'Converts string to Switch with no VLAN set' {
            $result = @{
                VMName  = 'Test'
                Network = 'Switch-Name'
            } | ParseOrder

            $result.Network.Switch | Should -Be 'Switch-Name'
            $result.Network.Vlan | Should -Be $false
        }

        It 'Adds missing VLAN property' {
            $result = @{
                VMName  = 'Test'
                Network = @{
                    Switch = 'Switch-Name'
                }
            } | ParseOrder

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

            { $testInput | ParseOrder } | Should -Throw 'Switch'
        }
    }
}
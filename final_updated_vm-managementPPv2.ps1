# Prompt for vCenter Server and Username
$vCenterServer = Read-Host "Enter vCenter Server"
$username = Read-Host "Enter Username"

# Prompt for Password as SecureString
$password = Read-Host -Prompt "Enter Password" -AsSecureString

# Convert SecureString to plain text
$plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Connect to vCenter Server
Connect-VIServer -Server $vCenterServer -User $username -Password $plaintextPassword

# Main menu for user actions
do {
    Write-Host "Choose an action:"
    Write-Host "1. Get VM Information"
    Write-Host "2. Create Snapshot"
    Write-Host "3. Delete Snapshot"
    Write-Host "4. Gracefully Shutdown VM"
    Write-Host "5. Restart VM"
    Write-Host "6. Export VM"
    Write-Host "7. Power On VM"
    Write-Host "8. Export Multiple VMs Sequentially"
    Write-Host "9. Exit"
    $action = Read-Host "Enter your choice (1-9)"

    switch ($action) {
        "1" {
            $DCL = Get-VM -Server $vCenterServer | Select-Object -Property Name, PowerState, NumCPUs, MemoryGB
            $DCL
        }
        "2" {
            $vmName = Read-Host "Enter the name of the VM for snapshot creation"
            $snapshotName = Read-Host "Enter a name for the new snapshot"
            New-Snapshot -VM $vmName -Name $snapshotName
            Write-Host "Snapshot created successfully."
        }
        "3" {
            $vmName = Read-Host "Enter the name of the VM to delete its snapshot"
            $snapshot = Get-Snapshot -VM $vmName
            $task = Remove-Snapshot -Snapshot $snapshot -Confirm:$false -RunAsync
            $task | Wait-Task
            Write-Host "Snapshot deleted successfully."
        }
        "4" {
            $vmName = Read-Host "Enter the name of the VM to shutdown gracefully"
            Get-VM -Name $vmName | Shutdown-VMGuest -Confirm:$false
            Write-Host "VM is shutting down gracefully."
        }
        "5" {
            $vmName = Read-Host "Enter the name of the VM to restart"
            Restart-VMGuest -VM $vmName -Confirm:$false
            Write-Host "VM is restarting."
        }
        "6" {
            $vmName = Read-Host "Enter the name of the VM to export"
            $destination = Read-Host "Enter Destination of export"
            $format = Read-Host "Enter export format (OVA or OVF)"
            Get-VM -Name $vmName | Export-VApp -Destination $destination -Format $format
            Write-Host "VM exported successfully in $format format."
        }
        "7" {
            $vmName = Read-Host "Enter the name of the VM to power on"
            Start-VM -VM $vmName -Confirm:$false
            Write-Host "VM is powering on."
        }
        "8" {
            # Prompt for list of VMs to export
            $vmListInput = Read-Host "Enter the names of the VMs to export, separated by commas"
            $vmList = $vmListInput -split ","
            # Prompt for the destination path for exports
            $destinationPath = Read-Host "Enter the destination path for exports"

            # Prompt for export format
            $format = Read-Host "Enter export format for all VMs (OVA or OVF)"

            foreach ($vm in $vmList) {
                Write-Host "Starting export for VM: $vm"
                $task = Get-VM -Name $vm | Export-VApp -Destination $destinationPath -Format $format -RunAsync
                $task | Wait-Task
                Write-Host "Exported VM: $vm to $destinationPath in $format format."
            }
            Write-Host "All VMs have been exported in $format format."
        }
        "9" {
            Write-Host "Exiting..."
            break
        }
        default {
            Write-Host "Invalid choice, please try again."
        }
    }
} while ($action -ne "9")

# Disconnect from vCenter Server
Disconnect-VIServer -Confirm:$false

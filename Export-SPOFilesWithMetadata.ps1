# --------------------------------------------

# CONFIGURATION

# --------------------------------------------

$siteUrl = "https://yourtenant.sharepoint.com/sites/YourSite"

$library = "DocumentsSM"

$exportPath = "D:\Migration\Export"
 
# --------------------------------------------

# CONNECT TO SHAREPOINT ONLINE

# --------------------------------------------

Connect-PnPOnline -Url $siteUrl -Interactive -ClientId xxxxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
 
# Create local export path if it doesn't exist

if (!(Test-Path -Path $exportPath)) {

    New-Item -ItemType Directory -Path $exportPath -Force | Out-Null

}
 
# --------------------------------------------

# GET ALL FIELDS (INCLUDING CUSTOM COLUMNS)

# --------------------------------------------

$list = Get-PnPList -Identity $library

$fieldInternalNames = Get-PnPField -List $list.Id | Where-Object { $_.Hidden -eq $false } | Select-Object -ExpandProperty InternalName
 
# --------------------------------------------

# GET ALL ITEMS FROM THE LIBRARY

# --------------------------------------------

$items = Get-PnPListItem -List $library -PageSize 1000 -Fields $fieldInternalNames
 
foreach ($item in $items) {

    $fileRef = $item["FileRef"]

    $fileName = $item["FileLeafRef"]
 
    # Skip folders

    if ($fileRef.EndsWith("/")) { continue }
 
    # --------------------------------------------

    # BUILD RELATIVE PATH (MAINTAINING LIBRARY FOLDER STRUCTURE)

    # --------------------------------------------

    # Trim to relative folder path under the document library

    $relativeFilePath = $fileRef -replace "^/sites/[^/]+/[^/]+/[^/]+/", ""

    $relativeFolder = Split-Path $relativeFilePath -Parent

    $localFolderPath = Join-Path -Path $exportPath -ChildPath $relativeFolder
 
    # Create folder if it doesn't exist

    if (!(Test-Path -Path $localFolderPath)) {

        New-Item -ItemType Directory -Path $localFolderPath -Force | Out-Null

    }
 
    # Full path to local file

    $localFilePath = Join-Path -Path $localFolderPath -ChildPath $fileName
 
    # --------------------------------------------

    # DOWNLOAD FILE

    # --------------------------------------------

    Get-PnPFile -Url $fileRef -Path $localFolderPath -FileName $fileName -AsFile -Force
 
    # --------------------------------------------

    # EXPORT METADATA

    # --------------------------------------------

    $metadata = @{}

    foreach ($field in $fieldInternalNames) {

        try {

            $value = $item[$field]
 
            # Handle user fields

            if ($value -is [Microsoft.SharePoint.Client.FieldUserValue]) {

                $metadata[$field] = $value.Email

            } elseif ($value -is [System.Collections.ObjectModel.Collection[Microsoft.SharePoint.Client.FieldUserValue]]) {

                $metadata[$field] = ($value | ForEach-Object { $_.Email }) -join "; "

            } else {

                $metadata[$field] = $value

            }

        } catch {

            $metadata[$field] = $null

        }

    }
 
    # Save metadata as JSON next to the file

    $jsonPath = "$localFilePath.metadata.json"

    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
 
    Write-Host "Exported: $relativeFilePath"

}

 
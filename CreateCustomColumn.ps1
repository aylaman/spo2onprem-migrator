# ------------------------

# CONFIGURATION

# ------------------------

$siteUrl = "https://yourtenant.sharepoint.com/sites/YourSite"

$documentLibrary = "Documents"

$localPath = "D:\Migration"
 
# ------------------------

# CONNECT TO SHAREPOINT 2019

# ------------------------

Import-Module SharePointPnPPowerShell2019

$creds = Get-Credential

Connect-PnPOnline -Url $siteUrl -Credentials $creds
 
# ------------------------

# DEFINE FIELDS TO CREATE

# ------------------------

$fieldsToCreate = @(

    @{ Name = "CustomColumn1"; DisplayName = "CustomColumn1"; Type = "Text" },

    @{ Name = "CustomColumn2; DisplayName = "CustomColumn2"; Type = "Text" },

	@{ Name = "CustomColumn3"; DisplayName = "CustomColumn3"; Type = "Text" },
)
 
# ------------------------

# CREATE FIELDS IF MISSING

# ------------------------

foreach ($field in $fieldsToCreate) {

    $existingField = Get-PnPField -List $documentLibrary -Identity $field.Name -ErrorAction SilentlyContinue
 
    if (-not $existingField) {

        Write-Host "Creating column: $($field.DisplayName) [$($field.Type)]"
 
        switch ($field.Type) {

            "Text" {

                Add-PnPField -List $documentLibrary -InternalName $field.Name -DisplayName $field.DisplayName -Type Text

            }

            "User" {

                Add-PnPField -List $documentLibrary -InternalName $field.Name -DisplayName $field.DisplayName -Type User

            }

            "URL" {

                Add-PnPField -List $documentLibrary -InternalName $field.Name -DisplayName $field.DisplayName -Type URL

            }

            default {

                Write-Warning "Unsupported field type: $($field.Type)"

            }

        }

    }

    else {

        Write-Host "Column already exists: $($field.Name)" -ForegroundColor Yellow

    }

}

 
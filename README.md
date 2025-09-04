# spo2onprem-migrator
A collection of PowerShell scripts to export files and metadata with custom columns from SharePoint Online and import them into SharePoint on-premises.

## Features

- Export documents and metadata (including custom fields) from SharePoint Online
- Import files into SharePoint On-Prem document libraries
- Supports batch processing and large data volumes
- Minimal dependencies – built using native PowerShell and SharePoint modules

## Prerequisites

### For Exporting from SharePoint Online
- PowerShell 5.1 or PowerShell 7+
- [PnP PowerShell Module](https://pnp.github.io/powershell/)  
  Install with:
  ```powershell
  Install-Module -Name "PnP.PowerShell"
- The user running the script must have Contribute or higher permissions on the library

### For Importing to SharePoint On-premises
- Windows PowerShell 5.1 (PnP PowerShell 2019 is not compatible with PowerShell Core / 7+)
- SharePointPnPPowerShell2019 module
  Install with:
  ```powershell
  Install-Module -Name SharePointPnPPowerShell2019
- The user running the script must have Contribute or higher permissions on the target library

### Script Overview
Script	Description
Export-SPOFilesWithMetadata.ps1	Exports files and metadata from a SharePoint Online document library
Import-SPOnPremFilesWithMetadata.ps1	Imports the exported files and metadata into a SharePoint On-Prem library
CreateCustomColumn.ps1	(Optional but Recommended)) Creating custom columns in target document library

### How to Use
Step 1: Export from SharePoint Online
Use PowerShell 7+ with pnp module
.\Export-SPOFilesWithMetadata.ps1 `
    -SiteUrl "https://yourtenant.sharepoint.com/sites/YourSite" `
    -LibraryName "Documents" `
    -OutputFolder "C:\Migration\Export" `
    -IncludeCustomColumns $true
    
Step 2: (Optional but Recommended)) Creating custom columns in target document library
Use PowerShell 5.1
.\CreateCustomColumn.ps1 `
    -SiteUrl "https://yourtenant.sharepoint.com/sites/YourSite" `
    -LibraryName "Documents" `
    -OutputFolder "C:\Migration

Step 3: Import to SharePoint On-Prem
Use PowerShell 5.1 with SharePointPnPPowerShell2019 module
.\Import-SPOnPremFilesWithMetadata.ps1 `
    -SiteUrl "http://your-onprem-server/sites/TargetSite" `
    -LibraryName "Documents" `
    -InputFolder "C:\Migration\Export" `
    -PreserveMetadata $true

### FAQ
Q: Can I migrate version history?
A: Not currently supported, but can be extended with additional scripting logic.

Q: Are lookup or people fields supported?
A: Yes, but they may require mapping to match user or lookup values between environments.

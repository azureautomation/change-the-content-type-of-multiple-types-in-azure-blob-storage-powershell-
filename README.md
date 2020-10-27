Change the content type of multiple types in Azure blob storage(PowerShell)
===========================================================================

            
Change the content type of multiple types in Azure blob storage(PowerShell)

 

Introduction

 This powershell script changes the content type of multiple files or single file located
 in an Azure Blob storage to different content types depending on their extension and the rules set in the script. The script also has paging of results and continuation token if the script times our or an error occurs.


 This is a modification of the script posted by OneScript Team:
[https://gallery.technet.microsoft.com/scriptcenter/How-to-batch-change-the-47e310b4](https://gallery.technet.microsoft.com/scriptcenter/How-to-batch-change-the-47e310b4)


 

Scenarios

You want to change the content type of multiple files located in a blob to different content types based on their extentions.


 

Tested

The script was tested on two diffrent storage containers containing a total of 7.3 millions blobs (files) each with diffrent file formats.


In our case it was a blob full of images that we needed to change the content type depending on their extension, and because there was 7 million of them it took 48 hours per container.


 

Notes

  *  If Windows Azure PowerShell is not installed, see Getting Started with Windows Azure PowerShell Cmdlets for installation and configuration
 information 
  *  Please create the log directory before running the script 
  *  If you have set a default storage account please note this script can't change that and the operation will be executed against it and not the one you give the script, i recommend you set the account before running the script with



PowerShell
Edit|Remove
powershell
Set-AzureSubscription –SubscriptionName 'My Azure Subscription' –CurrentStorageAccountName 'My storage account name' 

Set-AzureSubscription –SubscriptionName 'My Azure Subscription' –CurrentStorageAccountName 'My storage account name' 




**Note:** You also need the sdk wich inlcudes the Microsoft.WindowsAzure.Storage.dll and then modify the location in the script



PowerShell
Edit|Remove
powershell
      #Specify a Windows Azure Storage Library path
            $StorageLibraryPath = '$env:SystemDrive\Program Files\Microsoft SDKs\Azure\.NET SDK\v2.6\ToolsRef\Microsoft.WindowsAzure.Storage.dll'

      #Specify a Windows Azure Storage Library path 
            $StorageLibraryPath = '$env:SystemDrive\Program Files\Microsoft SDKs\Azure\.NET SDK\v2.6\ToolsRef\Microsoft.WindowsAzure.Storage.dll'




 

Features

  *  Ability to specify different content type for different files (just edit the switch statement to include your own)

  *  Results paging (results are grouped and paged as with so many image in the tested scenarios azure powershell can't cope with all at once and crashes, we found that 10 000 per group works well but you can lower that number by changing the $MaxReturn value
 in the script) 
  *  Continuation with token found in the log file after each group of results (you can specify a token in the script and continue from where you left off, in the event of an error which we actually got as we used Add-AzureAccount which times out after 24 hours,
 so for long runs please use the certificate option for the azure PowerShell, all you need to do is uncomment the token being set in the script and substitute with the one from the log file) 



PowerShell
Edit|Remove
powershell
                $Token = $NULL
                # Comment above line '$Token = $NULL' and uncomment the bellow 3 to start processing from  where you leftoff/crashed, just change the marker with the last one in the last log
                #$Token = @{}
                #$Token.nextmarker = '2!132!MDAwMDU0IVNvbmV0dG9JbWFnZXMvUHJvZHVjdC8yLzEvMjExMDE1LTg'
                #$Token.targetLocation = 'Primary'

                $Token = $NULL 
                # Comment above line '$Token = $NULL' and uncomment the bellow 3 to start processing from  where you leftoff/crashed, just change the marker with the last one in the last log 
                #$Token = @{} 
                #$Token.nextmarker = '2!132!MDAwMDU0IVNvbmV0dG9JbWFnZXMvUHJvZHVjdC8yLzEvMjExMDE1LTg' 
                #$Token.targetLocation = 'Primary'




  *  Logging (a new log file is generated for every 10 groups or 100 000 results by default if you have left the MaxReturn as is, you can change that by modifying: If($LogCount -eq 10))


 

Usage

PS C:\> .\ChangeAzureBlobContentType.ps1 -StorageAccountName 'images' -ContainerName 'media' -LL 'C:\AZlogs'


 

Example

Powershell:



![Image](https://github.com/azureautomation/change-the-content-type-of-multiple-types-in-azure-blob-storage(powershell)/raw/master/a1.png)



Log file directory:


![Image](https://github.com/azureautomation/change-the-content-type-of-multiple-types-in-azure-blob-storage(powershell)/raw/master/a3.png)


Log File with continuation token:


 


![Image](https://github.com/azureautomation/change-the-content-type-of-multiple-types-in-azure-blob-storage(powershell)/raw/master/a2.png)


 


 

Code Sniplet


PowerShell
Edit|Remove
powershell
Function ChangeBlobContentType
    {
        Param
        (
            [String]$ContainerName,
            [String]$BlobName,
            [String]$Logfile
        )

        Add-content $Logfile -value 'Getting the container object named $ContainerName.'
        $BlobContainer = $CloudBlobClient.GetContainerReference($ContainerName)

        Add-content $Logfile -value 'Getting the blob object named $BlobName.'
        $Blob = $BlobContainer.GetBlockBlobReference($BlobName)
        Try
        {
            $blobext = [System.IO.Path]::GetExtension($Blob.Uri.AbsoluteUri)
            $blobext = $blobext.ToLower()

            #You can add or remove more content typs if need be, the defult of none makes sure that nothing get's changed if extension is not matched
            switch ($blobext) 
             { 
                '.jpg' {$Blobctype = 'image/jpeg'} 
                '.jpeg' {$Blobctype = 'image/jpeg'}
                '.jpe' {$Blobctype = 'image/jpeg'}
                '.gif' {$Blobctype = 'image/gif'}
                '.png' {$Blobctype = 'image/png'}
                default {$Blobctype = 'none'}
      
             }
             if($Blobctype -ne 'none'){

                $Blob.Properties.ContentType = $Blobctype
                $Blob.SetProperties()
                Add-content $Logfile -value 'Successfully changed content type of '$BlobName' to '$Blobctype'.'
            }Else{

                Add-content $Logfile -value ''$BlobName' - Type not found nothing changed'
            }
         
        }
        Catch
        {
            Add-content $Logfile -value 'Failed to change content type of '$BlobName'.'
        }



Function ChangeBlobContentType 
    { 
        Param 
        ( 
            [String]$ContainerName, 
            [String]$BlobName, 
            [String]$Logfile 
        ) 
 
        Add-content $Logfile -value 'Getting the container object named $ContainerName.' 
        $BlobContainer = $CloudBlobClient.GetContainerReference($ContainerName) 
 
        Add-content $Logfile -value 'Getting the blob object named $BlobName.' 
        $Blob = $BlobContainer.GetBlockBlobReference($BlobName) 
        Try 
        { 
            $blobext = [System.IO.Path]::GetExtension($Blob.Uri.AbsoluteUri) 
            $blobext = $blobext.ToLower() 
 
            #You can add or remove more content typs if need be, the defult of none makes sure that nothing get's changed if extension is not matched 
            switch ($blobext)  
             {  
                '.jpg' {$Blobctype = 'image/jpeg'}  
                '.jpeg' {$Blobctype = 'image/jpeg'} 
                '.jpe' {$Blobctype = 'image/jpeg'} 
                '.gif' {$Blobctype = 'image/gif'} 
                '.png' {$Blobctype = 'image/png'} 
                default {$Blobctype = 'none'} 
       
             } 
             if($Blobctype -ne 'none'){ 
 
                $Blob.Properties.ContentType = $Blobctype 
                $Blob.SetProperties() 
                Add-content $Logfile -value 'Successfully changed content type of '$BlobName' to '$Blobctype'.' 
            }Else{ 
 
                Add-content $Logfile -value ''$BlobName' - Type not found nothing changed' 
            } 
          
        } 
        Catch 
        { 
            Add-content $Logfile -value 'Failed to change content type of '$BlobName'.' 
        } 
 





 




        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.

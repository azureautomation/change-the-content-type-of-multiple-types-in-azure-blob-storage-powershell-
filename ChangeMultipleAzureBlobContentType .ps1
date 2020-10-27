#--------------------------------------------------------------------------------- 
#The sample scripts are not supported under any Microsoft standard support 
#program or service. The sample scripts are provided AS IS without warranty  
#of any kind. Microsoft further disclaims all implied warranties including,  
#without limitation, any implied warranties of merchantability or of fitness for 
#a particular purpose. The entire risk arising out of the use or performance of  
#the sample scripts and documentation remains with you. In no event shall 
#Microsoft, its authors, or anyone else involved in the creation, production, or 
#delivery of the scripts be liable for any damages whatsoever (including, 
#without limitation, damages for loss of business profits, business interruption, 
#loss of business information, or other pecuniary loss) arising out of the use 
#of or inability to use the sample scripts or documentation, even if Microsoft 
#has been advised of the possibility of such damages 
#--------------------------------------------------------------------------------- 

#requires -Version 3.0

<#
 	.SYNOPSIS
       This script can be used to change the content type of multiple/single file/s.                               .
    .DESCRIPTION
       This script is designed to change the content type of multiple/single file/s located in an Azure container
    .PARAMETER  ContainerName
		Specifies the name of container.
	.PARAMETER	BlobName
		Specifies the name of blob. It is not required, if the name of blob is not specified, this will changes the content 
        type of all blob items in the sepcified container and in all child container.
	.PARAMETER  StorageAccountName
		Specifies the name of the storage account to be connected.
	.PARAMETER  LogLoc
		Specifies a folder where the log files are going to be saved (it must already exists) 
	.EXAMPLE
        C:\PS> C:\Script\ChangeMultipleAzureBlobContentType.ps1  -StorageAccountName "AzureStorage01" -ContainerName "pics" -LogLoc "C:\Azlogs"

#>
[CmdletBinding(SupportsShouldProcess = $true)]

Param
(
    [Parameter(Mandatory = $true)]
    [Alias('CN')]
    [String]$ContainerName,
    [Parameter(Mandatory = $false)]
    [Alias('BN')]
    [String]$BlobName,
    [Parameter(Mandatory = $true)]
    [Alias('SN')]
    [String]$StorageAccountName,
    [Parameter(Mandatory = $true)]
    [Alias('LL')]
    [String]$LogLoc
)

#Check if Windows Azure PowerShell Module is avaliable
If((Get-Module -ListAvailable Azure) -eq $null)
{
    Write-Warning "Windows Azure PowerShell module not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools"
}
Else
{

    Function ChangeBlobContentType
    {
        Param
        (
            [String]$ContainerName,
            [String]$BlobName,
            [String]$Logfile
        )

        Add-content $Logfile -value "Getting the container object named $ContainerName."
        $BlobContainer = $CloudBlobClient.GetContainerReference($ContainerName)

        Add-content $Logfile -value "Getting the blob object named $BlobName."
        $Blob = $BlobContainer.GetBlockBlobReference($BlobName)
        Try
        {
            $blobext = [System.IO.Path]::GetExtension($Blob.Uri.AbsoluteUri)
            $blobext = $blobext.ToLower()

            #You can add or remove more content typs if need be, the defult of none makes sure that nothing get's changed if extension is not matched
            switch ($blobext) 
             { 
                ".jpg" {$Blobctype = "image/jpeg"} 
                ".jpeg" {$Blobctype = "image/jpeg"}
                ".jpe" {$Blobctype = "image/jpeg"}
                ".gif" {$Blobctype = "image/gif"}
                ".png" {$Blobctype = "image/png"}
                default {$Blobctype = "none"}
      
             }
             if($Blobctype -ne "none"){

                $Blob.Properties.ContentType = $Blobctype
                $Blob.SetProperties()
                Add-content $Logfile -value "Successfully changed content type of '$BlobName' to '$Blobctype'."
            }Else{

                Add-content $Logfile -value "'$BlobName' - Type not found nothing changed"
            }
         
        }
        Catch
        {
            Add-content $Logfile -value "Failed to change content type of '$BlobName'."
        }
    }

    If($StorageAccountName)
    {
        Get-AzureStorageAccount -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue `
        -ErrorVariable IsExistStorageError | Out-Null
        #Check if storage account is exist
        If($IsExistStorageError.Exception -eq $null)
        {
            #Specify a Windows Azure Storage Library path
            $StorageLibraryPath = "$env:SystemDrive\Program Files\Microsoft SDKs\Azure\.NET SDK\v2.6\ToolsRef\Microsoft.WindowsAzure.Storage.dll"

            #Getting Azure storage account key
            $Keys = Get-AzureStorageKey -StorageAccountName $StorageAccountName
            $StorageAccountKey = $Keys[0].Primary

            #Loading Windows Azure Storage Library for .NET.
            Write-Output -Message "Loading Windows Azure Storage Library from $StorageLibraryPath"
            [Reflection.Assembly]::LoadFile("$StorageLibraryPath") | Out-Null

            $Creds = New-Object Microsoft.WindowsAzure.Storage.Auth.StorageCredentials("$StorageAccountName","$StorageAccountKey")
            $CloudStorageAccount = New-Object Microsoft.WindowsAzure.Storage.CloudStorageAccount($creds, $true)
            $CloudBlobClient = $CloudStorageAccount.CreateCloudBlobClient()
        }
        Else
        {
            Write-Warning "Cannot find storage account '$StorageAccountName' because it does not exist. Please make sure thar the name of storage is correct."
        }
    }

    If($ContainerName)
    {
        Get-AzureStorageContainer -Name $ContainerName -ErrorAction SilentlyContinue `
        -ErrorVariable IsExistContainerError | Out-Null
        #Check if container is exist
        If($IsExistContainerError.Exception -eq $null)
        {
            If($BlobName)
            {
                Get-AzureStorageBlob -Container $ContainerName -Blob $BlobName -ErrorAction SilentlyContinue `
                -ErrorVariable IsExistBlobError | Out-Null
                 #Check if blob is exist
                If($IsExistBlobError.Exception -eq $null)
                {
                    #user specifiy a name of blob, the script will change the content type of specified blob only.
                    If($PSCmdlet.ShouldProcess("$BlobName","Change the content type"))
                    {
                        ChangeBlobContentType -ContainerName $ContainerName -BlobName $BlobName -Logfile "$LogLoc\LogB1.txt"
                    }
                }
                Else
                {
                    Write-Warning "Cannot find blob '$BlobName' because it does not exist. Please make sure thar the name of blob is correct."
                }
            }
            Else
            {
                
                $Total = 0
                $Token = $NULL
                # Comment above line "$Token = $NULL" and uncomment the bellow 3 to start processing from  where you leftoff/crashed, just change the marker with the last one in the last log
                #$Token = @{}
                #$Token.nextmarker = "2!132!MDAwMDU0IVNvbmV0dG9JbWFnZXMvUHJvZHVjdC8yLzEvMjExMDE1LTg"
                #$Token.targetLocation = "Primary"

                #Results are grouped in 10 000 (this number works very well with azure)
                $MaxReturn = 10000
                $LogFileNumber = 0
                $LogCount = 0
                $Logfile = "$LogLoc\LogC$LogFileNumber.txt"
                do
                {

                    #10 groups per log file so in our case 100 000 resutls in a log file wich keeps it at 25mb per log file
                    If($LogCount -eq 10)
                    {
                        $LogFileNumber = $LogFileNumber + 1
                        $Logfile = "$LogLoc\LogC$LogFileNumber.txt"
                        $LogCount = 0
                    }else{
                        $LogCount = $LogCount + 1
                    }

                    $BlobItems = Get-AzureStorageBlob -Container $ContainerName -MaxCount $MaxReturn  -ContinuationToken $Token
                    Foreach($BlobItem in $BlobItems)
                    {
                        $BlobN = $BlobItem.Name
                        If($PSCmdlet.ShouldProcess("$BlobN","Change the content type"))
                        {
                            ChangeBlobContentType -ContainerName $ContainerName -BlobName $BlobN -Logfile $Logfile
                        }
                    } 
                    $Total += $BlobItems.Count
                    if($BlobItems.Length -le 0) { Break;}
                    $Token = $BlobItems[$BlobItems.Count -1].ContinuationToken;
                    $tokenm = $Token.nextmarker
                    $tokenl = $Token.targetLocation
                    Add-content $Logfile -value "Token Market: $tokenm"
                    Add-content $Logfile -value "Token Location: $tokenl"
                }
                While ($Token -ne $Null) 
            }
        }
        Else
        {
            Write-Warning "Cannot find container '$ContainerName' because it does not exist. Please make sure thar the name of container is correct."
        }
    }
}
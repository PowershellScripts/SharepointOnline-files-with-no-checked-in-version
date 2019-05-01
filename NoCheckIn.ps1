function Get-SPOFolderFiles
{
param (
        [Parameter(Mandatory=$true,Position=1)]
		[string]$Username,
		[Parameter(Mandatory=$true,Position=2)]
		[string]$Url,
        [Parameter(Mandatory=$true,Position=3)]
		$password,
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=5)]
		[string]$CheckInComment
		)


  $ctx=New-Object Microsoft.SharePoint.Client.ClientContext($Url)
  $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $password)
  $ctx.Load($ctx.Web)
  $ctx.ExecuteQuery()
  $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
  $ctx.Load($ll)
  $ctx.ExecuteQuery()
  $NumberOfItemsInTheList=$ll.ItemCount
  $itemki=@()
  $spqQuery = New-Object Microsoft.SharePoint.Client.CamlQuery  
  $spqQuery.ViewXml ="<View Scope='RecursiveAll' />";
  $ViewThreshold=4000

  if($NumberOfItemsInTheList -gt $ViewThreshold)
  {
    [decimal]$NoOfRuns=($NumberOfItemsInTheList/$ViewThreshold)
    $NoOfRuns=[math]::Ceiling($NoOfRuns)

    for($WhichRun=0; $WhichRun -lt $NoOfRuns; $WhichRun++)
    {
        $startIndex=$WhichRun*$ViewThreshold
        $endIndex=$startIndex+$ViewThreshold      
        $spqQuery.ViewXml="<View Scope='RecursiveAll'><Query><Where><And>"+
		    "<Geq><FieldRef Name='ID'></FieldRef><Value Type='Number'>"+$startIndex+"</Value></Geq>"+
			"<Lt><FieldRef Name='ID'></FieldRef><Value Type='Number'>"+$endIndex+"</Value></Lt>"+
		  "</And></Where></Query></View>"
       

        Write-Host $spqQuery.ViewXml
        $partialItems=$ll.GetItems($spqQuery)
        $ctx.Load($partialItems)
        $ctx.ExecuteQuery()

        foreach($partialItem in $partialItems)
        {
            $itemki+=$partialItem
        }
    }
  }
  else
  {
    $itemki=$ll.GetItems($spqQuery)
    $ctx.Load($itemki)
    $ctx.ExecuteQuery()
  }


  foreach($item in $itemki)
  {

    Write-Host "Verifying " $item["FileRef"] $item.ElementType "..."
  
  $file =
        $ctx.Web.GetFileByServerRelativeUrl($item["FileRef"]);
        $ctx.Load($file)
        $ctx.Load($file.Versions)             
        $ctx.Load($file.ListItemAllFields)

        $Author=$file.Author
        $CheckedOutByUser=$file.CheckedOutByUser
        $LockedByUser=$file.LockedByUser
        $ModifiedBy=$file.ModifiedBy
        $ctx.Load($Author)
        $ctx.Load($CheckedOutByUser)
        $ctx.Load($LockedByUser)
        $ctx.Load($ModifiedBy)
        $ctx.Load($file.EffectiveInformationRightsManagementSettings)
        $ctx.Load($file.Properties)
        $ctx.Load($file.VersionEvents)

        try
        {
            $ctx.ExecuteQuery()
        }
        catch
        {
            #Do nothing
        }
       
       if(($CheckedOutByUser.LoginName -ne $null) -and ($file.Versions.Count -eq 0))
       {
            Write-Host $file.Name "was created by" $CheckedOutByUser.LoginName "and doesn't have any checked-in versions"

        #  $file.CheckIn($CheckInComment, 'MajorCheckIn')
            $ctx.Load($file)

            try
            {
                $ctx.ExecuteQuery()        
                Write-Host $file.Name " has been checked in"     -ForegroundColor DarkGreen 
            }
            catch [Net.WebException]
            { 
                Write-Host $_.Exception.ToString()
            }
       
        }
        

        
     }   
  }



$AdminPassword=Read-Host -Prompt "Enter password" -AsSecureString       


#Paths to SDK
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"  
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"  

#Enter the data
$username="test@tenant.onmicrosoft.com"
$Url="https://tenant.sharepoint.com/sites/test"
$ListTitle="noci"
$CheckinComment="Checked in automatically"

Get-SPOFolderFiles -Username $username -Url $Url -password $AdminPassword -ListTitle $ListTitle -CheckInComment $CheckinComment

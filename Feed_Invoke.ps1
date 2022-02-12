#####################################
##  Future state
##  . 'I:\RSS_Project\Get-InitialTitles.ps1'

Function Get-WordCount($anyposts)
{

    $titlestring = $anyposts.title -join ' '
    $titlestring = $titlestring.split(' ')

    $CleanList =@('a','after','an','and','as','at','for','from','I','in','into','is','have', 'has','her','him','man', 'on','of','s','t','to','the','with','woman','')
    $dirtylaundryterms = @('accident','armed','arrest', 'arrested','collision','crash','DUI','fatal','hit-and-run','homicide','police','sheriff','shooting','shot','suspects','Sutter','victim')
    
    $frequency = $titlestring -split '\W+' |
    Group-Object -NoElement |
    Sort-Object count -Descending | 
    Where-Object {$_.name -notin $CleanList -and $_.name -notin $dirtylaundryterms} |
    Where-Object{$_.count -gt 2} | Select-Object 

    return $frequency
}


Function Get-SimTitles([psobject]$NewPosts) {

  $i=0
  $end = $NewPosts.Count - 1
  write-host 'starting'

 
  For($i =0; $i -lt $end; $i++){
    
      $k=$i+1        
      $k..$end | Where{{$NewPosts[$i].source -ne $NewPosts[$_].source}} |
      Where-Object {(Measure-TitleSimilarity $NewPosts[$i].title.split(' ') $NewPosts[$_].title.split(' ')) -gt .35}  |
       & {process {$NewPosts[$_].SimTitles = $NewPosts[$_].SimTitles + 1; $NewPosts[$i].SimTitles+=1} }
            } 
                       
 }  
  
 
Function Get-PostCount([psobject]$anyposts)
{ 
        $apcount = $anyposts.count
        return $apcount
}
Function Get-NullPost([psobject]$anyposts)
{
    $strDate=Get-Date -Format "MM-dd-yyyy HH:mm tt"
    $emptypost = @{
                    title = '-'
                    description = '-'
                    link = '-'
                    pubDate = $strDate
                    pullDate = $strDate
                    source = '-'
                    SimTitles = 0
                    }
    return $emptypost

}
Function Convert-Links($anyHTML, $POEmail, $POData)
{
    $result = $anyHTML -replace '<tr><td>(?<title>[^\<]+)<\/td><td>(?<desc>[^\<]+)<\/td><td>(?<weblink>[^\<]+)\<\/td><td>(?<pubDate>[^\<]+)', `
    ('<tr><td>${title}</td><td>${desc}</td><td><a href="${weblink}">Full_Story_Click_Here</a><br><a href='+$POEmail+'${weblink}%0D%0A%0D%0ATitle: ${title}%0D%0ADescription: %0D%0APublished on: ${pubDate}%0D%0A'`
    + $POData + '>Send to PO</a></td><td>${pubDate}</td>')

    return $result

}
Function Measure-TitleSimilarity
{
## Based on VectorSimilarity by .AUTHOR Lee Holmes 
## Modified slightly to match use

[CmdletBinding()]
param(
    
    [Parameter(Position = 0)]
    $Title1,

    [Parameter(Position = 1)]   
    $Title2
    
        
) 

$allkeys = @($Title1) + @($Title2) |  Sort-Object -Unique

$set1Hash = @{}
$set2Hash = @{}
$setsToProcess = @($Title1, $Set1Hash), @($Title2, $Set2Hash)

foreach($set in $setsToProcess)
{
    $set[0] | Foreach-Object {
         $value = 1 
         $set[1][$_] = $value
    }
}

$dot = 0
$mag1 = 0
$mag2 = 0

foreach($key in $allkeys)
{
    $dot += $set1Hash[$key] * $set2Hash[$key]
    $mag1 +=  ($set1Hash[$key] * $set1Hash[$key])
    $mag2 +=  ($set2Hash[$key] * $set2Hash[$key])
}

$mag1 = [Math]::Sqrt($mag1)
$mag2 = [Math]::Sqrt($mag2)

return [Math]::Round($dot / ($mag1 * $mag2), 3)
}

Function Get-Posts ($anyXMLfeed, $anyname)
{ $fields = 'title','description','pubDate','link'

## Function created with major assist by Mathias R Jessen
## https://stackoverflow.com/users/712649/mathias-r-jessen
## ## Atom line
  $posts = foreach($item in $rss.SelectNodes('//item')) {
    # create dictionary to hold properties of the object we want to construct
    $properties = [ordered]@{}

    # now let's try to resolve them all
    foreach($fieldName in $fields) {
        # use a relative XPath expression to extract relevant child node from current item
        $value = $item.SelectSingleNode("./${fieldName}")

        # handle content wrapped in CData
        if($value.HasChildNodes -and $value.ChildNodes[0] -is [System.Xml.XmlCDataSection]){
            $value = $value.ChildNodes[0]
        }

        # add node value to dictionary
        $properties[$fieldName] = $value.InnerText
    }

    # output resulting object
    [pscustomobject]$properties
    
}
    $Source = 'RSS: ' + $anyname 
    $posts | Add-Member -NotePropertyName 'source' -NotePropertyValue $Source
    $posts | Add-Member -NotePropertyName 'SimTitles' -NotePropertyValue 0
    $posts | Add-Member -NotePropertyName 'PullDate' -NotePropertyValue (Get-Date).ToString("MM/dd/yyyy")
    return $posts
}

Function Get-Tweets ($anyTwitterHandle, $anyname)
{

    $Tweets = Get-TwitterStatuses_UserTimeline -screen_name $anyTwitterHandle -count 13 -tweet_mode extended | Select-Object full_text,created_at,user
    # Put in readable time format
    $Tweets | ForEach-Object {
        $_.created_at= [datetime]::ParseExact($_.created_at, "ddd MMM dd HH:mm:ss zzz yyyy", $null)
        } 
    # Add properties to match RSS feed posts
    $Source = 'Twitter: ' + $anyname
    $Tweets | Add-Member -NotePropertyName 'link' -NotePropertyValue '-'
    $Tweets | Add-Member -NotePropertyName 'source' -NotePropertyValue $Source
    $Tweets | Add-Member -NotePropertyName 'title' -NotePropertyValue '-'

    $Tweets | ForEach-Object { if($_.full_text -match '(?<weblink>\b(https:\/\/[a-zA-Z.\/0-9]*)+)') {
                                             $_.link = $Matches.weblink }} 

    $Tweets | ForEach-Object {$_.title = $_.user.name}
    # name of property and expression
    $posts = $Tweets | Select-Object -property @{Name='description'; Expression={$_.full_text}},@{Name='pubDate';Expression={$_.created_at}},`
    @{Name='title'; Expression={$_.full_text}},@{Name='link'; Expression={$_.link}},@{Name='source'; Expression={$_.source}},`
    @{Name='PullDate';Expression={(Get-Date).ToString("MM/dd/yyyy")}},@{Name='SimTitles';Expression={0}} 
                             
    return $posts
}
Function Rename-LatestNews
{
    ## Takes newest date stamped feed and copies it to unstamped RSS_Feed
    ## Deletes any date stamped feed older than 5 days
    $Path = "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\"
    $Item = Get-ChildItem -Path $Path | Where-Object {$_.Name -match 'RSS_Feed_' }| Sort-Object LastWriteTime -Descending |Select-Object -First 1
    Copy-Item $Item.FullName -Destination "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\RSS_Feed.html"
    
    ## Remove feeds older than 5 days
    Get-ChildItem -Path $Path | Where-Object {($_.Name -like 'RSS_Feed_*.html') -and ($_.LastWriteTime -lt (Get-Date).AddDays(-5))}  | Remove-Item
}
Function Reset-Authorization 
{
    Set-TwitterOAuthSettings @OAuthSettings
}

#######################################
##
##   Initialize Twitter API variables
##
#######################################

$OAuthSettings = @{
    ApiKey = $env:twApiKey
    ApiSecret = $env:twApiSecret
    AccessToken = $env:twAccessToken
    AccessTokenSecret =$env:twAccessTokenSecret
}
#Set-TwitterOAuthSettings @OAuthSettings

#######################################
##
##   Initialize variables
##
#######################################

$i = 0
$posts=@()
$filtered = @()
$filteredlocations = @()
$filteredposts = @()
$finalcut =@()
$badfeeds=@()
$dirtylaundryterms=@()
$sutterposts= @()
$medical =@()

####################################
##
##  Terms and locations for your purposes
##
####################################

$dirtylaundryterms = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\DirtyLaundryTerms.csv" |Select-Object -Property Terms
$Sutterterms = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\MedicalTerms.csv" |Select-Object -Property Sutter_Words
$medical =Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\MedicalTerms.csv" |Select-Object -Property Terms
#$cities = @('Antioch','Auburn','Brentwood','Citrus Heights','Elk Grove','Fairfield','Lodi','Oakdale','Oakland','Richmond','Rocklin','Roseville','Sacramento','San Francisco','San Jose','Stockton','Tracy','Vacaville','Vallejo','Yuba City')
$cities = Import-Csv -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\Cities.csv" | Select-Object -Property Name
$feeds = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\Feeds.csv" | Where-Object {$_.Type -eq 'RSS'}| Select-Object -Property Link, Name
$Tweeters = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\Feeds.csv" | Where-Object {$_.Type -eq 'Tweet'} |Select-Object -Property Link, Name

$feeds | Format-Table
$Tweeters | Format-Table


####################################
##
##  Save each feed in a file
##  $rss = [xml](Get-Content 'I:\RSS_Project\Feeds\feed-1.xml') from an array of files? -or
##  $rss=[xml](Invoke-WebRequest "https://sacramento.cbslocal.com/feed/")
##
####################################

foreach($feed in $feeds) {
$i++
$feed
try{
$rss=[xml](Invoke-WebRequest $feed.Link)
$posts += Get-Posts $rss $feed.Name}
catch{ write-host $feed ' - failed to pull'
    $badfeeds += $feed
}

}

foreach($Tweeter in $Tweeters){
    try{
    $posts += Get-Tweets $Tweeter.Link $Tweeter.Name
    } Catch
    { Reset-Authorization
        $posts += Get-Tweets $Tweeter.Link $Tweeter.Name
        }
}

$InitPosts = $posts.count
## replace any HTML in the XML
## \<.+?>
## $InitPosts | Where-Object {($_.description -match '<p>' -or $_.description -match '<a')} | ForEach-Object {$_.description -replace '(<.+?>)',''}| Select-Object
## $InitPosts | Where-Object { $_.description -match '\?\?\?'} | ForEach-Object {$_.description -replace '\?\?\?',"'"} | Select-Object
 
$posts | ForEach-Object {
    if ($_.description -match '<p>' ) {
        $_.description=$_.description -replace '(<.+?>)',''
    } 
    
}
$ic=[Globalization.CultureInfo]::InvariantCulture

$posts | & {process {if($_.description -match '<p>'){$_.description = $_.description -replace '(<.+?>)',''}}}
$posts | & {process {if($_.source -match 'SacBee'){$_.pubDate =$_.pubDate.replace('PST','-8')}}}
$posts | & {process {if($_.title -match '\?{3}'){$_.title = $_.title -replace '\?{3}',"'"}}}
$posts | & {process {if($_.description -match '\?{3}'){$_.description = $_.description -replace '\?{3}',"'"}}}



$posts | ForEach-Object {
    try { $_.pubDate= Get-Date $_.pubDate -Format ("MM-dd-yy hh:mm tt") }
    catch {  try{ $_.pubDate = Get-Date ($_.pubDate.replace('PST','-8')) -Format ('MM-dd-yy hh:mm tt')  }
             catch { write-host 'Unable to parse date' $_.Source }
           }
  ##'ddd dd MMM yyyy HH:mm:ss z'
   }            
    
#$posts | Format-Table
$InitPosts

####################################
##
##  Filter based on $qry terms and $Cities
##
####################################

Write-host 'Filtering terms'

foreach($term in $dirtylaundryterms.Terms){
   
    $filteredposts += $posts | Where-Object {(Get-Date $_.pubDate) -gt (Get-Date).AddDays(-4)  }|Where-Object {($_.description -match $term -or $_.Title -match $term)} |
     Where-Object{$_.description -notmatch "basketball"}
    
    }

write-host 'Filtering for Sutter terms'
foreach($term in $Sutterterms.Sutter_Words) {
    
    $Sutterposts += $posts | Where-Object {(Get-Date $_.pubDate) -gt (Get-Date).AddDays(-4)  }|Where-Object {($_.description -match $term -or $_.Title -match $term)} 

    }

    $OldPosts = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\DirtyLaundry.csv" `
    | Where-Object {(Get-Date $_.pubDate) -gt (Get-Date).AddDays(-4)  }
    #$dirtylaundry = $filteredposts | Sort-object -Unique -Property Title | Select-Object -Property title, description, link, source, SimTitles, PubDate, PullDate 
    
    $dirtylaundry = ($OldPosts + $filteredposts | Sort-object -Unique -Property Title)|Sort-Object -Unique -Property Title, pubDate, source |Select-Object -Property title, description,link,source,SimTitles,PubDate,PullDate 
    #  $NewPosts = ($OldPosts + $filteredposts | Sort-object -Unique -Property Title)|Sort-Object -Unique -Property Title, PullDate, pubDate |Select-Object -Property title, description,link,source,SimTitles,PubDate,PullDate 
    
    $dirtylaundry | & {process {$_.simTitles = 0}}

    write-host $dirtylaundry.Count '  - New posts, filtered for dirty laundry'
    
    ##Process for trending and save to dirty laundry
    write-host 'Processing Similar Titles'
    $TrendingArray=@()
    $TrendingTopics=@()
    $TrendingArray = Get-WordCount $dirtylaundry
 

    Get-SimTitles $dirtylaundry
    $dirtylaundry | Export-CSV -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\DirtyLaundry.csv"
    $TrendingTopics = $dirtylaundry | Where-Object{$_.SimTitles -gt 0} |Sort-Object -Property SimTitles -Descending | Select-Object -First 10 


Write-host 'Filtering Cities'
foreach($city in $cities){
     
    $filteredlocations += $dirtylaundry | where-object {($_.description -match $city.name -or $_.Title -match $city.name)} | Select-Object $_
}
    $filteredlocations = $filteredlocations | Sort-Object -Unique -Property Title, Source | Select-Object

Write-host 'Filtering Med terms'
foreach($term in $medical.Terms) {
    
    $finalcut +=$filteredlocations | where-object {($_.description -Match ('\b'+$term) -or $_.Title -match ('\b'+$term))}  |Select-Object $_
}


####################################
##
##  Capture only unique Titles
##
####################################


$filtered = $finalcut | Sort-Object -Unique -Property Title, Source | Sort-Object -Property SimTitles -Descending
$Articles = $filtered.Count
$Subj = 'Stories reviewed: ' + $posts.Count +' posts filtered to ' + $Articles + ' articles'
         

####################################
##
##  HTML output header
##
####################################

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #2AA9A0; }
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
h3{
clear: both;
font-size: 100%;
margin-left: 5px;
margin-top: 30px;
color:#717276;
}
h4{
color: black;
font-weight: bold;
font-size: 24px;
}
TABLE tr:nth-child(even) td:nth-child(even){  background: #BBBBBB; }
TABLE tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
TABLE tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
TABLE tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
</style>
"@
##########################################################


[string]$strT = $Tweeters.Name -join ", "
[string]$strF = $feeds.Name -join ", " 
[string]$strDL = $dirtylaundryterms.Terms -join ", "
[string]$strSut = $Sutterterms.Sutter_Words -join ", "
[string]$strMed = $medical.Terms -join ", " 
[string]$CRTab = '%0D%0A     '
[string]$CR = '%0D%0A'
[string]$DCR ='%0D%0A%0D%0A'
#[string]$POEmail ='"mailto:?cc=' + $env:UserName +'@sutterhealth.org&Subject=Media scraping identified a news event of interest [encrypt]&body='
[string]$POEmail ='"mailto:?Subject=Media scraping identified a news event of interest [encrypt]&body='
[string]$POBody = 'Based on the information below, and utilizing the HPP grid, Auditing and Monitoring Team would recommend the following: ' 
$POBody += $DCR + $DCR + 'Recommend:' +$CRTab +'BTG' + $CRTab + 'No BTG' + $DCR + 'Link:  '
$POEmail += $POBody
[string]$POData = $CR + 'Name: ' + $CR + 'MRN: ' +$DCR + 'Scoring Grid:' +$DCR +'Media Exposure: ' + $CRTab + 'Local/US/International Coverage (Y)' +$DCR +'Other Media links: '
$POData += $DCR + 'Patient status:' + $CRTab + 'Patient is part of the general population' + $CRTab + 'Patient is well known or recognizable by workforce and general public (Y)'
$POData += $DCR +'PHI Sensitivity:' + $CRTab + 'No sensitive PHI Identifier' + $CRTab +'Sensitive PHI identifier (Y)' + $DCR
$POData += 'Risk Exposure:' +$CRTab + 'No or low risk or harm associated with exposure' + $CRTab + 'Exposure may pose privacy violation and potential harm to patient and staff (Y)' + $DCR
$POData += 'Total Yes Responses:      ' + $DCR + '1-2 Yes: Privacy Officer Discretion' + $CR + '3-4 Yes: Patient is HPP' + $DCR 
#$POData += 'Options:' + $DCR + 'Temporary- If the patient is deemed a HPP, they are placed on the Protenus watch list for 30 days. Privacy Officer can request BTG depending on circumstances of the case. ' 
#$POData += $DCR + 'Permanent- If the PO determines it is a permanent HPP, then the patient is placed on the Protenus watch list permanently and BTG is applied. "'  
$POData += 'Options:' + $DCR + 'Temporary-Protenus watch list for 30 days. BTG-PO discretion.' 
$POData += $DCR + 'Permanent-Protenus watch list permanently and BTG is applied."'  
$FeedCount = $feeds.Count
$TweetCount = $Tweeters.Count
if($badfeeds.Count -eq 0) {$badfeeds += 'None'}



##  %0D%0A for carriage return
##########################################################
$strDate = (get-date).ToString("MM-dd-yyyy @ hh:mm tt")
$pCount = Get-PostCount $posts
$posts | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>Full Posts</h4><h3>RSS Feeds pulled: $strF <br> Twitter Accounts: $strT <br> Stories Reviewed: $pCount <br> $strDate</h3>" | Out-File "a:\RSS_Feeds\Original_Posts.html"

if(($pCount=Get-PostCount $dirtylaundry) -eq 0) { $dirtylaundry = Get-NullPost $dirtylaundry}
$dirtylaundry | ConvertTo-Html -as Table  -Property Title, description, link, pubDate, source, SimTitles -Head $Header `
    -PreContent "<h4>Dirty Laundry: $pCount posts</h4><h3>Terms: $strDL <br> $strDate</h3>" | Out-File "a:\RSS_Feeds\Dirty_Laundry.html"

#if(( = Get-PostCount $Sutterposts)-eq 0) {$Sutterposts = Get-NullPost $Sutterposts}
$pCount = $Sutterposts.Count
$Sutterposts | ConvertTo-Html -as Table  -Property Title, description, link, pubDate, source, SimTitles -Head $Header `
    -PreContent "<h4>Sutter mentioned Posts: $pCount posts</h4><h3>Terms: $strSut <br> $strDate</h3>" | Out-File "a:\RSS_Feeds\SutterPosts.html"

$Sutterpub = $Sutterposts | ConvertTo-Html -as Table  -Property Title, description, link, pubDate, source, SimTitles -Fragment `
    -PreContent "<h4>Sutter mentioned Posts: $pCount posts</h4><h3>Terms: $strSut <br> $strDate</h3>" 

$filteredlocations | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>Only in SandraCities</h4><h3>$strDate </h3>" | Out-File "a:\RSS_Feeds\LocationFiltered.html"

$filtered | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>Medical Terms: $Articles posts</h4><h3>Terms: $strMed <br>$strDate </h3>" | Out-File "a:\RSS_Feeds\FinalCut.html"

$HTMLT = $TrendingTopics | ConvertTo-Html -As Table -Property Title, description, link, pubDate,  source, SimTitles -Fragment `
    -PreContent "<h4>Trending News:  Stories with three or more similar titles</h4><h3>Only filtered on dirty laundry terms: $strDL</h3>"

$filtered = $filtered | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source, SimTitles -Fragment `
    -PreContent "<h4>Feeds scraped - $feedCount  Twitter Accounts scraped:  $TweetCount<br> $Subj </h4><h3> Filtered for dirty laundry, cities and medical terms </h3>"|Out-String

$filtered

$HTMLTF = Convert-Links $HTMLT $POEmail $POData 
$HTMLSP = Convert-Links $Sutterpub $POEmail $POData
$HTMLFil = Convert-Links $filtered $POEmail $POData


$ResultsHTML = ConvertTo-Html -Body  "$HTMLfil", "$HTMLTF", "$HTMLSP"  -Title "RSS Feed Report" -Head $Header `
    -PostContent "<br><h3> RSS Feeds pulled: $strF  <br>Feeds that failed : $badfeeds <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:UserName<br>`
    <a href='\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\RSS_Feed.html'>Filtered Posts</a><br>`
    <a href='\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Dirty_Laundry.html'>Dirty Laundry</a><br> `
    <a href='\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Original_Posts.html'>All Posts</a></h3>" `
    |Out-String   ##Out-File "a:\TestScript\RSS_Feed.html"

 

# For testing purposes - so I don't bombard with emails
$LiveRun = $true

####################################
##
##  CSV file of mail variables to protect sensitive info
##  name,value (ToGroup,Tom Jones <anyemail@somewhere.com>)
##
####################################

Import-Csv -Path "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Data\Variable.csv" | foreach {
    New-Variable -Name $_.Name -Value $_.Value -Force
}

if($LiveRun) {
    $props = @{
        From = $CCGroup
        To= $TTGroup
        CC= $CCGroup
        Subject = 'RSS Feeds'
        Body = $ResultsHTML 
        SmtpServer = $mailserver
    }
    Send-MailMessage @props -BodyAsHtml
}
$strDate = (get-date).ToString("MM-dd-yyyy_hhmm_tt")
$FileName = "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\RSS_Feed_" + $strDate +".html"
$ResultsHTML| Out-File $FileName 
$filtered | Out-File "\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\filtered.html"
Rename-LatestNews

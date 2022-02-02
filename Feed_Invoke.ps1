#####################################

Function Get-SimTitles ([object[]]$anyPosts)
{
write-host 'Titles -' $anyPosts.title

Function Get-CleanTitle([string]$anyTitle)
{
    $anyTitle =$anyTitle -replace ',|\?', '' 
    $CleanList=@()
    $CleanList =@('a','an','and','as','at','for','in','into','have', 'has', 'on','of','to','the','with')
    $anyTitle=$anyTitle.ToLower()
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
       
    #Run twice as loop was not working right     
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
        
    return $TitleArray | Sort-Object -Unique 
}

Function Measure-VectorSimilarity
{ 
## VectorSimilarity by .AUTHOR Lee Holmes 
## 
[CmdletBinding()]
param(
    ## The first set of items to compare
    [Parameter(Position = 0)]
    $Set1,

    ## The second set of items to compare
    [Parameter(Position = 1)]   
    $Set2,
    
     
    [Parameter()]
    $KeyProperty,

   
    [Parameter()]
    $ValueProperty
)

## If either set is empty, there is no similarity
if((-not $Set1) -or (-not $Set2))
{
    return 0
}

## Figure out the unique set of items to be compared - either based on
## the key property (if specified), or the item value directly
$allkeys = @($Set1) + @($Set2) | Foreach-Object {
    if($PSBoundParameters.ContainsKey("KeyProperty")) { $_.$KeyProperty}
    else { $_ }
} | Sort-Object -Unique

## Figure out the values of items to be compared - either based on
## the value property (if specified), or the item value directly. Put
## these into a hashtable so that we can process them efficiently.

$set1Hash = @{}
$set2Hash = @{}
$setsToProcess = @($Set1, $Set1Hash), @($Set2, $Set2Hash)

foreach($set in $setsToProcess)
{
    $set[0] | Foreach-Object {
        if($PSBoundParameters.ContainsKey("ValueProperty")) { $value = $_.$ValueProperty }
        else { $value = 1 }
        
        if($PSBoundParameters.ContainsKey("KeyProperty")) { $_ = $_.$KeyProperty }

        $set[1][$_] = $value
    }
}

## Calculate the vector / cosine similarity of the two sets
## based on their keys and values.
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

## Return the result
return [Math]::Round($dot / ($mag1 * $mag2), 3)

}

$i=0
write-host 'Checking similarities for ' $anyPosts.Count ' titles'

Foreach($title in $anyPosts) {
    $Sim = 0
    $i++
    if($i%20 -eq 0) {write-host $i ' of ' $anyPosts.Count}
    $test1 = Get-CleanTitle $title.title
    $k=0
    Foreach($other in $anyPosts) {
        
        if($other.source -ne $title.source) {
            $test2= Get-CleanTitle $other.title
            $VS= Measure-VectorSimilarity $test1 $test2
            if($VS -gt .375) {
                $Sim ++
            }
        }
    }
    
    $title.SimTitles = $Sim
}

return $anyPosts

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
    $Path = "\\dcms2ms\Privacy Audit and Logging\TestScript\"
    $Item = Get-ChildItem -Path $Path | Where-Object {$_.Name -match 'RSS_Feed' }| Sort-Object LastWriteTime -Descending |Select-Object -First 1
    Copy-Item $Item.FullName -Destination "\\dcms2ms\Privacy Audit and Logging\TestScript\RSS_Feed.html"
    
    ## Remove feeds older than 5 days
    Get-ChildItem | Where-Object {($_.Name -like 'RSS_Feed*.html') -and ($_.LastWriteTime -lt (Get-Date).AddDays(-5))}  | Remove-Item
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
$badfeeds=@()

####################################
##
##  Terms and locations for your purposes
##
####################################

$dirtylaundryterms = @('accident','armed','arrest','collision','crash','DUI','fatal','hit-and-run','homicide','shooting','shot','suspects','Sutter','victim')
$medical =@('injuries','injured','injury','hospitalized','hospital','death','died','dies','killed','wounded')
#$cities = @('Antioch','Auburn','Brentwood','Citrus Heights','Elk Grove','Fairfield','Lodi','Oakdale','Oakland','Richmond','Rocklin','Roseville','Sacramento','San Francisco','San Jose','Stockton','Tracy','Vacaville','Vallejo','Yuba City')
$cities = Import-Csv -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\Cities.csv" | Select-Object -Property Name
$feeds = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\Feeds.csv" | Where-Object {$_.Type -eq 'RSS'}| Select-Object -Property Link, Name
$Tweeters = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\Feeds.csv" | Where-Object {$_.Type -eq 'Tweet'} |Select-Object -Property Link, Name

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

$InitPosts = $posts
## replace any HTML in the XML
## \<.+?>
 $InitPosts | Where-Object {($_.description -match '<p>' -or $_.description -match '<a')} | ForEach-Object {$_.description -replace '(<.+?>)',''}| Select-Object
 $InitPosts | Where-Object { $_.description -match '\?\?\?'} | ForEach-Object {$_.description -replace '\?\?\?',"'"} | Select-Object
 
$posts | ForEach-Object {
    if ($_.description -match '<p>' ) {
        $_.description=$_.description -replace '(<.+?>)',''
    } 
    
}
$ic=[Globalization.CultureInfo]::InvariantCulture

$posts | ForEach-Object {
    try { $_.pubDate= Get-Date $_.pubDate -Format ("MM-dd-yy hh:mm tt") }
    catch {  try{ $_.pubDate = [datetime]::ParseExact($_.pubDate.replace('PST','-8'), 'MM-dd-yy hh:mm tt', $ic)  }
             catch { write-host 'Unable to parse date' $_.Source }
           }
  ##'ddd dd MMM yyyy HH:mm:ss z'
   }            
    
$posts | Format-Table
$posts.Count

####################################
##
##  Filter based on $qry terms and $Cities
##
####################################

Write-host 'Filtering terms'

foreach($term in $dirtylaundryterms){
    
    $filteredposts += $posts | Where-Object {($_.description -match $term -or $_.Title -match $term)} | Where-Object{$_.description -notmatch "basketball"}
    
    }
    $OldPosts = Import-CSV -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\DirtyLaundry.csv" `
    | Where-Object {$_.PullDate -gt (Get-Date).AddDays(-2) }
    $dirtylaundry = $filteredposts | Sort-object -Unique -Property Title | Select-Object -Property title, description, link, source, SimTitles, PubDate, PullDate 
    $NewPosts = ($OldPosts + $filteredposts | Sort-object -Unique -Property Title)|Sort-Object -Unique -Property Title, PullDate, pubDate | Select-Object -Property title, description,link,source,SimTitles,PubDate,PullDate 
    write-host $NewPosts '  - New posts, filtered for dirty laundry'
    $TrendingTopics = Get-SimTitles $NewPosts
    $TrendingTopics | Export-CSV -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\DirtyLaundry.csv"
    $TrendingTopics = $TrendingTopics | Where-Object{$_.SimTitles -gt 2} |Sort-Object -Property SimTitles -Descending


Write-host 'Filtering Cities'
foreach($city in $cities){
       
    $filteredlocations += $dirtylaundry | where-object {($_.description -match $city.name -or $_.Title -match $city.name)} | Select-Object $_
}
    $filteredlocations = $filteredlocations | Sort-Object -Unique -Property Title, Source | Select-Object

Write-host 'Filtering Med terms'
foreach($term in $medical) {

    $finalcut +=$filteredlocations | where-object {($_.description -Match ('\b'+$term) -or $_.Title -match ('\b'+$term))} | Select-Object $_
    }


####################################
##
##  Capture only unique Titles
##
####################################


$filtered = $finalcut | Sort-Object -Unique -Property Title, Source
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
[string]$strDL = $dirtylaundryterms -join ", "
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
$posts | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>Full Posts</h4><h3>RSS Feeds pulled: $strF <br> Twitter Accounts: $strT <br> $Subj <br> $strDate</h3>" | Out-File "a:\RSS_Feeds\Original_Posts.html"

$dirtylaundry | ConvertTo-Html -as Table  -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>DirtyLaundry Posts</h4><h3>Terms: $dirtylaundryterms <br> $strDate</h3>" | Out-File "a:\RSS_Feeds\Dirty_Laundry.html"

$filteredlocations | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>Only in SandraCities</h4><h3>$strDate </h3>" | Out-File "a:\RSS_Feeds\LocationFiltered.html"

$filtered | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Head $Header `
    -PreContent "<h4>Medical Terms</h4><h3>Terms: $Medical <br>$strDate </h3>" | Out-File "a:\RSS_Feeds\FinalCut.html"

$HTMLT = $TrendingTopics | ConvertTo-Html -As Table -Property Title, description, link, pubDate,  source, SimTitles -Fragment `
    -PreContent "<h4>Trending News:  Stories with three or more similar titles</h4>"

$HTMLTF = $HTMLT -replace '<tr><td>(?<title>[^\<]+)<\/td><td>(?<desc>[^\<]+)<\/td><td>(?<weblink>[^\<]+)\<\/td><td>(?<pubDate>[^\<]+)', `
    ('<tr><td>${title}</td><td>${desc}</td><td><a href="${weblink}">Full_Story_Click_Here</a><br><a href='+$POEmail+'${weblink}%0D%0A%0D%0ATitle: ${title}%0D%0ADescription: ${desc}%0D%0APublished on: ${pubDate}%0D%0A'`
    + $POData + '>Send to PO</a></td><td>${pubDate}</td>')

$filtered = $filtered | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Fragment `
    -PreContent "<h4>Feeds scraped - $feedCount  Twitter Accounts scraped:  $TweetCount </h4><h3> Filtered Feed Terms: $qry </h3>"|Out-String

$HTMLfiltered = $filtered  -replace '<tr><td>(?<title>[^\<]+)<\/td><td>(?<desc>[^\<]+)<\/td><td>(?<weblink>[^\<]+)\<\/td><td>(?<pubDate>[^\<]+)', `
    ('<tr><td>${title}</td><td>${desc}</td><td><a href="${weblink}">Full_Story_Click_Here</a><br><a href='+$POEmail+'${weblink}%0D%0A%0D%0ATitle: ${title}%0D%0ADescription: ${desc}%0D%0APublished on: ${pubDate}%0D%0A'`
    + $POData + '>Send to PO</a></td><td>${pubDate}</td>')



$ResultsHTML = ConvertTo-Html -Body  "$HTMLfiltered", "$HTMLTF" -Title "RSS Feed Report" -Head $Header `
    -PostContent "<br><h3> RSS Feeds pulled: $strF  <br>Feeds that failed : $badfeeds <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:UserName<br>`
    <a href='\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\rss_feed.html'>Filtered Posts</a><br>`
    <a href='\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Dirty_Laundry.html'>Dirty Laundry</a><br> `
    <a href='\\dcms2ms\Privacy Audit and Logging\RSS_Feeds\Original_Posts.html'>All Posts</a></h3>" `
    |Out-String   ##Out-File "a:\TestScript\RSS_Feed.html"

 

# For testing purposes - so I don't bombard with emails
$LiveRun = $false

####################################
##
##  CSV file of mail variables to protect sensitive info
##  name,value (ToGroup,Tom Jones <anyemail@somewhere.com>)
##
####################################

Import-Csv -Path "I:\RSS_Project\Variable.csv" | foreach {
    New-Variable -Name $_.Name -Value $_.Value -Force
}

if($LiveRun) {
    $props = @{
        From = $CCGroup
        To= $CCGroup
        CC= $CCGroup
        Subject = 'RSS Feeds'
        Body = $ResultsHTML 
        SmtpServer = $mailserver
    }
    Send-MailMessage @props -BodyAsHtml
}
$strDate = (get-date).ToString("MM-dd-yyyy_hhmm_tt")
$FileName = "\\dcms2ms\Privacy Audit and Logging\TestScript\RSS_Feed_" + $strDate +".html"
$ResultsHTML| Out-File $FileName 
$filtered | Out-File "\\dcms2ms\Privacy Audit and Logging\TestScript\filtered.html"
Rename-LatestNews

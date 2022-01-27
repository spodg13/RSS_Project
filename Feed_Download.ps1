######################################

Function Get-Posts ($anyXMLfeed)
{ $fields = 'title','description','pubDate','link'

## substitute $anyXMLfeed for $rss
## Atom line
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
    $posts | Add-Member -NotePropertyName 'source' -NotePropertyValue 'rss'
    return $posts
}

Function Get-Tweets ($anyTwitterHandle)
{

    $Tweets = Get-TwitterStatuses_UserTimeline -screen_name $anyTwitterHandle -count 13 -tweet_mode extended | Select-Object full_text,created_at,user
    # Put in readable time format
    $Tweets | ForEach-Object {
        $_.created_at= [datetime]::ParseExact($_.created_at, "ddd MMM dd HH:mm:ss zzz yyyy", $null)
        } 
    
    $Tweets | Add-Member -NotePropertyName 'link' -NotePropertyValue '-'
    $Tweets | Add-Member -NotePropertyName 'source' -NotePropertyValue 'tweet'
    $Tweets | Add-Member -NotePropertyName 'title' -NotePropertyValue '-'

    $Tweets | ForEach-Object { if($_.full_text -match '(?<weblink>\b(https:\/\/[a-zA-Z.\/0-9]*)+)') {
                                             $_.link = $Matches.weblink }} 

    $Tweets | ForEach-Object {$_.title = $_.user.name}
    # name of property and expression
    $posts = $Tweets | Select-Object -property @{Name='description'; Expression={$_.full_text}},@{Name='pubDate';Expression={$_.created_at}},@{Name='title'; Expression={$_.title}},@{Name='link'; Expression={$_.link}},@{Name='source'; Expression={$_.source}} 
                             
    return $posts
}
Function Rename-LatestNews
{
    ## Takes newest date stamped feed and copies it to unstamped RSS_Feed
    ## Deletes any date stamped feed older than 5 days
    $Path = "\\dcms2ms\Privacy Audit and Logging\TestScript\"
    $Item = Get-ChildItem -Path $Path | Where-Object {$_.Name -match 'RSS_Feed' }| Sort-Object LastWriteTime -Descending |Select-Object -First 1
    Copy-Item $Item.FullName -Destination "\\dcms2ms\Privacy Audit and Logging\TestScript\RSS_Feed.html"
    <#
        For combining - could use: loop through array, item 0 was just populated
        $Comb=Get-Content $Item.FullName[1-4]|Out-file RSS_Feed_Comb.html

    #>
    ## Remove feeds older than 5 days
    Get-ChildItem | Where-Object {($_.Name -like 'RSS_Feed*.html') -and ($_.LastWriteTime -lt (Get-Date).AddDays(-5))}  | Remove-Item
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
$Tweeters = @()
$Tweeters = ('krcr7','AuburnJournal')
$feeds = @()
$feeds = ("https://www.kcra.com/topstories-rss","https://sacramento.cbslocal.com/feed/","https://sanfrancisco.cbslocal.com/feed/","https://abc7news.com/feed/","https://www.ksbw.com/topstories-rss")#, "https://www.sacbee.com/?widgetName=rssfeed&widgetContentId=6199&getXmlFeed=true")
#"https://rss.app/feeds/P9pRXxyOc0VmepAS.xml",

$i = 0
$doc = New-Object System.Xml.XmlDocument
$posts=@()
$filtered = @()
$filteredlocations = @()
$filteredposts = @()

####################################
##
##  Terms and locations for your purposes
##
####################################

$qry = @('accident','armed','arrested','collision','crash','died','dies','fatal','hit-and-run','killing','shooting','shot','suspects','Sutter','victim')
#$cities = @('Antioch','Auburn','Brentwood','Citrus Heights','Elk Grove','Fairfield','Lodi','Oakdale','Oakland','Richmond','Rocklin','Roseville','Sacramento','San Francisco','San Jose','Stockton','Tracy','Vacaville','Vallejo','Yuba City')
$cities = Import-Csv -Path "\\dcms2ms\Privacy Audit and Logging\TestScript\Cities.csv" | Select-Object -Property Name

####################################
##
##  Save each feed in a file
##  $rss = [xml](Get-Content 'I:\RSS_Project\Feeds\feed-1.xml') from an array of files? -or
##  $rss=[xml](Invoke-WebRequest "https://sacramento.cbslocal.com/feed/")
##
####################################

foreach($feed in $feeds) {
$i++

$doc.Load("$feed")
$doc.save("I:\RSS_Project\Feeds\feed-" + $i +".xml")
}

$files = Get-ChildItem "I:\RSS_Project\Feeds\"
$files

####################################
##
##  Process files
##
####################################

foreach($file in $files){
    $rss = [xml](Get-Content $file.FullName)
    $posts += Get-Posts $rss
}

foreach($Tweeter in $Tweeters){
    $posts += Get-Tweets $Tweeter
}


## replace any HTML paragraphs
## \<.?p\>

$posts | ForEach-Object {
    if ($_.description -match '<p>') {
        $_.description=$_.description -replace '(\<.?p\>)',''
    }       
}

$posts | ForEach-Object {
    $_.pubDate= Get-Date $_.pubDate -Format ("MM-dd-yy hh:mm tt") 
}       
    

$posts | Format-Table
$posts.Count

####################################
##
##  Filter based on $qry terms and $Cities
##
####################################

Write-host 'Filtering terms'
foreach($term in $qry){
    $filteredposts += $posts | where-object {($_.description -Match $term -or $_.Title -match $term)} | Select-Object $_
}

Write-host 'Filtering Cities'
foreach($city in $cities){
       
    $filteredlocations += $filteredposts | where-object {($_.description -Match $city.name -or $_.Title -match $city.name)} | Select-Object $_
}

####################################
##
##  Capture only unique Titles
##
####################################


$filtered = $filteredlocations | Sort-Object -Unique -Property Title
$Articles = $filtered.Count
$Subj = $feeds.Count.ToString() + ' RSS Feeds - ' + $posts.Count + ', Twitter Feeds - ' + $Tweeters.Count + ` 
        ', posts filtered to ' + $Articles + ' articles'
         
$filtered | Format-List

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
color: #343434;
font-weight: normal;
font-size: 20px;
}
TABLE tr:nth-child(even) td:nth-child(even){  background: #BBBBBB; }
TABLE tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
TABLE tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
TABLE tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
</style>
"@
##########################################################

$strDate = (get-date).ToString("MM-dd-yyyy @ hh:mm tt")
[string]$strT = $Tweeters -join ", "
[string]$strF = $feeds -join ", " 
[string]$CRTab = '%0D%0A     '
[string]$CR = '%0D%0A'
[string]$DCR ='%0D%0A%0D%0A'
[string]$POEmail ='"mailto:?cc=' + $env:UserName +'@sutterhealth.org&Subject=Media scraping identified a news event of interest [encrypt]&body='
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




##  %0D%0A for carriage return
##########################################################

$HTMLposts = $posts | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Fragment `
    -PreContent "<h3>RSS Feeds pulled: $strF <br> Twitter Accounts: $strT <br> $Subj </h3>"


$filtered = $filtered | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source -Fragment `
    -PreContent "<h3> Filtered Feed Terms: $qry </h3>"|Out-String

$HTMLfiltered = $filtered  -replace '<tr><td>(?<title>[^\<]+)<\/td><td>(?<desc>[^\<]+)<\/td><td>(?<weblink>[^\<]+)\<\/td><td>(?<pubDate>[^\<]+)', `
    ('<tr><td>${title}</td><td>${desc}</td><td><a href="${weblink}">Full_Story_Click_Here</a><br><a href='+$POEmail+'${weblink}%0D%0A%0D%0ATitle: ${title}%0D%0ADescription: ${desc}%0D%0APublished on: ${pubDate}%0D%0A'`
    + $POData + '>Send to PO</a></td><td>${pubDate}</td>')

<### Test HTML section

$FullHTML = $filtered  -replace '<tr><td>(?<title>[^\<]+)<\/td><td>(?<desc>[^\<]+)<\/td><td>(?<weblink>[^\<]+)\<\/td><td>(?<pubDate>[^\<]+)', `
    ('<tr><td>${title}</td><td>${desc}</td><td><a href="${weblink}">Full_Story_Click_Here</a><br><a href='+$POEmail+'${weblink}%0D%0A%0D%0ATitle: ${title}%0D%0ADescription: ${desc}%0D%0APublished on: ${pubDate}%0D%0A'`
    + $POData + '>Send to PO</a></td><td>${pubDate}</td>')

$ResultsF = ConvertTo-Html -Body "$FullHTML","$HTMLposts" -Title "RSS Feed Report" -Head $Header `
    -PostContent "<br><h3> <br>Locations = $cities <br>RSS Feeds pulled: $strF <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:UserName<br></h3>" `
    |Out-File "a:\TestScript\RSS_Feed_test.html"

##########>


$ResultsHTML = ConvertTo-Html -Body  "$HTMLfiltered", "$HTMLposts" -Title "RSS Feed Report" -Head $Header `
    -PostContent "<br><h3> <br>Locations = $cities <br>RSS Feeds pulled: $strF <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:UserName<br></h3>" `
    |Out-String   ##Out-File "a:\TestScript\RSS_Feed.html"

 

# For testing purposes - so I don't bombard with emails
$LiveRun = $true

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


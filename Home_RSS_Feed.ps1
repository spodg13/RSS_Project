$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

function ConvertTo-WordSets( [psobject] $Posts )
{

    # preprocess each post to break its title into word counts 
    # so we don't need to do it every time we compare 2 posts
    # Courtesy stackoverflow @mclayton

    foreach( $post in $Posts )
    {
        $set = new-object PSCustomObject -Property ([ordered] @{
            "Post"   = $post
            "Title"  = $post.Title.Trim()
            "Words"  = $null
            "Counts" = $null
        });
        $set.Words  = $set.Title.Split(" ");
        $set.Counts = $set.Words `
            | group-object `
            | foreach-object `
                -Begin   { $counts = @{} } `
                -Process { $counts.Add($_.Name, $_.Count) } `
                -End     { $counts };
        write-output $set;
    }

}
Function Convert-Links($anyHTML)
{
    $result = $anyHTML -replace '<tr><td>(?<title>[^\<]+)<\/td><td>(?<desc>[^\<]+)<\/td><td>(?<weblink>[^\<]+)\<\/td><td>(?<pubDate>[^\<]+)', `
    ('<tr><td>${title}</td><td>${desc}</td><td><a href="${weblink}">Full_Story_Click_Here</a></td><td>${pubDate}</td>')

    return $result

}


function Get-SimTitles( [psobject] $NewPosts )
{

    # instead of comparing every object to every object, just compare unique combinations
    # e.g. X compared to Y is the same as Y compared to X so score them both at the same time
    # (and we don't need to compare an object to itself either)

    for( $i = 0; $i -lt $NewPosts.Length; $i++ )
    {
        $left = $NewPosts[$i];
        for( $j = $i + 1; $j -lt $NewPosts.Length; $j++ )
        {
            $right = $NewPosts[$j];
            if ((Measure-TitleSimilarityMC $left $right) -gt .35)
            {
                $left.Post.SimTitles  = $left.Post.SimTitles + 1;
                $right.Post.SimTitles = $right.Post.SimTitles + 1;
            } 
        } 
    }

}

Function Measure-TitleSimilarityMC
{
    param
    (
        [Parameter(Position = 0)]
        $Left,
        [Parameter(Position = 1)]   
        $Right
    ) 

    # we can use the pre-processed word counts now

    $allkeys = $Left.Words + $Right.Words | Sort-Object -Unique

    $dot = 0
    $mag1 = 0
    $mag2 = 0

    foreach($key in $allkeys)
    {
        $dot  += $Left.Counts[$key] * $Right.Counts[$key]
        $mag1 += $Left.Counts[$key] * $Left.Counts[$key]
        $mag2 += $Right.Counts[$key] * $Right.Counts[$key]
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
    ApiKey = $env:twAPIKey
    ApiSecret = $env:twAPIKeySecret
    AccessToken = $env:twAccessToken
    AccessTokenSecret =$env:twAccessTokenSecret
}

$i = 0
$posts=@()
$filtered = @()
$OldPosts=@()
$filteredlocations = @()
$filteredposts = @()
$dirtylaundry=@()
$finalcut =@()
$badfeeds=@()
$dl_file = "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/Dirty_Laundry.html"
$post_file ="/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/all_posts.html"
$RSS_file = "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/RSS_Out.html"
$cutoff = (Get-Date).AddDays(-3)

####################################
##
##  Terms and locations for your purposes
##
####################################

$dirtylaundryterms = @('accident','armed','arrest','collision','crash','DUI','fatal','hit-and-run','homicide','shooting','shot','suspects','Sutter','victim')
$medical =@('injuries','injured','injury','hospitalized','hospital','death','died','dies','killed','wounded')
$cities = @('Antioch','Auburn','Brentwood','Citrus Heights','Elk Grove','Fairfield','Lodi','Oakdale','Oakland','Richmond','Rocklin','Roseville','Sacramento','San Francisco','San Jose','Stockton','Tracy','Vacaville','Vallejo','Yuba City')
#$cities = Import-Csv -Path "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/Cities.csv" | Select-Object -Property Name
$feeds = Import-CSV -Path "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/Feeds.csv" | Where-Object {$_.Type -eq 'RSS'}| Select-Object -Property Link, Name
#$feeds = ("https://www.kcra.com/topstories-rss","https://sacramento.cbslocal.com/feed/","https://abc7news.com/feed/","https://www.ksbw.com/topstories-rss")
$Tweeters = Import-CSV -Path "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/Feeds.csv" | Where-Object {$_.Type -eq 'Tweet'} |Select-Object -Property Link, Name
#$Tweeters =@()

$feeds | Format-Table
$Tweeters | Format-Table

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
    #try{
    $posts += Get-Tweets $Tweeter.Link $Tweeter.Name
    #} Catch
    #{ Reset-Authorization
    #    $posts += Get-Tweets $Tweeter.Link $Tweeter.Name
    #    }
}


$posts | & {process {if($_.description -match '<p>'){$_.description = $_.description -replace '(<.+?>)',''}}}
$posts | & {process {if($_.source -match 'Bee'){$_.pubDate =$_.pubDate.replace('PST','-8')}}}
$posts | & {process {if($_.title -match '\?{3}'){$_.title = $_.title -replace '\?{3}',"'"}}}
$posts | & {process {if($_.description -match '\?{3}'){$_.description = $_.description -replace '\?{3}',"'"}}}

$posts | ForEach-Object {
        try { $_.pubDate= Get-Date $_.pubDate -Format ("MM-dd-yy hh:mm tt") }
            catch { write-host 'Unable to parse date' $_.Source }
        }      
$posts.Count
$posts | Sort-Object -Property pubDate, title

Write-host 'Filtering terms'

foreach($term in $dirtylaundryterms){
        $filteredposts += $posts | Where-Object {($_.description -match $term -or $_.Title -match $term)} | Where-Object{$_.description -notmatch "basketball"}
}
##$dirtylaundry = $filteredposts | Sort-object -Unique -Property Title | Select-Object -Property title, description, link, source, SimTitles, PubDate, PullDate 

$OldPosts = Import-CSV -Path "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/DirtyLaundry.csv"     |
     Where-Object {(Get-Date $_.PullDate) -gt $cutoff } | Select-Object
 
$dirtylaundry = $filteredposts + $OldPosts     
##$dirtylaundry = $filteredposts | Sort-object -Unique -Property Title | Select-Object -Property title, description, link, source, SimTitles, PubDate, PullDate  
$dirtylaundry = $dirtylaundry | Sort-object -Unique -Property Title, pubDate |Select-Object -Property title, description,link,source,SimTitles,PubDate,PullDate 
$dirtylaundry | & {process {$_.simTitles = 0}}
write-host $dirtylaundry.Count '  - New posts, filtered for dirty laundry'
    
##Process for trending and save to dirty laundry
write-host 'Processing Similar Titles'
  
$WordSets = @( ConvertTo-WordSets  $dirtylaundry)
Get-SimTitles $WordSets;    
$dirtylaundry | Export-CSV -Path "/Users/darrylgould/Library/Mobile Documents/com~apple~CloudDocs/Coding/RSS_Project/RSS_Project/Feeds/DirtyLaundry.csv"
$TrendingTopics = $dirtylaundry | Where-Object{$_.SimTitles -gt 2} |Sort-Object -Property SimTitles -Descending | Select-Object -First 15
$dirtylaundry = $dirtylaundry | Sort-Object -Property SimTitles -Descending | Select-Object 

foreach($city in $cities){
       
    $filteredlocations += $dirtylaundry | where-object {($_.description -match $city -or $_.Title -match $city)} | Select-Object 
}
    $finalcut = $filteredlocations | Sort-Object -Unique -Property Title, Source  | Sort-Object -property SimTitles -Descending | Select-Object

$Articles = $finalcut.Count
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

$strT =  'None' #  $Tweeters.Name -join ", "
$strF = $feeds.Name -join ", " 
$strDL = $dirtylaundryterms -join ", "
$strDate = (get-date).ToString("MM-dd-yyyy @ hh:mm tt")
$dlCount = $dirtylaundry.count
$feedCount = $feeds.count
$TweetCount = 0

Convert-Links ($posts | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source, SimTitles -Head $Header `
    -PreContent "<h4>Full Posts</h4><h3>RSS Feeds pulled: $strF <br> Twitter Accounts: $strT <br> $Subj <br> $strDate</h3>" `
    -PostContent "<br><h3> RSS Feeds pulled: $strF  <br>Feeds that failed : $badfeeds <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:USER<br>`
    <a href='$dl_file'>Dirty Laundry</a><br> `
    <a href='$RSS_file'>City Filtered</a></h3>" ) | Out-File $post_file

Convert-Links($dirtylaundry | ConvertTo-Html -as Table  -Property Title, description, link, pubDate, source, SimTitles -Head $Header `
    -PreContent "<h4>DirtyLaundry: $dlCount posts</h4><h3>Terms: $strDL <br> $strDate</h3>" `
    -PostContent "<br><h3> RSS Feeds pulled: $strF  <br>Feeds that failed : $badfeeds <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:USER<br>`
    <a href='$RSS_file'>City Filtered Posts</a><br> `
    <a href='$post_file'>All Posts</a></h3>" )| Out-File $dl_file

$HTMLT = $TrendingTopics | ConvertTo-Html -As Table -Property Title, description, link, pubDate,  source, SimTitles -Fragment `
    -PreContent "<h4>Trending News:  Stories with three or more similar titles</h4>"

$HTMLTF = Convert-Links $HTMLT 
    
$finalcut = $finalcut | ConvertTo-Html -as Table -Property Title, description, link, pubDate, source, SimTitles -Fragment `
    -PreContent "<h4>Feeds scraped - $feedCount  Twitter Accounts scraped:  $TweetCount </h4><h3> Filtered Feed Terms: None </h3>"|Out-String

$HTMLfiltered = Convert-Links $finalcut  


ConvertTo-Html -Body  "$HTMLfiltered", "$HTMLTF" -Title "RSS Feed Report" -Head $Header `
    -PostContent "<br><h3> RSS Feeds pulled: $strF  <br>Feeds that failed : $badfeeds <br> Twitter Accounts: $strT <br> <br> Created on $strDate  by $env:USER<br>`
    <a href='$dl_file'>Dirty Laundry</a><br> `
    <a href='$post_file'>All Posts</a></h3>" `
    |Out-File $RSS_file 

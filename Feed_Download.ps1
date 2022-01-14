######################################

Function Get-Posts ($anyXMLfeed)
{ $fields = 'title','description','pubDate','link'

  $posts = foreach($item in $anyXMLfeed.SelectNodes('//item')) {
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
        # if field name date - convert to format?
        # add node value to dictionary
        $properties[$fieldName] = $value.InnerText
    }

    # output resulting object
    [pscustomobject]$properties
}
    return $posts
}


#######################################
##
##   Initialize variables
##
#######################################

$feeds = @()
$feeds = ("https://www.kcra.com/topstories-rss","https://sacramento.cbslocal.com/feed/","https://abc7news.com/feed/","https://www.ksbw.com/topstories-rss")#, "https://www.sacbee.com/?widgetName=rssfeed&widgetContentId=6199&getXmlFeed=true")
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

$qry = @('accident','arrested','collision','crash','died','dies','fatal','hit-and-run','killing','shooting','suspects','Sutter','victim')
$cities = @('Antioch','Auburn','Brentwood','Citrus Heights','Elk Grove','Fairfield','Lodi','Oakdale','Oakland','Richmond','Rocklin','Roseville','Sacramento','San Francisco','San Jose','Stockton','Tracy','Vacaville','Vallejo','Yuba City')

####################################
##
##  Save each feed in a file
##
####################################

foreach($feed in $feeds) {
$i++

$doc.Load("$feed")
$doc.save("I:\RSS_Project\Feeds\feed-" + $i +".xml")
}


$files = Get-ChildItem "I:\RSS_Project\Feeds\" 
$files
#######################################
##
##  How best to get feeds, 
##  [xml](Invoke-WebRequest "https://sacramento.cbslocal.com/feed/")
##  [xml] (Invoke-WebRequest "https://www.sacbee.com/?widgetName=rssfeed&widgetContentId=6199&getXmlFeed=true")
##  $rss = [xml](Get-Content 'I:\RSS_Project\Feeds\feed-1.xml') from an array of files?
##  Maybe only on foreach loop needed if just load via web-request.  SacBee failed via Get-Content
##
#######################################

####################################
##
##  Process files
##
####################################
   
foreach($file in $files){
 $rss = [xml](Get-Content $file.FullName)
 ##$rss = [xml](Get-Content 'I:\RSS_Project\Feeds\feed-1.xml')
  
    $posts += Get-Posts $rss
    
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

foreach($term in $qry){
$filteredposts += $posts | where-object {($_.description -Match $term -or $_.Title -match $term)} | Select-Object $_

}

foreach($city in $cities){
$filteredlocations += $filteredposts | where-object {($_.description -Match $city -or $_.Title -match $city)} | Select-Object $_

}

####################################
##
##  Capture only unique Titles
##
####################################


$filtered = $filteredlocations | Sort-Object -Unique -Property Title
$Articles = $filtered.Count
$Subj = $feeds.Count.ToString() + ' RSS Feeds - ' + $posts.Count + ' posts filtered to ' + $Articles + ' articles' 

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

$HTMLposts = $posts | ConvertTo-Html -as Table -Property Title, description, link, pubDate -Fragment `
    -PreContent "<h3>Feeds pulled $feeds <br> $Subj </h3>"


$filtered = $filtered | ConvertTo-Html -as Table -Property Title, description, link, pubDate -Fragment `
    -PreContent "<h3> Filtered Feed Terms: $qry </h3>"|Out-String
$HTMLfiltered = $filtered -replace '(?<weblink>https:\/\/\S*)\<\/td\>', '<a href="${weblink}">Full_Story_Click_Here</a></td>'

$ResultsHTML = ConvertTo-Html -Body "$HTMLposts", "$HTMLfiltered" -Title "RSS Feed Report" -Head $Header `
 -PostContent "<br><h3> <br>Locations = $cities <br><br> Created on $strDate  by $env:UserName<br></h3>" `
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
    To= $TOGroup
    CC= $CCGroup
    Subject = $Subj
    Body = $ResultsHTML 
    SmtpServer = $mailserver 
}

Send-MailMessage @props -BodyAsHtml
}

$ResultsHTML| Out-File "a:\TestScript\RSS_Feed.html"
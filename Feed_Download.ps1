#################################
Function Get-Posts ($anyXMLfeed)
{ $fields = 'title','description','pubDate','link'

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
    return $posts
}

      




$feeds = @()
$feeds = ("https://www.kcra.com/topstories-rss","https://sacramento.cbslocal.com/feed/","https://abc7news.com/feed/","https://www.ksbw.com/topstories-rss")
$i = 0


$doc = New-Object System.Xml.XmlDocument
$qry = @('accident','arrested','collision','crash','died','dies','fatal','hit-and-run','killing','shooting','suspects','Sutter','victim')
$cities = @('Antioch','Auburn','Brentwood','Citrus Heights','Elk Grove','Fairfield','Lodi','Oakdale','Oakland','Richmond','Rocklin','Roseville','Sacramento','San Francisco','San Jose','Stockton','Tracy','Vacaville','Vallejo','Yuba City')

foreach($feed in $feeds) {
$i++
$i
$feed


$doc.Load("$feed")
$doc.save("I:\RSS_Project\Feeds\feed-" + $i +".xml")
}


$files = Get-ChildItem "I:\RSS_Project\Feeds\" 
$files
$posts=@()
   
foreach($file in $files){
 $rss = [xml](Get-Content $file.FullName)
 ##$rss = [xml](Get-Content 'I:\RSS_Project\Feeds\feed-1.xml')


 #$rss.SelectSingleNode('//item')|%{
 #   $posts += New-Object psobject -Property @{
 #       Title = If($_.Title."#cdata-section"){$_.Title."#cdata-section"}else{$_.Title}
 #       Desc = If($_.description."#cdata-section"){$_.description."#cdata-section"}else{$_.Title}
 #       link = If($_.link."#cdata-section"){$_.link."#cdata-section"}else{$_.link}
 #       pubDate = If($_.pubDate."#cdata-section"){$_.pubDate."#cdata-section"}else{$_.pubDate}
 #        }
 #    }

    $posts += Get-Posts $rss


}
## 
## \<.?p\> 

$posts | ForEach-Object {
    if ($_.description -match '<p>') {
        $_.description=$_.description -replace '(\<.?p\>)',''
        }
        $_.description
    }

$posts | Format-Table
 
$filtered = @()
$filteredlocations = @()
$filteredposts = @()


foreach($term in $qry){
$filteredposts += $posts | where-object {($_.description -Match $term -or $_.Title -match $term)} | Select-Object $_

}

foreach($city in $cities){
$filteredlocations += $filteredposts | where-object {($_.description -Match $city -or $_.Title -match $city)} | Select-Object $_

}




$filtered = $filteredlocations | Sort-Object -Unique -Property Title


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
TABLE tr:nth-child(even) td:nth-child(even){  background: #F2F2F2; }
TABLE tr:nth-child(odd) td:nth-child(odd){ background: #FFFFFF; }
</style>
"@
##########################################################
$strDate = (get-date).ToString("MM-dd-yyyy @ hh:mm tt")

$HTMLposts = $posts | ConvertTo-Html -as Table -Property Title, description, link -Fragment `
    -PreContent "<h3> All Feeds </h3>"


$filtered = $filtered | ConvertTo-Html -as Table -Property Title, description, link -Fragment `
    -PreContent "<h3> Filtered Feed Terms: $qry </h3>"|Out-String
$filtered = $filtered -replace '(?<weblink>https:\/\/\S*)\<\/td\>', '<a href="${weblink}">Full_Story_Click_Here</a>'

$ResultsHTML = ConvertTo-Html -Body "$HTMLposts", "$filtered" -Title "RSS Feed Report" -Head $Header `
 -PostContent "<br><h3> <br>Locations = $cities <br><br> Created on $strDate  by $env:UserName<br></h3>" `
 |Out-String   ##Out-File "a:\TestScript\RSS_Feed.html"


$ToGroup =  'Kathy Maggard <maggark@sutterhealth.org>'
$CCGroup = 'Darryl Gould <gouldd@sutterhealth.org>' ##For testing
$LiveRun = $false

if($LiveRun) {
$props = @{
    From = $CCGroup 
    To= $CCGroup
    CC= $CCGroup
    Subject = 'RSS Feeds - KCRA and CBS ' 
    Body = $ResultsHTML 
    SmtpServer = 'mail.sutterhealth.org' 
}


Send-MailMessage @props -BodyAsHtml
}

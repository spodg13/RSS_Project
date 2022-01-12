#################################
$cposts=@()

$CBS_Sac_Feed = [xml](Invoke-WebRequest "https://sacramento.cbslocal.com/feed/")
$CBS_Sac_Feed.rss.channel.item | Where-Object {$_.category."#cdata-section" -match 'Local'}|Select-Object Title, link, pubDate, @{Name="Desc"; Expression={$_.description."#cdata-section"}}|%{
    $cposts += New-Object psobject -Property @{
        Title = $_.Title
        Desc = $_.Desc
        link = $_.link
        pubDate = $_.pubDate
        }
 }       




$feeds = @()
$feeds = ("https://www.kcra.com/topstories-rss","https://sacramento.cbslocal.com/feed/","https://abc7news.com/feed/","https://www.ksbw.com/topstories-rss")
$i = 0


$doc = New-Object System.Xml.XmlDocument
$qry = @('killing', 'died', 'fatal', 'Sutter', 'crash', 'accident', 'shooting', 'victim' )

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
   
## foreach($file in $files){
 ##$rss = [xml](Get-Content $file.FullName)
 $rss = [xml](Get-Content 'I:\RSS_Project\Feeds\feed-1.xml')


 $rss.SelectNodes('//item')|%{
    $posts += New-Object psobject -Property @{
        Title = $_.Title
        Desc = $_.description
        link = $_.link
        pubDate = $_.pubDate
        
        }
    }

## 


$posts = $posts + $cposts

$filtered = @()

foreach($term in $qry){
$filtered += $posts | where-object {($_.Desc -Match $term -or $_.Title -match $term)} | Select-Object $_

}


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

$posts = $posts | ConvertTo-Html -as Table -Property Title, Desc, link -Fragment `
    -PreContent "<h3> All Feeds </h3>"


$filtered = $filtered | ConvertTo-Html -as Table -Property Title, Desc, link -Fragment `
    -PreContent "<h3> Filtered Feed Terms: $qry </h3>"

$ResultsHTML = ConvertTo-Html -Body "$posts", "$filtered" -Title "RSS Feed Report" -Head $Header `
 -PostContent "<br><h3> <br> Created on $strDate  by $env:UserName<br></h3>" `
 |Out-File "a:\TestScript\RSS_Feed.html"


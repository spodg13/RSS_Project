$rss.SelectSingleNode('//item')|%{
    $posts += New-Object psobject -Property @{
        Title = If($_.Title."#cdata-section"){$_.Title."#cdata-section"}else{$_.Title}
        Desc = If($_.description."#cdata-section"){$_.description."#cdata-section"}else{$_.Title}
        link = If($_.link."#cdata-section"){$_.link."#cdata-section"}else{$_.link}
        pubDate = If($_.pubDate."#cdata-section"){$_.pubDate."#cdata-section"}else{$_.pubDate}
         }
     }

##  Future scraping
##
##  Regex for two proper names:
##  (?:\s*\b(?<TwoName>[A-Z][a-z]+\s[A-Z][a-z]+)\b)+
##
##  Will need to add alternatives for First Middle Last or First M. Last

$WebResponse = Invoke-WebRequest "https://www.kcra.com/article/3-children-dead-mother-injured-merced-county-apartment/38752253"
$WebResponse.content


<####################################
    Alternate term and city searching

    instead of -contains $true - try adding boolean property to $posts


    $posts | Add-Member -MemberType NoteProperty -Name 'qryMatch' -Value $false
    update posts.qryMatch = $true

#####################################>


($qry|%{$posts.Title.Contains($_)}) -contains $true
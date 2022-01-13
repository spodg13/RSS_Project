$rss.SelectSingleNode('//item')|%{
    $posts += New-Object psobject -Property @{
        Title = If($_.Title."#cdata-section"){$_.Title."#cdata-section"}else{$_.Title}
        Desc = If($_.description."#cdata-section"){$_.description."#cdata-section"}else{$_.Title}
        link = If($_.link."#cdata-section"){$_.link."#cdata-section"}else{$_.link}
        pubDate = If($_.pubDate."#cdata-section"){$_.pubDate."#cdata-section"}else{$_.pubDate}
         }
     }
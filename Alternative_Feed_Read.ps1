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

    https://stackoverflow.com/questions/241789/parse-datetime-with-time-zone-of-form-pst-cest-utc-etc

#####################################>


($qry|%{$posts.Title.Contains($_)}) -contains $true


## test data
$b = @()
$b = ('UPDATE: Arrest Made In SoFi Stadium Assault Of 49ers Fan Daniel Luna',
'Con radars is dreams on sinch wear',
'Daniel Luna SoFi Assault suspect arrested',
'Klay Thompson dazzles in return shooting from deep',
'Shooting guard Thompson on fire from deep',
'Brendon Gould waves goodbye to soccer crowd at Woodcreek HS',
'Seniors play their last soccer game at Woodcreek High',
'Woodcreek HS beats Yuba City 3-0 for senior night soccer game',
'Seniors have big night for Woodcreek Soccer',
'Norrin Radd has cosmic awareness',
'Woodcreek seniors defeat Yuba City in soccer game',
'Babybel maker Bel Brands USA unveiled a new plant-based cheese Tuesday',
'Bel Brands USA already offers a dairy-free version of its Boursin cheese',
'Chances are your local grocery store now carries an array of plant-based items',
'Now hungry kids may be reaching for a cheese cocooned in another color -- lime green',
'Knowing how to take a screenshot is an essential skill',
'Mac you have three ways to take a screenshot',
'Apple gives you a fair number',
'Press and release the space bar',
'your initial selection area is off',
'Hold down the Shift key',
'embrace the Floating Thumbnail',
'Human rights activists had asked athletes to boycott the Ceremony',
'Chad Johnson raises good point about outrageous Super Bowl LVI ticket prices',
'Bill Riccette',
'Cincinnati Bengals fans have been dying to see their team back in the Super Bowl for decades')
$Titles_to_check=@()
$Titles_to_check = Get-InitialTitles $b
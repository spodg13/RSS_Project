################################
##  Text File  storage of Titles
################################

################################
##  CSV structure
##  PullDate, Period, FullTitle, CleanedTitle, Source, PubDate, link
################################

Function Update-Title($anyTitle)
{
    $TitleArray=@()
    $CommonWords =@('a','an','and','at','for','in','into','have', 'has', 'on','of','to','with')
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
    $TitleArray
    foreach ($word in $CommonWords){
            do {
                $word
                $TitleArray.Remove($word)
               } until ($TitleArray -notcontains $word ) 

    }          
    write-Host 'The removal'
     $TitleArray.Remove('The')
     $TitleArray.Remove('the')

     $TitleArray.Sort()
     $TitleArray.Count
     #Put back to string??
     return $TitleArray
}

Function Get-TitleComparison ($anyTitleArray, $RecentTitles)
{
    $i=0
    $SimTitles =@()
    $base = $anyTitleArray.Count
        #$RecentTitles = Import-Csv -Path "Titles.txt" -Property PullDate, Period, FullTitle, CleanedTitle,Source, PubDate
        # Count words - take smallest Clean.  Smallest/Biggest = max value, so accuracy would be 
        # Does length of word come close?  Jump - Jumping vs cod vs Codified
        foreach ($ct in $RecentTitles.CleanedTitle){
            foreach($word in $anyTitleArray){
                $word = $word + '*'
                if($RecentTitles.CleanedTitle -like $word ){
                    $i++
                }
            }
            $Accuracy = $i/$base
            if($Accuracy -gt .5){
                $SimTitles += [PSCustomObject]@{
                    PullDate    = $RecentTitles.PullDate
                    PubDate     = $RecentTitles.PubDate
                    Period      = $RecentTitles.Period
                    FullTitle   = $RecentTitles.FullTitle
                    Source      = $RecentTitles.Source 
                    Link        = $RecentTitles.link
                    Accuracy = $Accuracy   
                }
                return 
            }
        }
        return $Accuracy
    }        

$PullDate = (get-date).AddDays(-4).ToString() ##-Format "MM/dd/yyyy"
$CTitle = Update-Title 'The quick and agile brown and rust fox jumped to the window in a tall building at a stop light north of the andes mountains'
$PullDate
$RecentTitles =@()
$RecentTitles += [PSCustomObject]@{
    PullDate    = Get-Date
    PubDate     = Get-Date
    Period      = 'AM'
    FullTitle   = 'The quick and agile brown and rust fox jumped to the window in a tall building at a stop light north of the andes mountains'
    CleanedTitle = $CTitle
    Source      = 'KCRA'
    Link        = 'Any hyperlink'
}

#Get-Content I:\new\Titles.txt |     Where-Object { -not $_.Contains('H|159') } |     Set-Content C:\new\newfile.txt
$NewTitle = 'A quick brown fox was rumored to have jumped into the window of a building north of the andes mountains'
$NT = Update-Title $NewTitle
Get-TitleComparison $NT $RecentTitles
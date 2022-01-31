################################
##  Text File  storage of Titles
################################

################################
##  CSV structure
##  PullDate, Period, FullTitle, CleanedTitle, Source, PubDate, link
################################

Function Update-Title($anyTitle)
{
    $CommonWords =@('a','an','and','at','for','in','into','have', 'has', 'on','of','to','with')
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
    $TitleArray | Sort-Object -Unique 
    $TitleArray
    #$TitleArray.ToLower()
    foreach ($word in $CommonWords){
            do {
                $TitleArray.Remove($word)
               } until ($TitleArray -notcontains $word ) 

    }          
    write-Host 'The removal'
     #$TitleArray.Remove('The')
     #$TitleArray.Remove('the')

     $TitleArray.Sort()
     $TitleArray.Count
     
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
        # Compare-Object $a $b -PassThru -IncludeEqual # union
        # Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent # intersection
        #https://stackoverflow.com/questions/8609204/union-and-intersection-in-powershell
        #https://stackoverflow.com/questions/55162668/calculate-similarity-between-list-of-words
        <#  Python
        from collections import Counter
        import math

        counterA = Counter(list_A)
        counterB = Counter(list_B)


        def counter_cosine_similarity(c1, c2):
            terms = set(c1).union(c2)
            dotprod = sum(c1.get(k, 0) * c2.get(k, 0) for k in terms)
            magA = math.sqrt(sum(c1.get(k, 0)**2 for k in terms))
            magB = math.sqrt(sum(c2.get(k, 0)**2 for k in terms))
            return dotprod / (magA * magB)

        print(counter_cosine_similarity(counterA, counterB) * 100)
        #>

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
$CTitle = Update-Title 'The quick And agile brown and rust Fox jumped to the window in a tall building at a stop light north of the andes Mountains'
$PullDate
$CTitle
#$RecentTitles =@()
#$RecentTitles += [PSCustomObject]@{
#    PullDate    = Get-Date
#    PubDate     = Get-Date
#    Period      = 'AM'
#    FullTitle   = 'The quick and agile brown and rust fox jumped to the window in a tall building at a stop light north of the andes mountains'
#    CleanedTitle = $CTitle
#    Source      = 'KCRA'
#    Link        = 'Any hyperlink'
#}

#Get-Content I:\new\Titles.txt |     Where-Object { -not $_.Contains('H|159') } |     Set-Content C:\new\newfile.txt
#$NewTitle = 'A quick Brown fox was rumored to have jumped into the window of a Wal-Mart building north of the andes mountains'
#$NT = Update-Title $NewTitle
#$NT
##Get-TitleComparison $NT $RecentTitles
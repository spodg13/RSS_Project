################################
##  Text File  storage of Titles
################################

################################
##  CSV structure
##  PullDate, Period, FullTitle, CleanedTitle, Source, PubDate, link
################################

Function Get-CleanTitle([string]$anyTitle)
{
    $CleanList=@()
    $CleanList =@('a','an','and','at','for','in','into','have', 'has', 'on','of','to','the','with')
    $anyTitle.ToLower()
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
    $TitleArray | Sort-Object -Unique 
   
    #Run twice as loop was not working right     
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
   
    $TitleArray.Sort()
    $TitleArray.Count
     
    return $TitleArray
}

     
        # Compare-Object $a $b -PassThru -IncludeEqual # union
        # Compare-Object $a $b -PassThru -IncludeEqual -ExcludeDifferent # intersection
        #https://stackoverflow.com/questions/8609204/union-and-intersection-in-powershell
        #https://stackoverflow.com/questions/55162668/calculate-similarity-between-list-of-words
        <#
        
            terms = intersection of two arrays a1 and a2
            for each term in terms{
            dotprod = sum(a1.term * a2.term)

            magA = math::sqrt(sum(a1.term^2))
            magB = math::sqrt(sum(a2.term^2))
            }
            return dotprod / (magA * magB)
                    
        #>


$PullDate = (get-date).AddDays(-4).ToString() ##-Format "MM/dd/yyyy"
write-host 'Date: ' $PullDate
$mytitle = 'The quick agile brown and rust Fox jumped to the window in a tall building north of Andes Mountains'

$CTitle = Get-CleanTitle $mytitle.ToLower()

$PullDate
$CTitle

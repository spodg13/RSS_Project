################################
##  Text File  storage of Titles
################################

################################
##  CSV structure
##  PullDate, Period, FullTitle, CleanedTitle, Source, PubDate
################################

Function Clean-Title($anyTitle)
{

    $CommonWords =@('a','an','and','for','in','on','of','the','to','with')
    foreach ($word in $anyTitle){

        if($word -match $CommonWords ){
            $anyTitle -replace (\b$word), ''
        }

    }

    $anyTitle


}


$PullDate = (get-date).AddDays(-4).ToString() -Format "MM/dd/yyyy"
Clean-Title 'The quick brown fox jumped to the window in a tall building'
#Get-Content I:\new\Titles.txt |     Where-Object { -not $_.Contains('H|159') } |     Set-Content C:\new\newfile.txt

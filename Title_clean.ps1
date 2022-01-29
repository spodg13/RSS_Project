################################
##  Text File  storage of Titles
################################

################################
##  CSV structure
##  PullDate, Period, FullTitle, CleanedTitle, Source, PubDate
################################

Function Update-Title($anyTitle)
{
    $TitleArray=@()
    $CommonWords =@('a','an','and','at','for','in','on','of','to','with')
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

     $TitleArray
}

$PullDate = (get-date).AddDays(-4).ToString() ##-Format "MM/dd/yyyy"
Update-Title 'The quick and agile brown and rust fox jumped to the window in a tall building at a stop light north of the andes mountains'
$PullDate
#Get-Content I:\new\Titles.txt |     Where-Object { -not $_.Contains('H|159') } |     Set-Content C:\new\newfile.txt

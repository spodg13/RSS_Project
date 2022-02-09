Function Get-SimTitles([psobject]$NewPosts) {
  ## For testing accuracy purposes

  $CKTitles = $NewPosts
  $Vresults =@()

  foreach ($Ck in $CkTitles.title) {
    $NewPosts | Where-Object {$_.source -ne $CKTitles.source} | Where-Object{ ($score=Measure-TitleSimilarity $Ck.ToCharArray() $_.title.toCharArray()) -lt 1 -and $score -gt .1}  |
     Select @{Name = 'Score'; E={$score} }, @{Name = 'Title'; E={$Ck} }, @{Name = 'Comp_Title'; E={$_.title} }, @{Name = 'Date'; E={Get-Date -Format "MM-dd-yy HH:mm"} } | Export-CSV "I:\RSS_Project\Check_Title_letter.csv" -Append
                      

          } 
       } 


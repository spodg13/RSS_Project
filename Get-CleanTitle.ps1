Function Get-CleanTitle([string]$anyTitle)
{
    $anyTitle =$anyTitle -replace ',|\?', '' 
    $CleanList =@('a','an','and','as','at','for','in','into','have', 'has', 'on','of','to','the','with')
    $anyTitle=$anyTitle.ToLower()
    [System.Collections.ArrayList]$TitleArray = $anyTitle.split(' ')
       
    #Run twice as loop was not working right     
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
    $CleanList | %{if($_ -in $TitleArray){$TitleArray.Remove($_)} } 
        
    return $TitleArray | Sort-Object -Unique 
}
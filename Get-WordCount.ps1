Function Get-WordCount($anyposts)
{

    $titlestring = $anyposts.title -join ' '
    $titlestring = $titlestring.split(' ')

    $CleanList =@('a','after','an','and','as','at','for','from','I','in','into','is','have', 'has','her','him','man', 'on','of','s','t','to','the','with','woman','')
    $dirtylaundryterms = @('accident','armed','arrest', 'arrested','collision','crash','DUI','fatal','hit-and-run','homicide','police','sheriff','shooting','shot','suspects','Sutter','victim')
    
    $frequency = $titlestring -split '\W+' |
    Group-Object -NoElement |
    Sort-Object count -Descending | 
    Where-Object {$_.name -notin $CleanList -and $_.name -notin $dirtylaundryterms} |
    Where-Object{$_.count -gt 2} | Select-Object 

    return $frequency
}

$results = Get-WordCount $NewPosts
$results
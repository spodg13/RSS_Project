function Get-Substitute ($anycipher, $anyshift, $anyalphabet){
    
    foreach ($schar in $anycipher){
            
       $ind = $anycipher.IndexOf('G')
        Write-Host $ind  $schar
                   
        
        }    
    
    return 
}
$cipher = 'GO HRCDOGCDH OUWDH U HOUOD RI HRQGOPAD OR LFGTM OR CGTA OJD FDUQ BRKDF RI XRCBUTGRTHJGB'
$cipher = $cipher.ToUpper()

$ajoined = $cipher -join “ ”
$charset = $ajoined.ToCharArray()


$alphabet = ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',' ')
$alphabet = $alphabet.ToUpper()

$ajoinedUC = $ajoined.ToUpper()

$test = ($ajoinedUC.GetEnumerator() | Group-Object -NoElement | Sort-Object Count -Descending -top 5).Name

write-host $test
foreach ($letter in $test) {
    if ($letter -ne " "){
       $shift = [array]::indexof($alphabet,$letter) - 4
       write-host $letter  ' has a shift of ' $shift
       Get-Substitute $charset $shift $alphabet
    }   

}





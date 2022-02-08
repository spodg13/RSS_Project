[string]$s = 'Fri, 28 Jan 2022 05:00:00 GMT'


$cfo=[string[]]('ddd MMM d HH:mm:ss yyyy');
$ic=[Globalization.CultureInfo]::InvariantCulture;
$lc=if($env:culture){try{[Globalization.CultureInfo]$env:culture}catch{exit 1}}else{$null};
try{$dt=[DateTime]::ParseExact($s,$cfo,$ic,15)}
    catch{
            try{$dt=[DateTime]::ParseExact($s,$cfo,$lc,15)}
            catch{
                try{$dt=[Management.ManagementDateTimeConverter]::ToDateTime($s)}
                    catch{
                            $s=$($s -replace '(\d),(\d)','$1.$2') -replace 'Z\b','+0:00';
                             try{$dt=[DateTime]::Parse($s,$ic,143)}
                             catch{
                                try{$dt=[DateTime]::Parse($s,$lc,143)}
                                    catch{ 
                                            Write-host 'exiting'
                                            exit 1
                                          }
                                  }
                         }
                  }
          }
$dow=[int]$dt.DayOfWeek;$cw=$(Get-Culture).Calendar.GetWeekOfYear($(if($dow -match '[1-3]'){$dt.AddDays(3)}else{$dt}),2,1);
$yow=if($dt.Month -eq 1 -and $cw -gt 51){$dt.Year-1}else{$dt.Year};
($dt.toString('yyyy MM dd HH mm ss fff ')+$dow+$dt.DayOfYear.toString(' 000')+$cw.toString(' 00')+$yow.toString(' 0000'))
$dt

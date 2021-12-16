#######################  Aktualna data i data utworzenia skryptu ####################### 

    $data = Get-Date 
    ${TIMESTAMP}  = "{0:MM-dd-yyyy}" -f ($data) 
    ${TIMESTAMP}
    $data

#######################  Change log ####################### 

    $skrypt = "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie_8.ps1"
    $log = "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"

    # tworzy changelog
    $skrypt_log = Get-ItemProperty $skrypt | Format-Wide -Property CreationTime
    "#######################  Change log #######################`n`nData utworzenia skryptu:" > "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"

    # zapisuje date utworzenia 
    $skrypt_log >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"





####################### Pobieranie pliku #######################

    #lokalizacja pliku źródłowego 
    $url = "https://home.agh.edu.pl/~wsarlej/Customers_Nov2021.zip"

    #mijsce zapisu pliku
    $plik = "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.zip"

    #pobieranie pliku 
    Invoke-WebRequest -Uri $url -OutFile $plik

    Write-Host "`nPobieranie pliku działa"

    $data = Get-Date 
    $data, "   -   Pobieranie pliku   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"

    


####################### Rozpakowanie pliku #######################

    #scieżka do winra
    $WinRAR = "C:\winrar\WinRAR.exe"
    $haslo = "agh"

    #ustawienie lokalizacji
    Set-Location C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8

    #rozpakowywanie 
    Start-Process "$WinRAR" -ArgumentList "x -y `"$plik`" -p$haslo"


    Write-Host " `nRozpakowywanie pliku działa "

    $data = Get-Date 
    $data, "   -   Rozpakowanie pliku   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"


####################### Poprawność pliku #######################


    $nrIndeksu = "401290"
    $Plik_1 = Get-Content "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.csv"
   
    #szuka pustych lini  
    $poprawny_plik = for($i = 0; $i -lt $Plik_1.Count; $i++)
                     {
                      if($Plik_1[$i] -ne "")
                         {
                             $Plik_1[$i]  
                         }
                     } 
    
    #plik z błędnymi wierszami
    $poprawny_plik[0] > "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.bad_${TIMESTAMP}"


    #porównaj plik wejściowy z plikiem Customers_old.csv, pozostaw te wiersze, które nie występują w pliku Customers_old.csv
    $Plik_2 = Get-Content "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_old.csv"
    for($i = 1; $i -lt $poprawny_plik.Count; $i++)
    {
      for($j = 0; $j -lt $Plik_2.Count; $j++)
        {
           if($poprawny_plik[$i] -eq $Plik_2[$j])
             {
                 $poprawny_plik[$i] >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.bad_${TIMESTAMP}"
                 $poprawny_plik[$i] = $null
              }
       }
     } 
   
    #końcowy plik po walidacji
    $poprawny_plik > "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.csv" 
    
    Write-Host " `nPoprawność pliku działa "


    $data = Get-Date 
    $data, "   -   Poprawność pliku  -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"




####################### Dodawanie tabeli #######################


    #ustawianie lokalizacji
    Set-Location 'D:\PostgresSQL\bin\'

    
    #logowanie do postgresa
    $env:USER = "postgres"
    $env:PGPASSWORD =  'postgres'
    $env:DATABASE = "postgres"
    $env:NEWDATABASE = "cw8"
    $env:TABLE = "CUSTOMERS_$nrIndeksu"
    $env:SERVER  ="PostgreSQL 13"
    $env:PORT = "5432"


    #dodawanie tabeli
    psql -U postgres -d $env:NEWDATABASE -w -c "DROP TABLE IF EXISTS $env:TABLE"
    psql -U postgres -d $env:DATABASE -w -c "DROP DATABASE IF EXISTS $env:NEWDATABASE"
    psql -U postgres -d $env:DATABASE -w -c "CREATE DATABASE $env:NEWDATABASE"
    psql -U postgres -d $env:NEWDATABASE -w -c "CREATE TABLE IF NOT EXISTS $env:TABLE (first_name VARCHAR(100), last_name VARCHAR(100) PRIMARY KEY, email VARCHAR(100), lat VARCHAR(100) NOT NULL, long VARCHAR(100) NOT NULL)"

    
    Write-Host " `nPoprawność pliku działa "

    $data = Get-Date 
    $data, "   -   Dodawanie tabeli   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"



####################### Załadowanie danych #######################


    #zamiana , na ','
    $poprawny_plik_2 = $poprawny_plik -replace ",", "','"


    #wczytywanie danych do tabeli
    for($i=1; $i -lt $poprawny_plik_2.Count; $i++)
    {
        $poprawny_plik_2[$i] = "'" + $poprawny_plik_2[$i] + "'"
        $wczytaj = $poprawny_plik_2[$i]
        psql -U postgres -d $env:NEWDATABASE -w -c "INSERT INTO $env:TABLE (first_name, last_name, email, lat, long) VALUES($wczytaj)"
    }
    
    #wyświetlenie tabeli
    psql -U postgres -d $env:NEWDATABASE -w -c "SELECT * FROM $env:TABLE"

    Write-Host " `nPzaładowanie danych działa "
    

    $data = Get-Date 
    $data, "   -   Załadowanie danych   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"



####################### Przeniesienie pliku #######################
    
    #stworzenie katalogu PROCESSED
    New-Item -Path 'C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\PROCESSED' -ItemType Directory

    Set-Location C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8

    #przeniesienie do podkatalogu i zmiana nazwy
    Move-Item -Path "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.csv" -Destination "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\PROCESSED" -PassThru -ErrorAction Stop
    Rename-Item -Path "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\PROCESSED\Customers_Nov2021.csv" "${TIMESTAMP}_Customers_Nov2021.csv"

    Write-Host " `nprzeniesienie pliku działa "

   
    $data = Get-Date 
    $data, "   -   Przeniesienie pliku   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"



####################### Wysłanie maila #######################


    #ponowne wczytanie plików
    $Plik_zinternetu = $Plik_1
    $poprawny_plik = Get-Content "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\PROCESSED\${TIMESTAMP}_Customers_Nov2021.csv"
    $plik_bledy = Get-Content "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Customers_Nov2021.bad_${TIMESTAMP}"


    #oblicznia
    $wszystkie_wiersze = $Plik_zinternetu.Count
    $wszystkie_wiersze
    $wiersze_po_czyszeniu = $poprawny_plik.Count
    $wiersze_po_czyszeniu
    $duplikaty = $plik_bledy.Count
    $duplikaty
    $dane_tabela = $poprawny_plik.Count -1
    $dane_tabela


    #wywłanie maila
    $MyEmail = "aleksandra37.juras@gmail.com"
    $SMTP= "smtp.gmail.com"
    $To = "dfoltaa@gmail.com"
    $Subject = "CUSTOMERS LOAD - ${TIMESTAMP}"
    $Body = "liczba wierszy w pliku pobranym z internetu: $wszystkie_wiersze`n
    liczba poprawnych wierszy (po czyszczeniu): $wiersze_po_czyszeniu`n
    liczba duplikatow w pliku wejsciowym: $duplikaty`n 
    ilosc danych zaladowanych do tabeli: $dane_tabela `n"

    $Creds = (Get-Credential -Credential "$MyEmail")

    Send-MailMessage -To $MyEmail -From $MyEmail -Subject $Subject -Body $Body -SmtpServer $SMTP -Credential $Creds -UseSsl -Port 587 -DeliveryNotificationOption never
   
    Write-Host " `nWysłanie maila działa działa "


    $data = Get-Date 
    $data, "   -   Wysłanie maila   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"



    ####################### Kwerenda SQL ###############################

    #utworenie pliku txt
    New-Item -Path 'C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\zapytanie.txt' -ItemType File

    #wisanie do pliku kwerendy
    Set-Content -Path 'C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\zapytanie.txt' -Value " 
     alter table CUSTOMERS_401290 alter column lat type double precision using lat::double precision;
    alter table CUSTOMERS_401290 alter column long type double precision using long::double precision;

    SELECT first_name, last_name  INTO best_customers_400581 FROM customers_401290
				WHERE ST_DistanceSpheroid( 
			ST_Point(lat, long), ST_Point(41.39988501005976, -75.67329768604034),
			'SPHEROID[""WGS 84"",6378137,298.257223563]') <= 50000"
			
    #sprawdzenie czy tabela już nie istnieje
    $NOWATABELA = "BEST_CUSTOMERS_401290"
    psql -U postgres -d $env:NEWDATABASE -w -c "DROP TABLE IF EXISTS $NOWATABELA"

    #uruchomienie zapytania
    psql -U postgres -d $env:NEWDATABASE -w -c "CREATE EXTENSION postgis"
    psql -U postgres -d $env:NEWDATABASE -w -f "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\zapytanie.txt"
   
    Write-Host " `nKwerenda SQL działa "
  
          $data = Get-Date 
    $data, "   -   Kwerenda SQL   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"


    ####################### Export tabeli #######################
    
    #zapisuje tabele
    $zapis = psql -U postgres -d $env:NEWDATABASE -w -c "SELECT * FROM $NOWATABELA" 
    $zapis
    $tab = @()

    #????
    for ($i=2; $i -lt $zapis.Count-2; $i++)
    {
        $dane = New-Object -TypeName PSObject
        $dane | Add-Member -Name 'first_name' -MemberType Noteproperty -Value $zapis[$i].Split( "|")[0]
        $dane | Add-Member -Name 'last_name' -MemberType Noteproperty -Value $zapis[$i].Split( "|")[1]
        $dane | Add-Member -Name 'odleglosc' -MemberType Noteproperty -Value $zapis[$i].Split( "|")[2]
        $tab += $dane
    }

    #ekspoert tabeli 
    $tab | Export-Csv -Path "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\$NOWATABELA.csv" -NoTypeInformation


    Write-Host " `nExport tabeli działa "

    $data = Get-Date 
    $data, "   -   Export tabeli   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"



    ####################### Skompresowanie pliku #######################


    Compress-Archive -Path "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\$NOWATABELA.csv" -DestinationPath "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\$NOWATABELA.zip"

    Write-Host " `nSkompresowanie pliku działa "

    $data = Get-Date 
    $data, "   -   Skompresowanie pliku   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"



    ####################### Wysłanie pliku mailem #######################

    #dodanie daty utworzenia
    Get-ItemProperty "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\$NOWATABELA.csv" | Format-Wide -Property CreationTime > "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\data.txt"
    $data = Get-Content "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\data.txt"

    Remove-Item -Path "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\data.txt"

    #zapis danych
    $wiersze = $zapis.Count -3
    $Skompresowany_plik = "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\$NOWATABELA.zip"
    
    #utworzenie treści 
    $Body2 = "`n`nData ostatniej modyfikacji pliku:$data
    Ilosc wierszy w pliku CSV:   $wiersze"

    $Creds = (Get-Credential -Credential "$MyEmail")

    #wysłanie maila
    Send-MailMessage -To $To -From $MyEmail -Subject $Subject -Body $Body2 -Attachments $Skompresowany_plik -SmtpServer $SMTP -Credential $Creds -UseSsl -Port 587 -DeliveryNotificationOption never

    $data = Get-Date 
    $data, "   -   Wysłanie pliku mailem   -   Successful!" >> "C:\Users\folta\Desktop\Bazy_danych_przestrzennych\cwiczenie8\Cwiczenie8_${TIMESTAMP}.log"

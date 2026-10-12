# Utkast — e-post till DA (2026-10-07)

Ämne: Resultat sedan 28/9 — indexkonstruktion, timkalibrering, kontotäckning, E4

Hej David,

Här följer en sammanfattning av arbetet sedan 28/9. Analyspipelinen har
körts två gånger i TRE (5/10 och 7/10) med oförändrad specifikation, och
resultaten är identiska mellan körningarna. Nuvarande export finns i
TRE_output/; samtliga 16 automatiska kontroller är godkända. Underlaget
per punkt redovisas i den bifogade briefen.

1. Indexkonstruktion. Huvudanalysen använder nu den preregistrerade
konstruktionen utan q11b_7 (e-handel) och q11b_8 (onlineförsäljning), 11
item som z-standardiseras före aggregering. M0–M5 ger 179.7, 274.2, 197.8,
197.0, 202.3 respektive 203.9 kg CO2e per index-SD (M5: SE 32.3, 95 % KI
140.7–267.2, p = 2.9e-10, R² = 0.366, N = 4 250 konstant). Att återta
e-handel och onlineförsäljning ger +214.3, 5.1 % över huvudskattningen; de
två posterna förklarar alltså inte sambandet. Däremot är q11b_2 (samtal)
det enskilt största itemet (+385 kg per item-SD), och ett index utan
samtal ger +140.8 (−31 %). Frågan om samtalsitemet kvarstår; min
rekommendation är 11 item som huvudspecifikation och 10 item som
registrerad känslighetsanalys. Om normalisering: item standardiseras före
aggregering, så itemvarians påverkar inte vikterna. Skillnaden mellan de
tidigare redovisade värdena (+243 och +180) beror på vilket urval som
använts för standardiseringen; under nuvarande specifikation ger de två
alternativen +202.7 och +203.9.

2. Timkalibrering. Den tidigare inkonsekvensen (0.369 mot 0.317 timmar per
index-SD) berodde på att indexets standardavvikelse och ankarkoefficienten
hämtats från olika urval och skalor. Samtliga omräkningar utgår nu från en
dokumenterad enhet: ankarkoefficient b = 0.3384 timmar per index-SD
(SE 0.0577, n = 2 082, p = 5.2e-9, R² = 0.018); M5 ger 468.1 kg per rå
indexenhet, 203.9 per index-SD och 602.6 kg per timme, där den härledda
timskatten är identisk med den direkta skattningen. Kontrolltabellen finns
i calibration_check.csv; tre interntester är uppfyllda. Per-SD används som
huvudskala och timvärdet redovisas som sekundärt. Kvarstår: timskarnas
konfidensintervall behandlar ankaret som känt (SE/b ≈ 17 %); osäkerheten
kan propageras med deltametoden.

3. Kontotäckning. M5 med antal konton som regressor ger −10.7 % och med
fasta effekter för antal konton −10.8 %, båda med kvarvarande signifikans
(p ≈ 1e-08). Stratumskattningar: 1 konto +113.2 (p = .032), 2 konton
+104.8 (p = .062), 3 konton +234.2 (p = .0004), 4+ konton +298.9
(p = .00014). Utfallet utgifter/registerinkomst ger +0.140 (p = .050) och
CO2e/registerinkomst +221.6 kg per 100 tkr (p = .014). För urvalet med
utgifter inom 50–150 % av registerinkomsten blir skattningen +154.7 (−24.1 %
mot huvudskattningen). Kontotäckning förklarar alltså inte sambandet;
högsta avvikelsen i någon restriktion är 24 %. Att gradienten är
koncentrerad till deltagare med 3–4+ konton kan tolkas som
mätningsfel hos glest täckta, eller som systematiska skillnader i
ekonomisk komplexitet. Medelvärdet på indexet är likartat mellan
kontogrupperna medan inkomst och utgifter ökar med antalet konton.

4. Itemnivåfiguren. Figuren genereras nu direkt från den slutliga tabellen.
Avvikelsen som rapporterades 25/9 berodde på att etiketter och skattningar
sorterades oberoende i plottkoden; CSV-filens värden var korrekta. En
automatisk kontroll verifierar att varje etikett har rätt skattning och
intervall, och kontrollen körs vid varje export.

5. E4. Fördelningen är utan anmärkningar (medel 4.39 h/dag, median 3.95,
SD 2.41; n = 2 200 giltiga rapporter efter 0–18 h-regeln). Stapling vid
exakt :00 (5.1 %) och :00/:30 (10.3 %) är förenlig med värden avlästa från
skärmen och inmatade manuellt. E4 korrelerar svagt men signifikant med
indexet (r = 0.134; starkast med sociala medier, r = 0.176); någon separat
självskattad skärmtidsfråga finns inte i enkäterna. Ingen variabel för
iOS/Android finns i utdraget, så den föreslagna uppdelningen kan inte
genomföras; det återstår att kontrollera om variabeln finns i
endline-kodboken eller i appdata. E4 har ingen oberoende koppling till
konsumtionsbaserade utsläpp: +65.6 kg per E4-SD (p = .148) i separat M5,
+29.1 (p = .52) i gemensam modell medan indexet behåller sin skattning
(+233.4); skillnaden i lutningar är +204.3 (p = .0039) och mönstret är
detsamma i samtliga kategorier. Två kategorier är signifikant positiva för
E4: digitala tjänster +0.97 kg/h (p = .001) och kläder +3.5 kg/h (p = .032).
Tolkningen är att E4 mäter enhetsregistrerad skärmtid på ett rimligt sätt,
men att denna fångar en annan dimension än självskattad digital aktivitet.
Eventuell vidare analys: begränsa ankarsamplingsurvalet till respondenter
som klarar kontrollfrågan (C11), och plattformsuppdelning om variabeln kan
anskaffas.

6. Reproducerbart underlag. Exporten innehåller samtliga skript (20–68) med
körfilen RUN_TRE.R, README med indexdefinitioner och urvalsregler,
datadictionary för samtliga redovisade kolumner, körmanifest (run_info.csv)
och verifieringsskriptet med 16 kontroller. Resultat från olika
genereringar blandas inte; den första versionen av exporten är arkiverad
separat.

Utöver punkterna ovan, två analyser som tillkommit efter 28/9:

- Volym mot komposition. Av M5-gradienten på 203.9 kg CO2e/SD utgörs 96.2 %
  (196.1 kg) av ökad utgiftsvolym vid oförändrad korgintensitet;
  kompositionsbidraget är 26.9 kg (13.2 %, p = .17) och
  korgintensitetslutningen +0.105 kg per 1 000 kr (p = .17). Den
  justerade skillnaden mellan extremkvintilerna är +599 kg CO2e (+13.3 % av
  medelvärdet) på +31 914 kr utgifter, medan registerinkomsten ökar 7.6 %
  mellan kvintilerna. Sambandet uttrycks alltså huvudsakligen i
  konsumtionsvolym, inte i en mer koldioxidintensiv korg.
- Fritidsmekanismen (E1). Den registrerade hypotesen om lägre
  fritidsaktivitet utanför hemmet får inte stöd: associationen är positiv
  (+0.073 poäng per index-SD, p = 8.8e-05 för kompositen utanför hemmet,
  +0.137 för hemmeaktivitet, p = 1e-13). Medieringsandelen av
  transportgradienten är 1.8 % respektive 9.6 % med båda mediatorierna, och
  mediatorkoefficienterna är inte signifikanta. Jag föreslår att resultatet
  redovisas som ett registrerat negativt resultat, med en daterad
  avvikelsetabell mot preregistreringen.

Kvar att besluta: (i) samtalsitemet i eller utanför huvudindexet; (ii)
redovisning av RQ3 som negativt resultat och avvikelsetabellens omfattning;
(iii) formuleringen i abstractet, där timskalen bör ges en sekundär roll
med tanke på ankarets förklarade varians (R² = 0.018); (iv) om en
plattformsvariabel kan anskaffas.

Hälsningar,
Mikael

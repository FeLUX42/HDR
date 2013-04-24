echo "erzeuge 'HDR' Bilder"

echo "convert to tif"
RAW=0

for file in $(ls ./*.NEF ); do
	RAW="1"
	echo "convert: $file"
	ufraw-batch --wb=camera --gamma=0.45 --linearity=0.00 --exposure=0.0 --saturation=1.0 --rotate=camera --out-depth=16 --zip --out-type=tiff --overwrite --create-id=no $file
done

if [ $RAW != "1" ] 
then
	for file in $(ls ./*.JPG ); do
		echo "convert: $file"
		#convert "./zzz_verkleinern/$file" -resize '1920x1920>' -quality 88% "./zzz_verkleinern/klein/klein-$file"
		convert "./$file" "./$file.tif"
	done
fi


if [ $RAW -eq "1" ]
then 
	PREF="DSC_????"
else
	PREF="DSC_????.JPG"
fi

echo "aligning"
align_image_stack -a align $PREF.tif



echo "generiere hdr mit enfuse"
enfuse -o enfuse.tif align????.tif

echo "convert back to jpg"
convert enfuse.tif -quality 95 hdr.jpg

echo "compressing enfuse"
convert enfuse.tif -compress zip enfuse.tif

touch hdr.jpg


echo "hdrgen"

touch hdrgen.hdrgen
I=0
if [ $RAW != "1" ] 
then
	#jpeg2hdrgen DSC*.JPG > hdrgen.hdrgen
	for file in $(ls DSC*.JPG ); do
		this=$(printf "%.4d" "$I")
		dat=`echo $file | sed -e "s/DSC.*JPG/align$this.tif/" `
		time=`exiftool -exposuretime $file | sed 's/.*: //g' | sed 's|1/||'`
		blende=`exiftool -fnumber $file | sed 's/.*: //g' `
		iso=`exiftool -iso $file | sed 's/.*: //g'`
		
		toecho="$dat $time $blende $iso 0"
		echo $toecho >> hdrgen.hdrgen
		echo $toecho
		I=$(($I+1))
	done
	pfsinhdrgen hdrgen.hdrgen | pfshdrcalibrate -b 8 -x  | pfsout pfs.hdr
else
	for file in $(ls  *.NEF ); do

		this=$(printf "%.4d" "$I")
		dat=`echo $file | sed -e "s/DSC.*NEF/align$this.tif/" `
		time=`exiftool -exposuretime $file | sed 's/.*: //g' | sed 's|1/||'`
		blende=`exiftool -fnumber $file | sed 's/.*: //g'`
		iso=`exiftool -iso $file | sed 's/.*: //g'`
		
		toecho="$dat $time $blende $iso 0"
		echo $toecho >> hdrgen.hdrgen
		echo $toecho
		I=$(($I+1))
	done
	pfsinhdrgen hdrgen.hdrgen | pfshdrcalibrate -b 16 -x  | pfsout pfs.hdr
	#dcraw2hdrgen DSC*.NEF | sed -e "s/NEF/tif/" > hdrgen.hdrgen
fi



echo "pfstmo"
pfsin pfs.hdr | pfstmo_mantiuk06 -e 1 -s 1 | pfsgamma --gamma 2.2 | pfsoutimgmagick pfstmo_mantiuk06.tif
pfsin pfs.hdr | pfstmo_fattal02 -s 1 | pfsoutimgmagick pfstmo_fattal02.tif 
pfsin pfs.hdr | pfstmo_reinhard02 --key 0.5 --phi 1 -s 1  | pfsoutimgmagick pfstmo_reinhard02.tif 

convert pfstmo_fattal02.tif -compress zip pfstmo_fattal02.tif 
convert pfstmo_mantiuk06.tif -compress zip pfstmo_mantiuk06.tif
convert pfstmo_reinhard02.tif -compress zip pfstmo_reinhard02.tif 


for file in $(ls  ./DSC*.tif ); do
	rm $file
done
rm *.ufraw
rm align*
rm hdrgen.hdrgen


echo "finish" 


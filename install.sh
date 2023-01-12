path="~/.config/mpv/scripts/subcliper"

if [ ! -d $path ]; then
	mkdir $path
fi

for FILE in *.lua 
do
	cp $FILE $path
done

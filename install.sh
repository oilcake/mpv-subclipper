path=~/.config/mpv/scripts/subcliper

if [ ! -d $path ]; then
	mkdir -p $path
fi

for FILE in *.lua 
do
	cp $FILE $path
done

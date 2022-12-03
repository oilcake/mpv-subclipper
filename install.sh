path="/Users/Oilcake/.config/mpv/scripts/subcliper"
file="main.lua"
target="$path/$file"
if [ ! -d $path ]; then
	mkdir $path
fi

for FILE in *.lua 
do
	cp $FILE $path
done
# if [ ! -f $target ]; then
#     touch $target
# fi
#
# cat subclipper.lua > $target

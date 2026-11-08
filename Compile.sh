
# Argument1 = Input.asm
# Argument2 = Output.gb

../rgbasm -o Temp.o $1 ;
../rgblink -o $2 Temp.o ;
../rgbfix -v -p 0xFF $2 ;
../PICboy.o $2 000 ;


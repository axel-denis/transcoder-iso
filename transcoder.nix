with builtins;
lib: transcoderFile:
lib.replaceString "ENCODER" (readFile transcoderFile) (readFile ./main.sh)

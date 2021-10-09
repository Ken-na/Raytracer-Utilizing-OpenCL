@rem doskey magick = c:\Program Files\ImageMagick-7.0.10-Q8\magick.exe



magick compare -metric mae Outputs\a03s05t01.bmp Outputs_REFERENCE\donuts.txt_2048x2048x1_Stage5.exe.bmp  Outputs\stage5diff_01.bmp
magick compare -metric mae Outputs\a03s05t02.bmp Outputs_REFERENCE\donuts.txt_2048x2048x2_Stage5.exe.bmp  Outputs\stage5diff_02.bmp
magick compare -metric mae Outputs\a03s05t03.bmp Outputs_REFERENCE\donuts.txt_2048x2048x4_Stage5.exe.bmp  Outputs\stage5diff_03.bmp
magick compare -metric mae Outputs\a03s05t04.bmp Outputs_REFERENCE\donuts.txt_2048x2048x8_Stage5.exe.bmp  Outputs\stage5diff_04.bmp
magick compare -metric mae Outputs\a03s05t05.bmp Outputs_REFERENCE\donuts.txt_2048x2048x16_Stage5.exe.bmp Outputs\stage5diff_05.bmp
magick compare -metric mae Outputs\a03s05t06.bmp Outputs_REFERENCE\donuts.txt_2048x2048x32_Stage5.exe.bmp Outputs\stage5diff_06.bmp

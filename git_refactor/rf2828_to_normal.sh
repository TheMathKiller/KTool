#!/bin/bash

months=(
    Jan
    Feb
    Mar
    Apr
    May
    Jun
    Jul
    Aug
    Sep
    Oct
    Nov
    Dec
)

function rf2828_to_normal ()
{
   y=$(echo $rf2828_time | cut -f 5 -d " ")  
   m=$(echo $rf2828_time | cut -f 2 -d " ")
   d=$(echo $rf2828_time | cut -f 3 -d " ")
   h=$(echo $rf2828_time | cut -f 4 -d " " | cut -f 1 -d :)
   f=$(echo $rf2828_time | cut -f 4 -d " " | cut -f 2 -d :)
   s=$(echo $rf2828_time | cut -f 4 -d " " | cut -f 3 -d :)

   export result=
   export result=$y

   if [ $d = 1 ];then
      d=01
   fi
   if [ $d = 2 ];then
      d=02
   fi
   if [ $d = 3 ];then
      d=03
   fi
   if [ $d = 4 ];then
      d=04
   fi
   if [ $d = 5 ];then
      d=05
   fi
   if [ $d = 6 ];then
      d=06
   fi
   if [ $d = 7 ];then
      d=07
   fi
   if [ $d = 8 ];then
      d=08
   fi
   if [ $d = 9 ];then
      d=09
   fi

    if [ $m = Jan ];then
      export result=${result}01
    else
      if [ $m = Feb ];then
          export result=${result}02
      else
          if [ $m = Mar ];then
         export result=${result}03
          else
          if [ $m = Apr ];then
              export result=${result}04        
          fi          
          fi  
      fi   
    fi

    if [ $m = May ];then
      export result=${result}05
    else
      if [ $m = Jun ];then
          export result=${result}06
      else
          if [ $m = Jul ];then
         export result=${result}07
          else
          if [ $m = Aug ];then
              export result=${result}08        
          fi          
          fi  
      fi   
    fi

    if [ $m = Sep ];then
      export result=${result}09
    else
      if [ $m = Oct ];then
          export result=${result}10
      else
          if [ $m = Nov ];then
         export result=${result}11
          else
          if [ $m = Dec ];then
              export result=${result}12    
          fi       
          fi  
      fi   
    fi

    export result=${result}$d
    export result=${result}$h
    export result=${result}$f
    export result=${result}$s
}

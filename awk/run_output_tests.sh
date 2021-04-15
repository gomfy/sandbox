#!/usr/bin/env bash

message=($(awk '  
                    NR==FNR {  
                                out1[FNR]=$0
                                fnr1=FNR
                            } 
                    NR>FNR  {   
                                out2[FNR]=$0
                                fnr2=FNR
                            } 
                    END     {   
                                
                                if ( fnr1 != fnr2 ) {
                                        printf("ERROR number of records are not equal fnr1:%d != fnr2:%d\n", fnr1, fnr2)
                                        exit
                                }
                                    
                                for ( j in error ) {
                                    printf("%s\n", error[j])
                                }
                            }' "$tf1" "$tf2"))
                        
                # Process awk output            
                printf "%s\n" "${message[@]}"
                exit 0

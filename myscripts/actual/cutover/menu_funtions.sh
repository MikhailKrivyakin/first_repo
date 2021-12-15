function f_main_form  #main form
{
    clear
    PS3="What do you want to do? "
    select option in "Ping Stores from sites.list" "Check fjpkg at current tills from posclients.list" "Delete previos results" "Renew posclients.list" "quit" ;do
    case $option in
            "Ping Stores from sites.list")    
                    f_ping_result                
                    ;;
            "Check fjpkg at current tills from posclients.list")

                    echo 'Running fjpkg check'
                    ./fjpkg_check.sh
                    echo
                    ;;
            "Delete previos results")
                    ;;
            "Renew posclients.list")
                    ;;

            "quit")
                    exit
                    ;;
    esac
    done
}


function f_ping_result
{
    ./ping_sites.sh
    PS3="What do you want to do? "
    select option in "return to main" "quit";do
        case $option in
         "return to main")
                f_main_form
                ;;
          "quit")
                    exit
                    ;;
        esac
    done   

}


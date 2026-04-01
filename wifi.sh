#!/bin/bash

echo "iwd запущен!"
echo "a - показать сети, d - подключиться, q - выход"

while true; do
    read -n1 -s key  # читаем одну клавишу без Enter
    case "$key" in

        s)
            echo -e "\nСканирование..."
            sudo iwctl station wlan0 scan
            echo "a - показать сети, d - подключиться, q - выход"
            ;;

        a)
            sudo iwctl station wlan0 scan
            sudo iwctl station wlan0 get-networks
            echo "a - показать сети, d - подключиться, q - выход"
            ;;


        q)
            echo "Выход..."
            echo "a - показать сети,  d - подключиться, q - выход"
            break
            ;;

        d)
            echo "Cовет: выделите название сети курсором и нажмите колёсико мыши"
            read -p "Название сети: " ssid
            sudo iwctl station wlan0 connect "$ssid"
            
            if sudo iwctl station wlan0 connect "$ssid"; then
                sudo dhcpcd "wlan0"
                echo "Подключено к $ssid!"
                break
            else
                echo "Не удалось подключиться к $ssid."
                echo "a - показать сети, d - подключиться, q - выход"
            fi
            ;;
        *)
            echo "Неизвестная клавиша: $key"
            echo "a - показать сети, d - подключиться, q - выход"
            ;;
    esac
done
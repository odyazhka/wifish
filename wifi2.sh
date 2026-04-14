#!/bin/bash

# 1. Проверка прав доступа (необходим root)
if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: Скрипт должен быть запущен от имени root (sudo)."
  exit 1
fi

# 2. Проверка состояния сервиса wpa_supplicant
if ! sv status wpa_supplicant 2>/dev/null | grep -q "^run:"; then
  echo "Ошибка: Сервис wpa_supplicant не запущен или отсутствует!"
  echo "Убедитесь, что сервис привязан и запущен: sudo ln -s /etc/sv/wpa>
  exit 1
fi

# Основной бесконечный цикл
while true; do
  echo ""
  echo "=== Управление Wi-Fi (wpa_cli) ==="
  echo "a - Запуск сканирования сетей"
  echo "d - Подключение к сети"
  echo "q - Выход"
  read -n1 -s key
  case "$key" in
a)
      echo "[*] Запуск сканирования..."
      wpa_cli scan > /dev/null
      
      echo "[*] Ожидание 3 секунды..."
      sleep 3
      
      echo "[*] Доступные сети:"
      # Пропускаем 1-ю строку заголовка (tail -n +2)
      # Берем 5-е поле, разделенное табуляцией (cut -f5)
      # Убираем пустые имена от скрытых сетей (grep -v "^$")
      # Сортируем и убираем дубликаты (sort -u)
      wpa_cli scan_results | tail -n +2 | cut -f5 | grep -v "^$" | sort -u
      ;;
      
    d)
      echo "[*] Создание профиля новой сети..."
      net_id=$(wpa_cli add_network | tail -n 1)

      if ! [[ "$net_id" =~ ^[0-9]+$ ]]; then
        echo "[-] Ошибка: Не удалось создать новую сеть. Вывод: $net_id"
        continue
      fi
      echo "[+] Сеть создана. Внутренний ID: $net_id"

      read -p "Введите SSID (имя сети): " ssid
      wpa_cli set_network "$net_id" ssid "\"$ssid\"" > /dev/null

      read -s -p "Введите пароль: " psk
      echo ""
      wpa_cli set_network "$net_id" psk "\"$psk\"" > /dev/null

      echo "[*] Активация профиля сети..."
      wpa_cli enable_network "$net_id" > /dev/null

      echo "[*] Ожидание 5 секунд для проверки статуса подключения..."
      sleep 5

      if wpa_cli status | grep -q "wpa_state=COMPLETED"; then
        echo "[+] Подключение к сети '$ssid' успешно завершено!"
        
        echo "[*] Сохранение конфигурации..."
        wpa_cli save_config > /dev/null
        echo "[+] Конфигурация сохранена."
      else
        echo "[-] Ошибка: Подключение не удалось (возможно, неверный пароль или слабый сигнал)."
        echo "[*] Удаление созданного профиля сети ($net_id)..."
        wpa_cli remove_network "$net_id" > /dev/null
      fi
      ;;
      
    q)
      echo "Выход из скрипта..."
      exit 0
      ;;
      
    *)
      echo "[-] Неверный ввод. Пожалуйста, выберите 's', 'd' или 'q'."
      ;;
  esac
done

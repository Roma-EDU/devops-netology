# 7.5. Основы golang

С `golang` в рамках курса, мы будем работать не много, поэтому можно использовать любой IDE. 
Но рекомендуем ознакомиться с [GoLand](https://www.jetbrains.com/ru-ru/go/).  

## Задача 1. Установите golang.
1. Воспользуйтесь инструкций с официального сайта: [https://golang.org/](https://golang.org/).
   * Сам процесс установки подробно описан в разделе [Download and install](https://go.dev/doc/install), возможно некоторые шаги из-под `sudo`:
     * Скачиваем архив `wget https://go.dev/dl/go1.18.linux-amd64.tar.gz`
     * Удаляем при необходимости старую версию `rm -rf /usr/local/go`
     * Распаковываем архив в папку /usr/local `tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz`, должен появиться /usr/local/go
     * Дописываем при необходимости путь в переменную окружения `export PATH=$PATH:/usr/local/go/bin` (возможно понадобится перезагрузка)
     * Проверяем `go version`
3. Так же для тестирования кода можно использовать песочницу: [https://play.golang.org/](https://play.golang.org/).
   * Я пользовался песочницей

## Задача 2. Знакомство с gotour.
У Golang есть обучающая интерактивная консоль [https://tour.golang.org/](https://tour.golang.org/). 
Рекомендуется изучить максимальное количество примеров. В консоли уже написан необходимый код, 
осталось только с ним ознакомиться и поэкспериментировать как написано в инструкции в левой части экрана.  
* Более удобная ссылка https://go.dev/tour/list

## Задача 3. Написание кода. 
>Цель этого задания закрепить знания о базовом синтаксисе языка. Можно использовать редактор кода 
>на своем компьютере, либо использовать песочницу: [https://play.golang.org/](https://play.golang.org/).
>
>1. Напишите программу для перевода метров в футы (1 фут = 0.3048 метр). Можно запросить исходные данные 
>у пользователя, а можно статически задать в коде.
>    Для взаимодействия с пользователем можно использовать функцию `Scanf`:
>    ```
>    package main
>    
>    import "fmt"
>    
>    func main() {
>        fmt.Print("Enter a number: ")
>        var input float64
>        fmt.Scanf("%f", &input)
>    
>        output := input * 2
>    
>        fmt.Println(output)    
>    }
>    ```
> 
>1. Напишите программу, которая найдет наименьший элемент в любом заданном списке, например:
>    ```
>    x := []int{48,96,86,68,57,82,63,70,37,34,83,27,19,97,9,17,}
>    ```
>1. Напишите программу, которая выводит числа от 1 до 100, которые делятся на 3. То есть `(3, 6, 9, …)`.
>
>В виде решения ссылку на код или сам код. 

**Ответ**
```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	fmt.Println("1. Конвертация в футы")
	convertToFoot()

	fmt.Println("\n2. Минимальное число в массиве")
	x := []int{48, 96, 86, 68, 57, 82, 63, 70, 37, 34, 83, 27, 19, 97, 9, 17}
	fmt.Println(findMin(x))

	fmt.Println("\n3. Числа от 1 до 100, которые делятся на 3")
	modN(3, 100)
}

func convertToFoot() {
	fmt.Print("Enter a number: ")
	var input float64
	fmt.Scanf("%f", &input)

	output := input * 0.3048

	fmt.Println(output)
}

func findMin(array []int) int {
	result := array[0]
	for _, v := range array {
		if result > v {
			result = v
		}
	}
	return result
}

func modN(n int, maxValue int) {
	for i := n; i <= maxValue; i += n {
		fmt.Print(strconv.Itoa(i) + " ")
	}
}

```

## Задача 4. Протестировать код (не обязательно).

~~Создайте тесты для функций из предыдущего задания.~~

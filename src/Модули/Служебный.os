// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/nextcloud-lib/
// ----------------------------------------------------------

#Использовать logos
#Использовать 1connector

Перем Лог;    // логгер

#Область СлужебныйПрограммныйИнтерфейс

// Функция - получает значение элемента структуры данных по переданному пути
//
// Параметры:
//   Данные            - Структура           - данные, для которых получается значение элемента
//                       Массив
//   ПутьКЭлементу     - Массив из Строка    - массив - последовательность свойств/индексов
//                       Строка                или строка пути вида "tag1.tag2.[0].tag3"
//   Смещение          - Число               - отрицательное число - смещение от конца пути к элементу
//   ВыдаватьОшибку    - Число               - Истина - в случае невозможности получения элемента
//                                             будет выброшено исключение
//
// Возвращаемое значение:
//    Булево    - Истина - часть пути существует
//
Функция ЗначениеЭлементаСтруктуры(Знач Данные,
	                              Знач ПутьКЭлементу = "",
	                              Знач Смещение = 0,
	                              Знач ВыдаватьОшибку = Ложь) Экспорт

	ПутьКЭлементу = ПутьКЭлементуВМассив(ПутьКЭлементу);

	Результат = Данные;

	ТекущийПуть = "";

	// Обрабатываем элементов не больше чем "Количество элементов пути - Смещение"
	ГлубинаСвойств = Мин(ПутьКЭлементу.ВГраница(), ПутьКЭлементу.ВГраница() + Смещение);

	Для й = 0 По ГлубинаСвойств Цикл
		
		ЧастьПути = ПутьКЭлементу[й];
		Если ТипЗнч(ЧастьПути) = Тип("Число") Тогда
			ЧастьПути = СтрШаблон("[%1]", ЧастьПути);
		КонецЕсли;

		Если ЧастьПутиСуществует(Результат, ПутьКЭлементу[й]) Тогда
			Результат = Результат[ПутьКЭлементу[й]];
		ИначеЕсли ВыдаватьОшибку Тогда
			ВызватьИсключение СтрШаблон("Отсутствует свойство %1.(?)%2", ТекущийПуть, ЧастьПути);
		Иначе
			Лог.Предупреждение("Отсутствует свойство %1.(?)%2", ТекущийПуть, ЧастьПути);
			Возврат Неопределено;
		КонецЕсли;
		ТекущийПуть = ?(ТекущийПуть = "",
		                ЧастьПути,
		                СтрШаблон("%1.%2", ТекущийПуть, ЧастьПути));
	КонецЦикла;

	Возврат Результат;

КонецФункции // ЗначениеЭлементаСтруктуры()

// Функция - читает XML-строку и преобразует в структуру данных (Соответствие)
//
// Параметры:
//   ТекстXML    - Строка    - XML-строку для преобразования
//
// Возвращаемое значение:
//    Соответствие    - прочитанная структура данных
//
Функция ПрочитатьXMLВСтруктуру(ТекстXML) Экспорт

	Парсер = Новый ЧтениеXML;
	Парсер.УстановитьСтроку(ТекстXML);
 
	Результат = Новый Соответствие();

	ПутьКЭлементу = Новый Массив();
 
	Пока Парсер.Прочитать() Цикл

		ТекЭлемент = ЗначениеЭлементаСтруктуры(Результат, ПутьКЭлементу);

		Если Парсер.ТипУзла = ТипУзлаXML.НачалоЭлемента Тогда

			ДобавитьЭлементДанных(ТекЭлемент, ПутьКЭлементу, Парсер.Имя);

		ИначеЕсли Парсер.ТипУзла = ТипУзлаXML.Текст Тогда

			Если ТипЗнч(ТекЭлемент) = Тип("Массив") Тогда
				ТекЭлемент.Добавить(Парсер.Значение);
			Иначе
				Контейнер = ЗначениеЭлементаСтруктуры(Результат, ПутьКЭлементу, -1);
				Контейнер[ПутьКЭлементу[ПутьКЭлементу.ВГраница()]] = Парсер.Значение;
			КонецЕсли;

		ИначеЕсли Парсер.ТипУзла = ТипУзлаXML.КонецЭлемента Тогда

			Если ТипЗнч(ТекЭлемент) = Тип("Соответствие") И ТекЭлемент.Количество() = 0 Тогда
				Контейнер = ЗначениеЭлементаСтруктуры(Результат, ПутьКЭлементу, -1);
				Контейнер[ПутьКЭлементу[ПутьКЭлементу.ВГраница()]] = Неопределено;
			КонецЕсли;
			
			Если ТипЗнч(ПутьКЭлементу[ПутьКЭлементу.ВГраница()]) = Тип("Число") Тогда
				ПутьКЭлементу.Удалить(ПутьКЭлементу.ВГраница());
			КонецЕсли;
			ПутьКЭлементу.Удалить(ПутьКЭлементу.ВГраница());

		КонецЕсли;

	КонецЦикла;
 
    Парсер.Закрыть();

	Возврат Результат;

КонецФункции // ПрочитатьXMLВСтруктуру()

// Функция - проверяет наличие в соответствии элемента с указанным ключом (регистронезависимо)
//
// Параметры:
//   Соответствие    - Соответствие    - проверяемое соответствие
//   Ключ            - Строка          - проверяемый ключ
//
// Возвращаемое значение:
//    Булево    - Истина - элемент с указанным ключ присутствует в соответствии
//
Функция ЕстьЭлементСоответствия(Соответствие, Ключ = Неопределено) Экспорт

	Для Каждого ТекЭлемент Из Соответствие Цикл
		Если НРег(ТекЭлемент.Ключ) = НРег(Ключ) Тогда
			Возврат Истина;
		КонецЕсли;
	КонецЦикла;

	Возврат Ложь;

КонецФункции // ЕстьЭлементСоответствия()

// Функция возвращает лог библиотеки
//
// Возвращаемое значение:
//    Логгер - лог библиотеки
//
Функция Лог() Экспорт
	
	Если Лог = Неопределено Тогда
		Лог = Логирование.ПолучитьЛог(ИмяЛога());
	КонецЕсли;

	Возврат Лог;

КонецФункции // Лог()

// Функция возвращает имя лога библиотеки
//   
// Возвращаемое значение:
//    Строка - имя лога библиотеки
//
Функция ИмяЛога() Экспорт

	Возврат "oscript.lib.nextcloud";
	
КонецФункции // ИмяЛога()

#КонецОбласти // СлужебныйПрограммныйИнтерфейс

#Область СлужебныеПроцедурыИФункции

// Функция - преобразует путь вида "tag1.tag2.[0].tag3" в массив
//
// Параметры:
//   ПутьКЭлементу    - Строка,       - путь к элементу структуры данных вида "tag1.tag2.[0].tag3"
//                      Произвольный
//
// Возвращаемое значение:
//    Массив, Произвольный    - если передана строка, то массив частей пути,
//                              переданное значение в противном случае
//
Функция ПутьКЭлементуВМассив(Знач ПутьКЭлементу = "")

	Если НЕ ТипЗнч(ПутьКЭлементу) = Тип("Строка") Тогда
		Возврат ПутьКЭлементу;
	КонецЕсли;

	ПутьКЭлементу = СтрРазделить(ПутьКЭлементу, ".");
	РВ = Новый РегулярноеВыражение("\[\d+\]");
	Для й = 0 По ПутьКЭлементу.ВГраница() Цикл
		// Если часть пути соответствует шаблону "[Число]", то это индекс в массиве
		// сохраняем как "Число"
		Если РВ.Совпадает(ПутьКЭлементу[й]) Тогда
			ПутьКЭлементу[й] = Число(Сред(ПутьКЭлементу[й], 2, СтрДлина(ПутьКЭлементу[й]) - 2));
		Иначе
			ПутьКЭлементу[й] = СокрЛП(ПутьКЭлементу[й]);
		КонецЕсли;
	КонецЦикла;

	Возврат ПутьКЭлементу;

КонецФункции // ПутьКЭлементуВМассив()

// Функция - проверяет доступность существование элемента данных соответствия или массива
//
// Параметры:
//   Данные       - Структура    - данные, для которых проверяется наличие элемента
//                  Массив
//   ЧастьПути    - Строка       - проверяемое имя элемента или индекс массива
//                  Число
//
// Возвращаемое значение:
//    Булево    - Истина - часть пути существует
//
Функция ЧастьПутиСуществует(Данные, ЧастьПути)

	Возврат (ТипЗнч(Данные) = Тип("Соответствие") И ЕстьЭлементСоответствия(Данные, ЧастьПути))
	    ИЛИ (ТипЗнч(Данные) = Тип("Массив") И ТипЗнч(ЧастьПути) = Тип("Число") И Данные.ВГраница() >= ЧастьПути);

КонецФункции // ЧастьПутиСуществует()

// Процедура - добавляет элемент данных в структуру данных
//
// Параметры:
//   ЭлементРодитель    - Структура           - структура данных, куда будет добавлен элемент
//                        Массив
//   ПутьКЭлементу     - Массив из Строка    - (возвр.) массив - последовательность свойств/индексов
//   ИмяЭлемента       - Строка              - имя добавляемого элемента
//
Процедура ДобавитьЭлементДанных(ЭлементРодитель, ПутьКЭлементу, ИмяЭлемента)

	Если ТипЗнч(ЭлементРодитель) = Тип("Соответствие") Тогда
		Если ЕстьЭлементСоответствия(ЭлементРодитель, ИмяЭлемента) Тогда
			Если ТипЗнч(ЭлементРодитель[ИмяЭлемента]) = Тип("Строка")
			 ИЛИ ТипЗнч(ЭлементРодитель[ИмяЭлемента]) = Тип("Соответствие") Тогда
				Значение = ЭлементРодитель[ИмяЭлемента];
				ЭлементРодитель.Вставить(ИмяЭлемента, Новый Массив());
				ЭлементРодитель[ИмяЭлемента].Добавить(Значение);
			КонецЕсли;
			ЭлементРодитель[ИмяЭлемента].Добавить(Новый Соответствие());
			ПутьКЭлементу.Добавить(ИмяЭлемента);
			ПутьКЭлементу.Добавить(ЭлементРодитель[ИмяЭлемента].ВГраница());
		Иначе
			ЭлементРодитель.Вставить(ИмяЭлемента, Новый Соответствие());
			ПутьКЭлементу.Добавить(ИмяЭлемента);
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры // ДобавитьЭлементДанных()

#КонецОбласти // СлужебныеПроцедурыИФункции

// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/nextcloud-lib/
// ----------------------------------------------------------

Перем Подключение;    // - ПодключениеNextCloud    - подключение к сервису NextCloud

Перем Лог;            // логгер

#Область ПрограммныйИнтерфейс

// Возвращает адрес сервиса NextCloud
//
// Возвращаемое значение:
//   ПодключениеNextCloud    - подключение к сервису NextCloud
//
Функция Подключение() Экспорт

	Возврат Подключение;

КонецФункции // Подключение()

// Устанавливает новое подключение к сервису NextCloud
//
// Параметры:
//   НовоеПодключение    - ПодключениеNextCloud    - подключение к сервису NextCloud
//
Процедура УстановитьПодключение(НовоеПодключение) Экспорт

	Подключение = НовоеПодключение;

КонецПроцедуры // УстановитьПодключение()

// Функция - получает список файлов сервиса NextCloud в указанном каталоге
//
// Параметры:
//   Каталог    - Строка    - каталог для получения списка файлов
//
// Возвращаемое значение:
//   Массив из Структура    - список описаний файлов в каталоге
//
Функция Список(Знач Каталог = "") Экспорт

	СтрокаЗапроса = "/remote.php/dav/files";

	ТелоЗапроса = "<?xml version=""1.0"" encoding=""UTF-8""?>
	              |<d:propfind xmlns:d=""DAV:"">
	              |	<d:prop xmlns:oc=""http://owncloud.org/ns"">
	              |	<d:getlastmodified/>
	              |	<d:getcontentlength/>
	              |	<d:getcontenttype/>
	              |	<oc:permissions/>
	              |	<oc:size/>
	              |	<oc:id/>
	              |	<oc:fileid/>
	              |	<oc:owner-id/>
	              |	<oc:owner-display-name/>
	              |	<d:resourcetype/>
	              |	<d:getetag/>
	              | </d:prop>
	              |</d:propfind>";
	
	СтрокаЗапроса = СтрокаЗапроса + "/" + Подключение.ИмяПользователя() + "/" + Каталог;

	Заголовки = Новый Соответствие();
	Заголовки.Вставить("Content-Type", "text/xml");

	РезультатЗапроса = Подключение.ВыполнитьЗапрос("PROPFIND", СтрокаЗапроса, , Заголовки, ТелоЗапроса);

	РезультатЗапроса = Служебный.ПрочитатьXMLВСтруктуру(РезультатЗапроса.Текст());

	ОписанияФайлов = Служебный.ЗначениеЭлементаСтруктуры(РезультатЗапроса, "d:multistatus.d:response");

	Результат = Новый Соответствие();

	Для Каждого ТекОписание Из ОписанияФайлов Цикл

		ПутьКФайлу = Служебный.ЗначениеЭлементаСтруктуры(ТекОписание, "d:href");

		ЧастиПути = СтрРазделить(ПутьКФайлу, "/", Ложь);

		Свойства = Служебный.ЗначениеЭлементаСтруктуры(ТекОписание, "d:propstat");

		Если Свойства = Неопределено Тогда
			Продолжить;
		КонецЕсли;

		Если ТипЗнч(Свойства) = Тип("Массив") Тогда
			Префикс = "[0].d:prop";
		Иначе
			Префикс = "d:prop";
		КонецЕсли;

		СвойстваФайла = Служебный.ЗначениеЭлементаСтруктуры(Свойства, Префикс);

		Если Служебный.ЕстьЭлементСоответствия(СвойстваФайла, "d:resourcetype") Тогда
			ТипРесурса = Служебный.ЗначениеЭлементаСтруктуры(СвойстваФайла, "d:resourcetype");
			Если ТипРесурса = Неопределено Тогда
				ЭтоКаталог = Ложь;
			Иначе
				ЭтоКаталог = Служебный.ЕстьЭлементСоответствия(ТипРесурса, "d:collection");
			КонецЕсли;
			ЭтоФайл    = НЕ ЭтоКаталог;
		Иначе
			ЭтоФайл    = Ложь;
			ЭтоКаталог = Ложь;
		КонецЕсли;

		Если ЭтоФайл Тогда
			ТипФайла = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.d:getcontenttype", Префикс));
		КонецЕсли;

		ДатаИзменения = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.d:getlastmodified", Префикс));
		ПраваДоступа  = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.oc:permissions", Префикс));
		ГлобальныИд   = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.oc:id", Префикс));
		Ид            = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.oc:fileid", Префикс));
		ВладелецИд    = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.oc:owner-id", Префикс));
		ВладелецИмя   = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.oc:owner-display-name", Префикс));
		Размер        = Служебный.ЗначениеЭлементаСтруктуры(Свойства, СтрШаблон("%1.oc:size", Префикс));

		ОписаниеФайла = Новый Структура();

		ОписаниеФайла.Вставить("ПолныйПуть"   , ПутьКФайлу);
		ОписаниеФайла.Вставить("Имя"          , ЧастиПути[ЧастиПути.ВГраница()]);
		
		ЧастиПути.Удалить(ЧастиПути.ВГраница());
		ОписаниеФайла.Вставить("Путь"         , СтрСоединить(ЧастиПути, "/"));

		ОписаниеФайла.Вставить("ЭтоФайл"      , ЭтоФайл);
		ОписаниеФайла.Вставить("ЭтоКаталог"   , ЭтоКаталог);
		ОписаниеФайла.Вставить("ТипФайла"     , ТипФайла);
		ОписаниеФайла.Вставить("ДатаИзменения", ДатаИзменения);
		ОписаниеФайла.Вставить("ПраваДоступа" , ПраваДоступа);
		ОписаниеФайла.Вставить("ГлобальныИд"  , ГлобальныИд);
		ОписаниеФайла.Вставить("Ид"           , Ид);
		ОписаниеФайла.Вставить("ВладелецИд"   , ВладелецИд);
		ОписаниеФайла.Вставить("ВладелецИмя"  , ВладелецИмя);
		ОписаниеФайла.Вставить("Размер"       , Размер);

		Результат.Вставить(ОписаниеФайла.Имя, ОписаниеФайла);
		
	КонецЦикла;

	Возврат Результат;

КонецФункции // Список()

// Функция - проверяет существование файла/каталога на сервисе NextCloud
//
// Параметры:
//   ПутьКФайлу    - Строка    - путь к файлу/каталогу
//
// Возвращаемое значение:
//   Булево    - Истина - файл/каталог существует на сервисе NextCloud
//
Функция Существует(Знач ПутьКФайлу) Экспорт

	ЧастиПути = ЧастиПути(ПутьКФайлу);
	
	СписокФайлов = Список(ЧастиПути.Путь);

	Возврат НЕ (СписокФайлов.Получить(ЧастиПути.Имя) = Неопределено);

КонецФункции // Существует()

// Функция - проверяет что по указанному пути на сервисе NextCloud расположен файл
//
// Параметры:
//   ПутьКФайлу    - Строка    - путь к файлу/каталогу
//
// Возвращаемое значение:
//   Булево    - Истина - по указанному пути на сервисе NextCloud расположен файл
//
Функция ЭтоФайл(Знач ПутьКФайлу) Экспорт

	ЧастиПути = ЧастиПути(ПутьКФайлу);
	
	СписокФайлов = Список(ЧастиПути.Путь);

	ОписаниеФайла = СписокФайлов.Получить(ЧастиПути.Имя);

	Если ОписаниеФайла = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;

	Возврат ОписаниеФайла.ЭтоФайл;

КонецФункции // ЭтоФайл()

// Функция - проверяет что по указанному пути на сервисе NextCloud расположен каталог
//
// Параметры:
//   ПутьКФайлу    - Строка    - путь к файлу/каталогу
//
// Возвращаемое значение:
//   Булево    - Истина - по указанному пути на сервисе NextCloud расположен каталог
//
Функция ЭтоКаталог(Знач ПутьКФайлу) Экспорт

	ЧастиПути = ЧастиПути(ПутьКФайлу);
	
	СписокФайлов = Список(ЧастиПути.Путь);

	ОписаниеФайла = СписокФайлов.Получить(ЧастиПути.Имя);

	Если ОписаниеФайла = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;

	Возврат ОписаниеФайла.ЭтоКаталог;

КонецФункции // ЭтоКаталог()

// Процедура - отправляет указанный файл в сервис NextCloud
//
// Параметры:
//   ПутьКФайлу           - Строка    - путь к отправляемому файлу
//   ПутьДляСохранения    - Строка    - путь к каталогу для сохранения отправленного файла на сервисе NextCloud
//   ИмяДляСохранения     - Строка    - имя с которым будет сохранен файл, если не указано,
//                                      то будет использовано имя исходного файла
//   Перезаписывать       - Строка    - Истина - если файл существует, то он будет перезаписан;
//                                      Ложь - если файл существует, то будет выдано исключение
//
Процедура Отправить(Знач ПутьКФайлу,
	                Знач ПутьДляСохранения,
	                Знач ИмяДляСохранения = "",
	                Знач Перезаписывать = Ложь) Экспорт

	Файл = Новый Файл(ПутьКФайлу);

	Если НЕ Файл.Существует() И Файл.ЭтоФайл() Тогда
		ВызватьИсключение СтрШаблон("Не обнаружен файл ""%1"", для отправки", ПутьКФайлу);
	КонецЕсли;

	ПутьДляСохранения = СокрЛП(СтрЗаменить(ПутьДляСохранения, "\", "/"));
	ПутьДляСохранения = ?(Прав(ПутьДляСохранения, 1) = "/",
	                      Сред(ПутьДляСохранения, 1, СтрДлина(ПутьДляСохранения) - 1),
	                      ПутьДляСохранения);

	ИмяДляСохранения = ?(ЗначениеЗаполнено(ИмяДляСохранения), ИмяДляСохранения, Файл.Имя);

	ПутьДляСохранения = ПутьДляСохранения + ?(ЗначениеЗаполнено(ПутьДляСохранения), "/", "") + ИмяДляСохранения;

	Если НЕ Перезаписывать
	   И Существует(ПутьДляСохранения) Тогда
		ВызватьИсключение СтрШаблон("Файл ""%1"" уже существует на сервере ""%2"" в каталоге пользователя ""%3""!",
		                            ПутьДляСохранения,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя());
	КонецЕсли;

	СтрокаЗапроса = СтрШаблон("/remote.php/dav/files/%1/%2",
	                          Подключение.ИмяПользователя(),
	                          ПутьДляСохранения);

	ДанныеФайла = Новый ДвоичныеДанные(ПутьКФайлу);

	Заголовки = Новый Соответствие();
	Заголовки.Вставить("Content-Type", "multipart/form-data");

	РезультатЗапроса = Подключение.ВыполнитьЗапрос("PUT", СтрокаЗапроса, , Заголовки, ДанныеФайла);

	Если НЕ (РезультатЗапроса.КодСостояния = 201 ИЛИ РезультатЗапроса.КодСостояния = 204) Тогда
		ВызватьИсключение СтрШаблон("Ошибка отправки файла ""%1"" на сервер ""%2""
		                            | в каталог пользователя ""%3"", код состояния %4:%5%6",
		                            ПутьДляСохранения,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя(),
		                            РезультатЗапроса.КодСостояния,
		                            Символы.ПС,
		                            РезультатЗапроса.Текст());
	КонецЕсли;

КонецПроцедуры // Отправить()

// Процедура - получает указанный файл из сервиса NextCloud
//
// Параметры:
//   ПутьКФайлу           - Строка    - путь к получаемому файлу на сервисе NextCloud
//   ПутьДляСохранения    - Строка    - путь для сохранения полученного файла
//   Перезаписывать       - Строка    - Истина - если файл существует, то он будет перезаписан;
//                                      Ложь - если файл существует, то будет выдано исключение
//
Процедура Получить(Знач ПутьКФайлу, Знач ПутьДляСохранения, Знач Перезаписывать = Ложь) Экспорт

	Если НЕ Существует(ПутьКФайлу) Тогда
		ВызватьИсключение СтрШаблон("Не найден файл ""%1"" на сервере ""%2"" в каталоге пользователя ""%3""!",
		                            ПутьКФайлу,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя());
	КонецЕсли;

	Файл = Новый Файл(ПутьДляСохранения);

	Если Файл.Существует() И НЕ Перезаписывать Тогда
		ВызватьИсключение СтрШаблон("Файл ""%1"" уже существует!",
		                            ПутьДляСохранения);
	КонецЕсли;

	СтрокаЗапроса = СтрШаблон("/remote.php/dav/files/%1/%2",
	                          Подключение.ИмяПользователя(),
	                          ПутьКФайлу);

	РезультатЗапроса = Подключение.ВыполнитьЗапрос("GET", СтрокаЗапроса);

	Если НЕ РезультатЗапроса.КодСостояния = 200 Тогда
		ВызватьИсключение СтрШаблон("Ошибка получения файла ""%1"" с сервера ""%2""
		                            | из каталога пользователя ""%3"", код состояния %4:%5%6",
		                            ПутьКФайлу,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя(),
		                            РезультатЗапроса.КодСостояния,
		                            Символы.ПС,
		                            РезультатЗапроса.Текст());
	КонецЕсли;

	ДанныеФайла = РезультатЗапроса.ДвоичныеДанные();

	Попытка
		ДанныеФайла.Записать(ПутьДляСохранения);
	Исключение
		ВызватьИсключение СтрШаблон("Ошибка записи файла ""%1"":%2%3",
		                            ПутьДляСохранения,
		                            Символы.ПС,
		                            ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
	КонецПопытки;

КонецПроцедуры // Получить()

// Процедура - удаляет указанный файл/каталог на сервисе NextCloud
//
// Параметры:
//   ПутьКФайлу                - Строка    - путь к удаляемому файлу/каталогу
//   ОшибкаЕслиНеСуществует    - Булево    - Истина - если файл/каталог не существует на сервере выдавать ошибку
//
Процедура Удалить(Знач ПутьКФайлу, Знач ОшибкаЕслиНеСуществует = Ложь) Экспорт

	Если ОшибкаЕслиНеСуществует
	   И НЕ Существует(ПутьКФайлу) Тогда
		ВызватьИсключение СтрШаблон("Файл ""%1"" не существует на сервере ""%2"" в каталоге пользователя ""%3""!",
		                            ПутьКФайлу,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя());
	 КонецЕсли;
 
	СтрокаЗапроса = СтрШаблон("/remote.php/dav/files/%1/%2",
	                          Подключение.ИмяПользователя(),
	                          ПутьКФайлу);

	РезультатЗапроса = Подключение.ВыполнитьЗапрос("DELETE", СтрокаЗапроса);

	Если РезультатЗапроса.КодСостояния = 404 Тогда
		ТекстОшибки = СтрШаблон("Удаляемый файл/каталог ""%1"" не существует на сервере ""%2""
			                    | в каталоге пользователя ""%3""!",
			                    ПутьКФайлу,
			                    Подключение.Адрес(),
			                    Подключение.ИмяПользователя());
		Если ОшибкаЕслиНеСуществует Тогда
			ВызватьИсключение ТекстОшибки;
		Иначе
			Лог.Предупреждение(ТекстОшибки);
		КонецЕсли;
	ИначеЕсли НЕ РезультатЗапроса.КодСостояния = 204 Тогда
		ВызватьИсключение СтрШаблон("Ошибка удаления файла ""%1"" с сервера ""%2""
		                            | в каталоге пользователя ""%3"", код состояния %4:%5%6",
		                            ПутьКФайлу,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя(),
		                            РезультатЗапроса.КодСостояния,
		                            Символы.ПС,
		                            РезультатЗапроса.Текст());
	КонецЕсли;

КонецПроцедуры // Удалить()

// Процедура - создает каталог на сервисе NextCloud
//
// Параметры:
//   ПутьККаталогу           - Строка    - путь к создаваемому каталогу
//   ОшибкаЕслиСуществует    - Булево    - Истина - если каталог уже существует на сервере выдавать ошибку
//
Процедура СоздатьКаталог(Знач ПутьККаталогу, Знач ОшибкаЕслиСуществует = Ложь) Экспорт

	СтрокаЗапроса = СтрШаблон("/remote.php/dav/files/%1/%2",
	                          Подключение.ИмяПользователя(),
	                          ПутьККаталогу);

	РезультатЗапроса = Подключение.ВыполнитьЗапрос("MKCOL", СтрокаЗапроса);

	Если РезультатЗапроса.КодСостояния = 405 Тогда
		ТекстОшибки = СтрШаблон("Каталог ""%1"" уже существует на сервере ""%2"" в каталоге пользователя ""%3""!",
		                        ПутьККаталогу,
		                        Подключение.Адрес(),
		                        Подключение.ИмяПользователя());
		Если ОшибкаЕслиСуществует Тогда
			ВызватьИсключение ТекстОшибки;
		Иначе
			Лог.Предупреждение(ТекстОшибки);
		КонецЕсли;
	ИначеЕсли НЕ РезультатЗапроса.КодСостояния = 201 Тогда
		ВызватьИсключение СтрШаблон("Ошибка создания каталога ""%1"" на сервера ""%2""
		                            | в каталоге пользователя ""%3"", код состояния %4:%5%6",
		                            ПутьККаталогу,
		                            Подключение.Адрес(),
		                            Подключение.ИмяПользователя(),
		                            РезультатЗапроса.КодСостояния,
		                            Символы.ПС,
		                            РезультатЗапроса.Текст());
	КонецЕсли;

КонецПроцедуры // СоздатьКаталог()

#КонецОбласти // ПрограммныйИнтерфейс

#Область СлужебныеПроцедурыИФункции

// Функция - разбивает переданный путь к файлу на части
//
// Параметры:
//   ПутьКФайлу    - Строка    - путь к файлу/каталогу
//
// Возвращаемое значение:
//   Структура    - части пути к файлу
//     *Имя           - Строка    - имя файла/каталога
//     *Путь          - Строка    - путь к каталогу в котором расположен файл/каталог
//     *ПолныйПуть    - Строка    - полный путь к файлу/каталогу
//
Функция ЧастиПути(Знач ПутьКФайлу)

	Результат = Новый Структура();
	
	ПутьКФайлу = СтрЗаменить(ПутьКФайлу, "\", "/");

	Результат.Вставить("ПолныйПуть", ПутьКФайлу);

	ЧастиПути = СтрРазделить(ПутьКФайлу, "/", Ложь);
	
	Результат.Вставить("Имя", ЧастиПути[ЧастиПути.ВГраница()]);

	ЧастиПути.Удалить(ЧастиПути.ВГраница());

	Результат.Вставить("Путь", СтрСоединить(ЧастиПути, "/"));

	Возврат Результат;

КонецФункции // ЧастиПути()

#КонецОбласти // СлужебныеПроцедурыИФункции

#Область Инициализация

// Конструктор
//
// Параметры:
//   ПодключениеКСервису    - ПодключениеNextCloud    - подключение к сервису NextCloud
//
Процедура ПриСозданииОбъекта(Знач ПодключениеКСервису = Неопределено)

	Лог = Служебный.Лог();

	Если НЕ ЗначениеЗаполнено(ПодключениеКСервису) Тогда
		ПодключениеКСервису = Новый ПодключениеNextCloud();
	КонецЕсли;

	УстановитьПодключение(ПодключениеКСервису);

КонецПроцедуры // ПриСозданииОбъекта()

#КонецОбласти // Инициализация

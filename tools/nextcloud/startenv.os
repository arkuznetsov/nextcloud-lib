#Использовать 1commands
#Использовать "../../src"

Перем Лог; // логгер

Процедура ПодготовитьОкружение()

	СистемнаяИнформация = Новый СистемнаяИнформация;
	ЭтоWindows = Найти(НРег(СистемнаяИнформация.ВерсияОС), "windows") > 0;

	КодировкаВывода = КодировкаТекста.UTF8;
	Если ЭтоWindows Тогда
		КодировкаВывода = КодировкаТекста.OEM;
	КонецЕсли;

	Команда = Новый Команда();
	Команда.УстановитьКоманду("docker");
	Команда.УстановитьКодировкуВывода(КодировкаВывода);
	Команда.ДобавитьПараметр("run");
	Команда.ДобавитьПараметр("--name nextcloud");
	Команда.ДобавитьПараметр("-d");
	Команда.ДобавитьПараметр("-p 8080:80");
	Команда.ДобавитьПараметр("nextcloud");

	Команда.УстановитьИсполнениеЧерезКомандыСистемы(Ложь);
	Команда.ПоказыватьВыводНемедленно(Ложь);

	Лог.Информация("Запуск контейнера NextCloud");

	КодВозврата = Команда.Исполнить();

	ВыводКоманды = Команда.ПолучитьВывод();

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка запуска контейнера, код возврата %1:%2%3",
		                            КодВозврата,
		                            Символы.ПС,
		                            Команда.ПолучитьВывод());
	КонецЕсли;

	Счетчик = 0;
	Пока НЕ СервисГотов() И Счетчик < 20 Цикл
		Приостановить(10000);
		Счетчик = 0;
	КонецЦикла;

	Если НЕ СервисГотов() Тогда
		ВызватьИсключение "Истекло время ожидания запуска сервиса NextCloud";
	КонецЕсли;

	Лог.Информация("Контейнер NextCloud запущен:%1%2", Символы.ПС, ВыводКоманды);

	АдминИмя    = ПолучитьПеременнуюСреды("NC_ADMIN_NAME");
	АдминПароль = ПолучитьПеременнуюСреды("NC_ADMIN_PWD");

	Команда = Новый Команда();
	Команда.УстановитьКоманду("docker");
	Команда.УстановитьКодировкуВывода(КодировкаВывода);
	Команда.ДобавитьПараметр("exec");
	Команда.ДобавитьПараметр("--user www-data");
	Команда.ДобавитьПараметр("nextcloud");
	Команда.ДобавитьПараметр("php occ maintenance:install");
	Команда.ДобавитьПараметр(СтрШаблон("--admin-user %1", АдминИмя));
	Команда.ДобавитьПараметр(СтрШаблон("--admin-pass %1", АдминПароль));

	Команда.УстановитьИсполнениеЧерезКомандыСистемы(Ложь);
	Команда.ПоказыватьВыводНемедленно(Ложь);

	Лог.Информация("Инициализация сервиса NextCloud");

	КодВозврата = Команда.Исполнить();
	
	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка инициализации сервиса NextCloud, код возврата %1:%2%3",
		                            КодВозврата,
		                            Символы.ПС,
		                            Команда.ПолучитьВывод());
	КонецЕсли;

	Лог.Информация("Сервис NextCloud инициализирован:%1%2", Символы.ПС, ВыводКоманды);

КонецПроцедуры // ПодготовитьОкружение()

Функция СервисГотов()

	СистемнаяИнформация = Новый СистемнаяИнформация;
	ЭтоWindows = Найти(НРег(СистемнаяИнформация.ВерсияОС), "windows") > 0;

	КодировкаВывода = КодировкаТекста.UTF8;
	Если ЭтоWindows Тогда
		КодировкаВывода = КодировкаТекста.OEM;
	КонецЕсли;

	Команда = Новый Команда();
	Команда.УстановитьКоманду("curl");
	Команда.УстановитьКодировкуВывода(КодировкаВывода);
	Команда.ДобавитьПараметр("-I");
	Команда.ДобавитьПараметр("-L");
	Команда.ДобавитьПараметр("-s");
	Команда.ДобавитьПараметр("http://localhost:8080");

	Команда.УстановитьИсполнениеЧерезКомандыСистемы(Ложь);
	Команда.ПоказыватьВыводНемедленно(Ложь);

	Лог.Информация("Проверка готовности сервиса NextCloud");

	КодВозврата = Команда.Исполнить();
	
	ВыводКоманды = Команда.ПолучитьВывод();

	Если НЕ КодВозврата = 0 Тогда
		Возврат Ложь;
	КонецЕсли;

	РВ = Новый РегулярноеВыражение("HTTP\/1.1\s*(\d{3})");
	Совпадения = РВ.НайтиСовпадения(ВыводКоманды);

	Если Совпадения.Количество() = 0 Тогда
		Возврат Ложь;
	КонецЕсли;

	Для Каждого ТекСовпадение Из Совпадения Цикл
		Если СокрЛП(ТекСовпадение.Группы[1].Значение) = "200" Тогда
			Возврат Истина;
		КонецЕсли;
	КонецЦикла;

	Возврат Ложь;

КонецФункции // СервисГотов()

Процедура Инициализация() Экспорт
	
	Лог = Служебный.Лог();

КонецПроцедуры

Инициализация();
ПодготовитьОкружение();
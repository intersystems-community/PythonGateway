Python Gateway в InterSystems IRIS

Эта серия статей будет посвящена Python Gateway - комьюнити проекту с открытым исходных кодом для платформы данных InterSystems IRIS. Этот проект 
добавит все возможности Python прямо в вашу среду InterSystems IRIS, позволяя:

- Выполнять произвольный код на Python
- Передавать данные из InterSystems IRIS в Python и обратно
- Добавлять Python код в ваши интеллектуальные бизнес-процессы с помощью Python адаптера
- Сохранять, исследовать, изменять и восстановливать контекст Python из InterSystems IRIS
- И многое другое...

# План

# Введение

Машинное обучение (ML) - класс методов искусственного интеллекта, характерной чертой которых является не прямое решение задачи, а обучение в процессе применения решений множества сходных задач. 

Алгоритмы и модели машинного обучения становятся все более распространенными. Причин тому множество, но все сводится к доступности, 
простоте и достижению практических результатов. Является ли кластеризация или даже нейросетевое моделирование новой технологией? 
Конечно нет, но в настоящее время нет необходимости писать сотни тысяч строк кода, чтобы запустить одну, а затраты на создание и применение моделей становятся всё меньше и меньше.

Инструменты развиваются - в то время как в настоящее время у нас нет полностью GUI-ориентированных AI/ML инструментов, но тот же прогресс, который мы наблюдали со многими другими классами информаионных систем, например BI (от написания кода до 
использования фреймворков и GUI-ориентированных конфигурируемых решений), наблюдается и в инструментах для создания AI/ML. Мы уже прошли этап написания кода и в настоящее время используем фреймворки для построени и обучения моделей.

Другие улучшения, например предоставление предобученной модели, когда конечный пользователь должен просто закончить обучение модели на его специфических данных также упрощает процесс настройки. Эти достижения значительно облегчают изучение машинного обучения как непосредственно для специалистов, так и для компаний в целом.

С другой стороны, в настоящее время мы собираем всё больше данных о каждой транзакции. Благодаря унифицированной платформе данных, такой как InterSystems IRIS, вся эта информация может быть немедленно получена и использована в качестве исходных данных для прогнозных моделей.

С облаком, запуск AI/ML проектов становится легче, чем когда-либо. Мы можем потреблять только те ресурсы, которые нам необходимы. Более того, благодаря параллелизации, предлагаемому облачными платформами, мы можем сэкономить затрачиваемое время.

Но как насчет результатов? Здесь все становится немного сложнее. 
Существует множество инструментов для построения модели, о которых я расскажу далее, и построить хорошую модель не просто, но что 
дальше? Получение прибыли от использования модели бизнесом также является нетривиальной задачей. 
Корень проблемы - разделение аналитических и транзакционных потоков и моделей данных. Когда мы обучаем модель, мы обычно делаем это на исторических данных. Но место для построенной модели - в транзакционной обработке данных. Что хорошего в лучшей модели обнаружения мошеннических транзакций, если мы запускаем ее раз в день? Преступники уже давно ушли с деньгами. Нам нужно тренировать модель на исторических данных, но мы также должны применять модель в реальном времени на новых поступающих данных, чтобы 
наши бизнес-процессы могли действовать в соответствии с прогнозами, сделанными моделью.

# MLToolkit

MLToolkit - набор инструментов, целью которого является именно это - объединение моделей и транзакционной среды, чтобы построенные вами модели можно было легко использовать прямо в ваших бизнес-процессах. Python Gateway является частью MLToolkit и обеспечивает интеграцию с языком Python (аналогично как R Gateway обеспечивает интеграцию с языком R).

# Ландшафт

Прежде чем мы продолжим, я хотел бы описать несколько инструментов и библиотек для Python, которые мы будем использовать позже.

## Инструменты

- Python - интерпретируемый, высокоуровневый язык программирования общего назначения. Основным преимуществом языка является большая библиотека математических, ML и AI библиотек. Как и ObjectScript, это объектно-ориентированный язык, но всё динамически, а не статично. Также все является объектом. Более поздние статьи предполагают мимолетное знакомство с языком. Если вы хотите начать обучение, я рекомендую начать с [документации](https://docs.python.org/3.6/tutorial/index.html).
- Для наших последующих упражнений установите [Python 3.6.7 64 bit](https://www.python.org/downloads/release/python-367/).
- IDE: Я использую [PyCharm](https://www.jetbrains.com/pycharm/), но вообще их [много](https://realpython.com/python-ides-code-editors-guide/). Если вы используете Atelier, то существует Eclipse для разработчиков Python. Если вы используете VS Code, то существует расширение для Python. 
- Notebook: вместо IDE вы можете писать и делиться своими скриптами в онлайн ноутбуках. Самый популярный из них - [Jupyter](https://jupyter.org/).

## Библиотеки

Вот (неполный) список библиотек для машинного обучения:

- [Numpy](http://www.numpy.org/) - фундаментальный пакет для точных вычислений.
- [Pandas](http://pandas.pydata.org/) - высокопроизводительные структуры данных и инструменты анализа данных.
- [Matplotlib](https://matplotlib.org/) - создание графиков.
- [Seaborn](https://seaborn.pydata.org/) - визуализация данных, основанная на matplotlib.
- [Sklearn](https://scikit-learn.org/stable/) - методы машинного обучения.
- [XGBoost](https://xgboost.readthedocs.io/en/latest/index.html) - алгоритмы машинного обучения в рамках методологии градиентного бустинга (Gradient Boosting).
- [Gensim](https://radimrehurek.com/gensim/) - NLP.
- [Keras](https://keras.io/) - нейронные сети.
- [Tensorflow](https://www.tensorflow.org/) - платформа для создания моделей машинного обучения.
- [PyTorch](https://pytorch.org/) - платформа для создания моделей машинного обученияб ориентированная на Python.
- [Nyoka](https://github.com/nyoka-pmml/nyoka) - PMML из различных моделей.

Технологии AI/ML позволяют сделать бизнес более эффективным и адаптируемым.  Более того, сегодня эти технологии становятся проще в разработке и внедрении. Начните изучать AI/ML технологии и то, как они могут помочь вашей организации расти.


# Установка

Существует несколько способов установки и использования Python Gateway:

- ОС
  - Windows
  - Linux
  - Mac
- Docker
  - Используйте образ из DockerGub
  - Создайте свой собственный образ
  
Независимо от способа установки, вам понадобится исходный код. Единственное место для скачивания кода - [страница релизов](https://github.com/intersystems-community/PythonGateway/releases). Она содержит протестированные стабильные релизы, просто берите последний. На данный момент это 0.8, но со временем будут и новые. Не клонируйте/загружайте репозиторий, скачайте последний релиз.

# ОС
  
Если вы устанавливаете Python Gateway в операционную систему, то сначала (вне зависимости от операционной системы) вам необходимо установить Python. Для этого:
  
1. [Установить Python 3.6.7 64 bit](https://www.python.org/downloads/release/python-367/). Рекомендуется установить Python в директорию по-умолчанию.
2. Установите модуль `dill`: `pip install dill`.
3. Загрузите код ObjectScript (т.е. `do $system.OBJ.ImportDir("C:\InterSystems\Repos\Python\isc\py\", "*.cls", "c",,1)`) в любую область с продукциями. В случае, если вы хотите, чтобы существующая область поддерживала продукции, выполните: `write ##class(%EnsembleMgr).EnableNamespace($Namespace, 1)`.
4. Поместите [callout DLL/SO/DYLIB](https://github.com/intersystems-community/PythonGateway/releases) в папку `bin` вашего инстанса InterSystems IRIS. Файл библиотеки должен быть доступен по пути, возвращаемом `write ##class(isc.py.Callout).GetLib()`. 

## Windows 

5. Убедитесь, что переменная окружения `PYTHONHOME` указывает на Python 3.6.7.
6. Убедитесь, что системная переменная окружения `PATH` содержит переменную `PYTHONHOME` (или директорию, на которую она указывает).

## Linux (Debian/Ubuntu)

5. Проверьте, что переменная окружения `PATH` содержит `/usr/lib` и `/usr/lib/x86_64-linux-gnu`. Используйте файл `/etc/environment` для установки переменных окружения.
6. В случае ошибок `undefined symbol: _Py_TrueStruct` установите настройку `PythonLib`. Также в [Readme](https://github.com/intersystems-community/PythonGateway) есть раздел Troubleshooting.

## Mac

5. В настоящее время поддерживается только питон 3.6.7 из [Python.org](https://www.python.org/downloads/release/python-367/). Проверьте переменную `PATH`.

Если вы изменяли переменные окружения, перезапустите ваш продукт InterSystems.

# Docker

Использование контейнеров имеет ряд преимуществ: 
- Портативность
- Эффективность
- Изоляция
- Легковесность
- Иммутабельность

Ознакомьтесь с этой [серией статей](https://community.intersystems.com/post/continuous-delivery-your-intersystems-solution-using-gitlab-part-v-why-containers) для получения более подробной информации об использовании Docker с продуктами InterSystems. 

Все сборки Python Gateway на данный момент основаны на контейнерах `2019.4`.

## Готовый образ

Выполните: `docker run -d -p 52773:52773 --name irispy intersystemscommunity/irispy-community:latest`, чтобы загрузить и запустить Python Gateway с InterSystems IRIS Community Edition. Вот и все.

## Создайте свой собственный образ

Для сборки докер образа выполните в корне репозитория: `docker build --force-rm --tag intersystemscommunity/irispy:latest .`. 
По умолчанию образ собирается на основе образа `store/intersystems/iris-community:2019.4.0.383.0`, однако вы можете изменить это, установив переменную `IMAGE`.
Для сборки из InterSystems IRIS выполните: `docker build --build-arg IMAGE=store/intersystems/iris:2019.4.0.383.0 --force-rm --tag intersystemscommunity/irispy:latest ``.

После этого вы можете запустить докер образ:

```
docker run -d \
  -p 52773:52773 \
  -v /<HOST-DIR-WITH-iris.key>/:/mount \
  --name irispy \
  intersystemscommunity/irispy:latest \
  --key /mount/iris.key
```

Если вы используете образ, основанный на InterSystems IRIS Community Edition, вы можете не указывать ключ.

## Docker - комментарии

- Тетсовый процесс `isc.py.test.Process` сохраняет ряд изображений во временный каталог. Возможно, вы захотите изменить этот путь на смонтированный каталог. Для этого отредактируйте настройку `WorkingDir` указав смонтированную директорию.
- Для доступа к терминалу выполните: `docker exec -it irispy sh`.
- Доступ к Порталу Управления Системой по логину `SuperUser`/`SYS`.
- Чтобы остановить контейнер, выполните: `docker stop irispy && docker rm --force irispy`.

# Проверка установки

После того, как вы установили Python Gateway стоит проверить, что он работает. Выполните этот код в терминале InterSystems IRIS:
```
set sc = ##class(isc.py.Callout).Setup() 
set sc = ##class(isc.py.Main).SimpleString("x='HELLO'", "x", , .var).
write var
```

В результате должно быть выведено `HELLO` - значение Python-переменной `x`. Если возвращаемый статус `sc` является ошибкой или `var` пусто, проверьте [Readme - Troubleshooting section](https://github.com/intersystems-community/PythonGateway).


Python Gateway установлен, и вы убедились, что он работает, пора начинать его использовать! 
Главный интерфейс к Python это `isc.py.Main`. Он предлагает следующие группы методов (все возвращают `%Status`):
- Исполнение кода
- Передача данных
- Вспомогательные

## Исполнение кода

Эти методы позволяют исполнять произвольный Python-код.

### SimpleString

`SimpleString` - это основной метод. Он принимает 4 опциональных аргумента:
- `code` - строка кода для выполнения. Символ перевода строки: `$c(10)`.
- `returnVariable` - имя переменной для возврата.
- `serialization` - как сериализовать `returnVariable`. 0 - string (по умолчанию), 1 - repr.
- `result` - ByRef ссылка на переменную, в которую записывается значение `returnVariable`.

Выше мы выполнили:
```
set sc = ##class(isc.py.Main).SimpleString("x='HELLO'", "x", , .var).
```

В данном примере мы присваиваем переменной Python `x` значение `Hello` и хотим вернуть значение Python переменной `x` в ObjectScript переменную `var`.

### ExecuteCode

ExecuteCode является более безопасной и менее ограниченной альтернативой `SimpleString`.
Строки в платформе InterSystems IRIS ограничены 3 641 144 символами, и если вы хотите выполнить более длинный кусок кода, вам необходимо использовать потоки. 
Принимаются два аргумента:
- `code` - строка или поток Python кода для исполнения.
- `variable` - (опционально) присваивает результат выполнения `code` этой Python переменной.

Приме использовать:
```
set sc = ##class(isc.py.Main).ExecuteCode("2*3", "y").
```

В этом примере мы умножаем 2 на 3 и записываем результат в Python переменную `y`.

## Передача данных

Передавайте данные в Python и обратно.

### Python -> InterSystems IRIS

Есть 4 способа получить значение Python переменной в InterSystems IRIS, в зависимости от сериализации, которая вам нужна:
- `String` для простых типов данных и отладки.
- `Repr` для хранения простых объектов и отладки.
- `JSON` для легкого манипоулирования данными на стороне InterSystems IRIS.
- `Pickle` для сохранения объектов.

Эти методы позволяют получать переменные с Python в виде строки или потоков.

- `GetVariable(variable, serialization, .stream, useString)` - получить `serialization` переменной `variable` в `stream`. Если `useString` равно 1 и сериализация помещается в строку, то возвращается строка а не поток.
- `GetVariableJson(variable, .stream, useString)` - получить JSON сериализацию переменной.
- `GetVariablePickle(variable, .stream, useString, useDill)` -получить Pickle (или Dill) сериализацию переменной.

Попробуем получить нашу переменную `y`.

```
set sc = ##class(isc.py.Main).GetVariable("y", , .val, 1)
write val
>6
```

### InterSystems IRIS -> Python

Загрузим некоторые данные из InterSystems IRIS в Python.

- `ExecuteQuery(query, variable, type, namespace)` - создает набор данных (pandas `dataframe` или `list`) из sql запроса и устанавливает его в Python переменную `variable`. Пакет `isc.py` должен быть доступен в области `namespace` - там будет исполняться запрос.
- `ExecuteGlobal(global, variable, type, start, end, mask, labels, namespace)` - загружает данные глобала `global` от сабскрипта `start` до `end` в Python как переменную типа `type`: `list`, либо pandas `dataframe`. Описание опциональных аргументов `mask` and `labels` доступно в документации класса и репозитории [Data Transfer docs](https://github.com/intersystems-community/PythonGateway/blob/master/DataTransfer.md).
- `ExecuteClass(class, variable, type, start, end, properties, namespace)` - загружает данные класса `class` от id `start` до `end` в Python как переменную типа `type`: `list`, либо pandas `dataframe`. `properties` - список (разделитель - запятая) свойств класса, которые нужно загрузить в набор данных. Поддерживаются маски `*` и `?`. По умолчанию - `*` (все свойства). Свойство `%%CLASSNAME` игнорируется.
- `ExecuteTable(table, variable, type, start, end, properties, namespace)` - загружает данные таблицы `table` от id `start` до `end` в Python.


`ExecuteQuery` - универсален (любой корректный SQL-запрос будет передан в Python). Однако, `ExecuteGlobal` и его обёртки `ExecuteClass` и `ExecuteTable` работают с рядом ограничений. Они намного быстрее (в 3-5 раз быстрее ODBC-драйвера и в 20 раз быстрее `ExecuteQuery`). Дополнительная информация в [Data Transfer docs](https://github.com/intersystems-community/PythonGateway/blob/master/DataTransfer.md).
Все эти методы поддерживают передачу данных из любой области. Пакет `iris.py` должен быть доступен в целевой области.

## ExecuteQuery

`ExecuteQuery(request, variable, type, namespace)` - передача результатов любого корректного SQL-запроса на Python. Это самый медленный метод передачи данных. Используйте его, если `ExecuteGlobal` и его обёртки недоступны.

Аргументы:
- `query` - sql запрос.
- `variable` - название Python переменной в которую записываются данные.
- `type` - `list` или Pandas `dataframe`.
- `namespace` - область в которой будет исполняться запрос.

## ExecuteGlobal

`ExecuteGlobal(global, variable, type, start, end, mask, labelels, namespace)` - передача глобала в Python.

Аргументы:
- `global` - имя глобала без `^`
- `variable` - название Python переменной в которую записываются данные.
- `type` - `list` или Pandas `dataframe`.
- `start` - первый сабскрипт глобала. Обязательно `%Integer`.
- `end` - последний сабскрипт глобала. Обязательно `%Integer`.
- `mask` - маска значений глобала. Маска может быть короче, чем количество полей в глобале (в этом случае поля в конце будут пропущены). Как форматировать маску:
  -   `+` передать значение как есть.
  -   `-` пропустить значение.
  -   `b` - Логический тип (`0` - `False`, всё остальное - `True`).
  -   `d` - Дата (из $horolog, на Windows от 1970, на Linux от 1900).
  -   `t` - Время ($horolog, сеукунды после полуночи).
  -   `m` - Метка времени (строка формата YEAR-MONTH-DAY HOUR:MINUTE:SECOND).
- `labels` - %List названий колоно. Первый элемент - название сабскрипта.
- `namespace` - область в которой будет исполняться запрос.

## ExecuteClass

Обертка над `ExecuteGlobal`. На основе определения класса подготавливает вызов `ExecuteGlobal` и вызывает его.

`ExecuteClass(class, variable, type, start, end, properties, namespace)` - передача данных класса в Python.

Аргументы:
- `class` - имя класса
- `variable` - название Python переменной в которую записываются данные.
- `type` - `list` или Pandas `dataframe`.
- `start` - стартовый Id.
- `end` - конечный Id
- `properties` - список (разделитель - запятая) свойств класса, которые нужно загрузить в набор данных. Поддерживаются маски `*` и `?`. По умолчанию - `*` (все свойства). Свойство `%%CLASSNAME` игнорируется.
- `namespace` - область в которой будет исполняться запрос.

Все свойства передаюся как есть кроме свойств типов `%Date`, `%Time`, `%Boolean` и `%TimeStamp` - они конвертируются в соответствующие классы Python.

## ExecuteTable

Обертка над `ExecuteClass`. Транслирует имя таблицы в имя класса и вызывает `ExecuteClass`. Сигнатура:

`ExecuteTable(table, variable, type, start, end, properties, namespace)` - передача данных таблицы в Python.

Аргументы:
- `table` - имя таблицы.
Все остальные аргументы передаются как есть в `ExecuteClass`.

## Заметки 

- `ExecuteGlobal`, `ExecuteClass` и `ExecuteTable` работают одинаково быстро.
- `ExecuteGlobal` в 20 раз быстрее чем `ExecuteQuery` на больших наборах данных (время передачи более >0.01 секунды).
- `ExecuteGlobal`, `ExecuteClass` и `ExecuteTable` работают на глобалах с данной структурой: `^global(key) = $lb(prop1, prop2, ..., propN)` где `key` - целое число.
- Для `ExecuteGlobal`, `ExecuteClass` и `ExecuteTable` поддерживаемый диапазон значений `%Date` соответствует диапазону  `mktime` и зависит от ОС ([windows](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/mktime-mktime32-mktime64?view=vs-2019): 1970-01-01, [linux](https://linux.die.net/man/3/mktime) 1900-01-01, [mac](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/mktime.3.html)). Используйте `%TimeStamp`для передачи данных вне этого диапазона или используйте pandas dataframe т.к. это ограничение только для списка.
- Для `ExecuteGlobal`, `ExecuteClass` и `ExecuteTable` все аргументы кроме источника данных (глобала, класса или таблицы) и переменной опциональны.

## Примеры
Тестовый класс [isc.py.test.Person](https://github.com/intersystems-community/PythonGateway/blob/master/isc/py/test/Person.cls) содержит метод, демонстрирующий все варианты передачи данных:

```
set global = "isc.py.test.PersonD"
set class = "isc.py.test.Person"
set table = "isc_py_test.Person"
set query = "SELECT * FROM isc_py_test.Person"

// Общие аргументы
set variable = "df"
set type = "dataframe"
set start = 1
set end = $g(^isc.py.test.PersonD, start)

// Способ 0: ExecuteGlobal без аргументов
set sc = ##class(isc.py.Main).ExecuteGlobal(global, variable _ 0, type)

// Способ 1: ExecuteGlobal с аргументами	
// При передаче глобала названия полей задаются вручную
// globalKey - название сабсткрипта 
set labels = $lb("globalKey", "Name", "DOB", "TS", "RandomTime", "AgeYears", "AgeDecimal", "AgeDouble", "Bool")

// mask содержит на 1 элемент меньше чем labels потому что "globalKey" - название сабскипта
// Пропускаем %%CLASSNAME
set mask = "-+dmt+++b"

set sc = ##class(isc.py.Main).ExecuteGlobal(global, variable _ 1, type, start, end, mask, labels)

// Способ 2: ExecuteClass
set sc = ##class(isc.py.Main).ExecuteClass(class, variable _ 2, type, start, end)

// Способ 3: ExecuteTable
set sc = ##class(isc.py.Main).ExecuteTable(table, variable _ 3, type, start, end)

// Способ 4: ExecuteTable
set sc = ##class(isc.py.Main).ExecuteQuery(query, variable _ 4, type)
```
Вызовите метод `do ##class(isc.py.test.Person).Test()` чтобы посмотреть как работают все методы передачи данных.

## Вспомогательные методы

- `GetVariableInfo(variable, serialization, .defined, .type, .length)` - получить инфрмацию о переменной: определена ли она, класс и длинну сериализации.
- `GetVariableDefined(variable, .defined)` - определена ли переменная.
- `GetVariableType(variable, .type)` - получить класс переменной.
- `GetStatus()` - получить и удалить последнее исключение на стороне Python.
- `GetModuleInfo(module, .imported, .alias)` - получить переменную модуля и статус импорта.
- `GetFunctionInfo(function, .defined, .type, .docs, .signature, .arguments)` - получить информацию о функции.

# Интероперабельность

Вы научились вызывать Python Gateway из терминала, теперь начнем использовать его в продукции. Основа взаимодействия с Python в таком режиме - `isc.py.ens.Operation`. Он позволяет нам:

- Выполнять код на Python
- Сохраниять/Восстанавливать Python контекст
- Загружать и получать данные из Python

В принципе, Pyhton операция это обертка над `isc.py.Main`.  Операция  `isc.py.ens.Operation` дает возможность взаимодействия с процессом Python из продукций InterSystems IRIS. Поддерживается пять запросов:

- `isc.py.msg.ExecutionRequest` для исполнения Python кода. Возвращает `isc.py.msg.ExecutionResponse` с результатом исполнения и значениями запрошенных переменных.
- `isc.py.msg.StreamExecutionRequest` для исполнения Python кода. Возвращает `isc.py.msg.StreamExecutionResponse`  результатом исполнения и значениями запрошенных переменных. Аналог `isc.py.msg.ExecutionRequest`, но принимает и возвращает потоки вместо строк.
- `isc.py.msg.QueryRequest` для передачи результата исполнения SQL запроса. Возвращает `Ens.Response`.
- `isc.py.msg.GlobalRequest`/`isc.py.msg.ClassRequest`/`isc.py.msg.TableRequest` для передачи данных глобала/класса/таблицы. Возвращает `Ens.Response`.
-  `isc.py.msg.SaveRequest` для сохранения Python контекста. Возвращает `Ens.StringResponse` с идентификатором контекста.
- `isc.py.msg.RestoreRequest` для восстановления Python контекста.

 Кроме того `isc.py.ens.Operation` имеет две настройки:
 - `Initializer` - выбор класса, реализующего интерфейс `isc.py.init.Abstract`. Он может быть использован для загрузки функций, модулей, классов и т.п. Он будет выполняться при запуске процесса.
 - `PythonLib` - (только для Linux) если вы видите ошибки при загрузке, установите его значение равным `libpython3.6m.so` или даже в полному пути к библиотеке Python. 

# Создание бизнес-процессов

Доступно два класса, которые облегчают разработку Бизнес-процессов:
- `isc.py.ens.ProcessUtils` позволяет извлекать аннотации из активностей с подстановкой переменных.
- `isc.py.util.BPEmulator` позволяет легко тестировать бизнес-процессы с Python. Он может выполнять бизнес-процесс (части на языке Python) в текущем процессе.

# Подстановка переменных

Все бизнес-процессы, унаследованные от `isc.py.ens.ProcessUtils`, могут использовать метод `GetAnnotation(name)` для получения значения аннотации активности по её названию. Аннотация активности может содержать переменные, которые будут вычислены на стороне InterSystems IRIS перед передачей в Python. Вот синтаксис подстановки переменных:

- `${class:method:arg1:...:argN}` - вызов метода
- `#{expr}` - исполнить код на языке ObjectScript.

Пример доступен в тестовом бизнес-процесе `isc.py.ens.ProcessUtils` бизнес-процесса, например, в активности `Correlation Matrix: Graph`: `f.savefig(r'#{process.WorkDirectory}SHOWCASE${%PopulateUtils:Integer:1:100}.png')`.

В этом примере:
- `#{process.WorkDirectory}` возвращает свойство WorkDirectory объекта `process`, являющегося экземпляром класса `isc.py.test.Process` т.е. текущего бизнес-процесса.
- `${%PopulateUtils:Integer:1:100}` вызывает метод `Integer` класса `%PopulateUtils`, передавая аргументы `1` и `100`, возвращая случайное целое число в диапазоне `1...100`.

# Тестовый бизнес-процесс

Тестовая совместимость Производство и тестовый бизнес-процесс доступны по умолчанию как часть шлюза Python Gateway. Для их использования:

1. В терминале ОС выполните: `pip install pandas matplotlib seaborn`. 
2. В терминале InterSystems IRIS выполните: `do ##class(isc.py.test.CannibalizationData).Import()` для заполнения тестовых данных.
3. Запустите продукцию `isc.py.test.Production`.
4. Отправить запрос типа `Ens.Request` в `isc.py.test.Process`.

Посмотрим, как все это будет работать вместе. Откройте `isc.py.test.Process` в редакторе BPL (или студии):

![](https://habrastorage.org/webt/5w/cx/hg/5wcxhgqpv9qvbyagnrawcuemxi4.png)

## Исполнение кода

Самый важный вызов - исполнение Python кода:

![](https://habrastorage.org/webt/ue/ct/bd/uectbds3ygxhohfkqyfzpkij4dg.png)

Используется запрос `isc.py.msg.ExecutionRequest`, вот его свойства:
- `Code` - Python код.
- `SeparateLines` - разделять ли код на строки для выполнения. `$c(10)` (`\n`) используется для разделения строк. Обратите внимание, что НЕ рекомендуется обрабатывать сообщение целиком сразу, эта функция предназначена только для обработки `def` и подобных многострочных выражений. По умолчанию 0.
- `Variables` - разделенный запятыми список переменных, которые будут добавлены в ответ.
- `Serialization` - Как сериализовать переменные, которые мы хотим вернуть. Варианты: `Str`, `Repr`, `JSON`, `Pickle` и `Dill`, по умолчанию `Str`.

В нашем случае, мы только устанавливаем свойство `Code`, так что все остальные свойства спользуют значения по умолчанию. Мы устанавливаем его вызовом `process.GetAnnotation("Import pandas")`, который во время выполнения возвращает аннотацию после выполнения подстановки переменных. В конце концов, код `import pandas as pd` будет передан в Python. `GetAnnotation` может быть полезна для получения многострочных питоновских скриптов, но никаких ограничений на данный способ получения кода нет. Вы можете установить свойство `Code` любым удобным для вас способом.

## Получение переменных

Еще один интересный вызов с использованием `isc.py.msg.ExecutionRequest` - `Correlation Matrix: Tabular`:

![](https://habrastorage.org/webt/zo/_r/ae/zo_raex_ziab1adyzcgkgi20oam.png)

![](https://habrastorage.org/webt/zo/_r/ae/zo_raex_ziab1adyzcgkgi20oam.png)

Он вычисляет Матрицу Корреляции на стороне Python и извлекает переменную `corrmat` обратно в InterSystems IRIS в формате JSON, путем установки свойств запроса:
- `Variables`: `"corrmat"`
- `Serialization`: `"JSON"`

Мы можем видеть результаты в Visual Trace:

![](https://habrastorage.org/webt/ha/ef/ki/haefki0xwu4j21gearr44sdd4pc.png)

И если нам это значение понадобится в БП, его можно получить так: `callresponse.Variables.GetAt("corrmat")`.

## Передача данных

Далее поговорим о передаче данных из InterSystems IRIS в Python, все запросы на передачу данных реализуют интерфейс `isc.py.msg.DataRequest`, который предоставляет следующие свойства:
- `Variable` - переменная Python в которую записываются данные.
- `Type` - тип переменной:`dataframe` (pandas dataframe) или `list`.
- `Namespace` -  область из которой получаем данные. Пакет 'isc.py' должен быть доступен в этой области. Это может быть область без подддержки продукций.

На основе этого интерфейса реализованы 4 класса запросов:
- `isc.py.msg.QueryRequest` - установите свойство `Query` для передачи SQL запроса.
- `isc.py.msg.ClassRequest` - установите свойство `Class` для передачи данных класса.
- `isc.py.msg.TableRequest` - установить свойство `Table` для передачи данных таблицы.
- `isc.py.msg.GlobalRequest` - установить свойство `Global` для передачи данных глобала.

В тестовом процессе посмотрите на активность `RAW`, где `isc.py.msg.QueryRequest` показан в действии.

![](https://habrastorage.org/webt/kz/xy/yb/kzxyybhwvfsymqhgkvqlph6k9rw.png)

## Сохранить/восстановить Python контекст

Наконец, мы можем сохранить Python контекст в InterSystems IRIS, чтобы сделать это, отправим `isc.py.msg.SaveRequest` с аргументами:
- `Mask` - Сохраняются только переменные, удовлетворяющие маске. Поддерживаются `*` и `?`. Пример: `"Data*, Figure?"`. По умолчанию `*`.
- `MaxLength` - Максимальная длина сохраняемой переменной. Если сериализация переменной длиннее, то она будет проигнорирована. Установите 0, чтобы получить переменные любой длины. По умолчанию `$$MaxStringLength`.
- `Name` - Имя контекста (опционально).
- `Description` - Описание контекста (опционально).

Возвращает `Ens.StringResponse` с `Id` сохраненного контекста. В тестовом процессе посмотрите на активность `Save Context`.

Соответствующий запрос `isc.py.msg.RestoreRequest` загружает контекст из InterSystems IRIS в Python:
- `ContextId` - идентификатор контекста.
- `Clear` - очистить контекст перед восстановлением.

# Jupyter Notebook

[Jupyter Notebook](https://jupyter.org/) - это веб-приложение с открытым исходным кодом, позволяющее создавать ноутбуки, содержащие  код, визуализации и текст и публиковать их. Python Gateway позволяет просматривать и редактировать BPL-процессы в виде Jupyter Notebook. Обратите внимание, что в настоящее время используется обычный executor Python 3.

Это расширение предполагает, что аннотации содержат код Python и используют названия активностей в качестве предшествующих заголовков. Теперь возможно разрабатывать бизнес-процессы PythonGateway в Jupyter Notebook. Вот что возможно: 
- Создавать новые бизнес-процессы
- Удалять бизнес-процессы
- Создавать новые активности
- Изменять активности
- Удалять активности

Вот [демо-видео](https://youtu.be/mZizgVtZ014). И несколько скриншотов:

### Проводник процессов

![](https://camo.githubusercontent.com/d74763eab501ee0804ce2408ce33de882189528f/68747470733a2f2f692e696d6775722e636f6d2f4441573330555a2e706e67)

### Редактор процесса

![](https://camo.githubusercontent.com/e25e9ee72f270a906bead73d7d294118bb1deccc/68747470733a2f2f692e696d6775722e636f6d2f343371413342312e706e67)

## Установка

1. Вам понадобится InterSystems IRIS 2019.2+.
2. Установите PythonGateway v0.8+ (требуется только `isc.py.util.Jupyter`, `isc.py.util.JupyterCheckpoints` и `isc.py.ens.ProcessUtils`).
3. Обновите код ObjectScript из репозитория.
4. Выполните `do ##class(isc.py.util.Jupyter).Install()` и следуйте подсказкам.

[Документация](https://github.com/intersystems-community/PythonGateway/tree/master/jupyter).

# Выводы

# Ссылки

- [Python Gateway](https://openexchange.intersystems.com/package/PythonGateway)
- [Python Gateway Samples](https://openexchange.intersystems.com/package/Python-Gateway-Samples)
- [Python 3.6.7 64 bit](https://www.python.org/downloads/release/python-367/)
- [Документация и курсы по Python](https://docs.python.org/3.6/tutorial/index.html)

# Юзергруппа

Есть также иллюстрированное руководство в группе пользователей MLToolkit. Группа пользователей MLToolkit - это частный GitHub-репозиторий, созданный как часть корпоративной GitHub-организации InterSystems. Она адресована внешним пользователям, которые устанавливают, изучают или уже используют компоненты MLToolkit, включая Python Gateway. Чтобы присоединиться к группе пользователей ML Toolkit, пожалуйста, отправьте короткое сообщение по электронной почте по следующему адресу: [MLToolkit@intersystems.com](mailto:MLToolkit@intersystems.com?subject=MLToolkit%20user%20group&body=Hello.%0A%0APlease%20add%20me%20to%20ML%20Toolkit%20user%20group%3A%0A%0A-%20GitHub%20username%3A%20%0A%0A-%20Name%3A%20%0A%0A-%20Company%3A%20%0A%0A-%20Position%3A%0A-%20Country%3A%20%0A%0A) и укажите в своем  письме следующие данные:

- Имя пользователя GitHub
- Организация (вы работаете или учитесь)
- Должность (ваша фактическая должность в вашей организации, или "Студент", или "Независимый").
- Страна

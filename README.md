# Реализация атомарной обработки данных

* [Базовый класс](#AtomicTaskPP)
* [Создание атомарной задачи](#AtomicTaskPP_Create)
* [Resources](#Resources)
    * [Resource::Data](#Resource_Data)
    * [Resource::JSON](#Resource_JSON)
    * [Resource::BSON](#Resource_BSON)
    * [Resource::XML](#Resource_XML)
    * [Resource::File](#Resource_File)
    * [Resource::MemFile](#Resource_MemFile)
    * [Resource::XmlFile](#Resource_XmlFile)
    * [Resource::Imager](#Resource_Imager)

<a name="AtomicTaskPP"></a>

## Базовый класс 


[AtomicTaskPP](AtomicTaskPP.pm)

Принимает массив модифицируемых ресурсов (`Resource::*`) и дополнительные параметры:

```perl
    sub new 
    {
        my ( $class, $resources, $params ) = @_;
        =for comment
            $resources => [ 
                Resource::*, ... 
            ]
            $params = {
                id          => SCALAR, # ID задачи, при отсутствии будет сгенерирован
                quiet       => bool,   # выводить предупреждения или нет
                mutex       => OBJECT, # должен уметь ->lock() и ->unlock()
                commit_lock => bool,   # блокировать всё исполнение или только коммит
            }
        =cut
        # ...
    }
```
В случае ошибок генерирует исключение. После успешной инициализации можно вызывать
метод `run()`. В нём:

* создаются рабочие копии русурсов
* вызывается метод `execute()` (должен быть перегружен в дочернем объекте)
* в случае успешного его завершения замещает исходные ресурсы модифицированными копиями (`commit`)
* при ошибках замещения возвращает изменённые ресурсы на место (`rollback`)

<a name="AtomicTaskPP_Create"></a>

## Создание атомарной задачи

Необхдимо унаследоваться от [AtomicTaskPP](AtomicTaskPP.pm) и перегрузить метод `execute()`:

```perl
    package ATask;
    use AtomicTaskPP;
    use base qw/AtomicTaskPP/;

    sub execute
    {
        my ($self) = @_;
        =for comment
            Здесь доступны:
                my @resources = @{ $self->{resources} };
                my %params    = @{ $self->{params} };
                my $id        = $self->{id};
            На практике достаточно:
        =cut
            my $id       = $self->id();
            # получить ресурс:
            my $resource = $self->rget('RESOURCE_ID');
            # получить рабочую копию данных ресурса:
            my $work     = $self->wget('RESOURCE_ID');
            # или
            $work = $resource->{work};
        =for comment
            Здесь делаем с делаем с рабочими копиями ресурсов что хотим.
            В случае ошибок вернуть сообщение:
                return 'Усё пропало, шеф!';
            Или ничего (всё хорошо).
            Если были изменения - обязательно выставить флаг модификации
        =cut
            $resource->modified(1);
            return;
    }

    use Mutex;
    my $task = ATask->new( [$xml_file], { mutex => Mutex->new, quiet => 1 } );
```

<a name="Resources"></a>

## Ресурсы

Наследуются от абстрактного класса [Resource::Base](Resource/Base.pm). 
Конструктор принимает ссылку на хэш с параметрами:

```perl
    sub new
    {
        my ($self, $params ) = @_;
        =for comment
            $params = {
                id     => SCALAR,     # ID, при отсутствии будет сгенерирован
                quiet  => bool,       # выводить предупреждения или нет
                SOURCE => VALUE,      # ОБЯЗАТЕЛЬНЫЙ аргумент, значение
                                      # зависит от типа ресурса
                # ... дополнительные данные
            }
        =cut
    }
```

Например:

```perl
    use Resource::XmlFile;
    my $xml_file = Resource::XmlFile->new( { source => '../data/test.xml' } );
```

<a name="Resource_Data"></a>

### [Resource::Data](Resource/Data.pm)

Любая структура данных (SCALAR, HASH, ARRAY, OBJECT). В случае blessed-объекта для 
корректного копирования в объекте должен быть (при необходимости) метод `clone()`.

```perl
    use Resource::Data;
    my $data = { a => 1, b => 2 };
    my $r_data = Resource::Data->new( { source => \$data } );
```

`AtomicTaskPP::wget()` возвращает копию исходной структуры данных.

<a name="Resource_JSON"></a>

### [Resource::JSON](Resource/JSON.pm)

Скаляр с JSON. Дополнительно могут быть указаны методы для управления парсером, см. 
[JSON::XS#OBJECT-ORIENTED-INTERFACE](https://metacpan.org/pod/JSON::XS#OBJECT-ORIENTED-INTERFACE).

```perl
    use Resource::JSON;
    my $json = '{"a":1, "b":2}';
    my $r_json = Resource::JSON->new( { source => \$json, json => { pretty => 1 } } );
```

`AtomicTaskPP::wget()` возвращает хэш с результатами разбора JSON.

<a name="Resource_BSON"></a>

### [Resource::BSON](Resource/BSON.pm)

Скаляр с BSON. Дополнительно могут быть указаны флаги для управления парсером, см. 
[BSON#ATTRIBUTES](https://metacpan.org/pod/BSON#ATTRIBUTES).

```perl
    use Resource::BSON;
    my $bson = '';
    my $r_bson = Resource::BSON->new( { source => \$bson, bson => { prefer_numeric => 1 } } );
```

`AtomicTaskPP::wget()` возвращает хэш с результатами разбора BSON.

<a name="Resource_XML"></a>

### [Resource::XML](Resource/XML.pm)

Скаляр с XMP. Дополнительно могут быть указаны методы для управления парсером, см. 
[XML::Hash::XS#OPTIONS](https://metacpan.org/pod/XML::Hash::XS#OPTIONS).

```perl
    use Resource::XML;
    my $xml = '<root a="1" b="2">text</root>';
    my $r_xml = Resource::XML->new( { source => \$xml, xml => { indent => 2 } } );
```

`AtomicTaskPP::wget()` возвращает хэш с результатами разбора XML.

<a name="Resource_File"></a>

### [Resource::File](Resource/File.pm)

Произвольный файл. В конструкторе только один обязательный параметр: имя файла.

```perl
    use Resource::File;
    my $r_file = Resource::File->new( { source => './data/hello.txt' } );
```

`AtomicTaskPP::wget()` возвращает объект [Path::Tiny](https://metacpan.org/pod/Path::Tiny).

<a name="Resource_MemFile"></a>

### [Resource::MemFile](Resource/MemFile.pm)

То же самое, но `AtomicTaskPP::wget()` возвращает буфер в памяти с содержимым исходного файла.

<a name="Resource_XmlFile"></a>

### [Resource::XmlFile](Resource/XmlFile.pm)

Аналогично `Resource::XML`, но на входе имя файла:

```perl
    use Resource::XmlFile;
    my $r_xmlfile = Resource::XmlFile->new( { source => './data/hello.xml', xml => { keep_root => 1 } } );
```

<a name="Resource_Imager"></a>

### [Resource::Imager](Resource/Imager.pm)

Картинка. Поддерживаются форматы `raw, sgi, bmp, pnm, ico, jpeg, tga, png, gif, tiff`.

```perl
    use Resource::Imager;
    my $r_img = Resource::Imager->new( { source => './data/hello.jpg' );
```

`AtomicTaskPP::wget()` возвращает объект [Imager](https://metacpan.org/pod/Imager).

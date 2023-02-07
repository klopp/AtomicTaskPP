# Реализация атомарной обработки данных

* [Базовый класс](#AtomicTaskPP)
* [Создание атомарной задачи](#создание-атомарной-задачи)
* [Ресурсы](#ресурсы)
    * [Atomic::Resource::Data](#atomicresourcedata)
    * [Atomic::Resource::JSON](#atomicresourcejson)
    * [Atomic::Resource::BSON](#atomicresourcebson)
    * [Atomic::Resource::XML](#atomicresourcexml)
    * [Atomic::Resource::File](#atomicresourcefile)
    * [Atomic::Resource::MemFile](#atomicresourcememfile)
    * [Atomic::Resource::XmlFile](#atomicresourcexmlfile)
    * [Atomic::Resource::Imager](#atomicresourceimager)
* [Блокировка](#блокировка)
 	* [Mutex::GlobalLock]
 	* [Mutex::LockSocket]
 	* [Mutex::IOLambda]
 	* [Mutex::LinuxFutex]
* [Создание ресурса](#создание-ресурса)
    * [Перегружаемые методы](#перегружаемые-методы)

<a name="Atomic::Task"></a>

## Базовый класс 

[Atomic::Task](Atomic/Task.pm)

Принимает массив модифицируемых ресурсов (`Atomic::Resource::*`) и дополнительные параметры:

```perl
    sub new 
    {
        my ( $class, $resources, $params ) = @_;
        #   $resources => [ 
        #       Atomic::Resource::*, ... 
        #   ]
        #   $params = {
        #       id          => SCALAR, # ID задачи, при отсутствии будет сгенерирован
        #       quiet       => bool,   # выводить предупреждения или нет
        #       mutex       => OBJECT, # должен уметь ->lock() и ->unlock()
        #                      хорошие кандидаты:
        #                      * ! Mutex :: https://metacpan.org/pod/Mutex
        #                      * ! MCE::Mutex :: https://metacpan.org/pod/MCE::Mutex
        #                      * ! JIP::LockFile :: https://metacpan.org/pod/JIP::LockFile
        #                      * ! JIP::LockSocket :: https://metacpan.org/pod/JIP::LockSocket
        #                      * ~~~
        #                      * Global::MutexLock
        #                      * ! Lock::Socket
        #                      * ? IO::Lambda::Mutex
        #                      * Linux::Futex
        #       commit_lock => bool,   # блокировать всё исполнение или только коммит
        #   }
        # ...
    }
```
В случае ошибок генерирует исключение. После успешной инициализации можно вызывать
метод `run()`. В нём:

* создаются рабочие копии русурсов
* вызывается метод `execute()` (должен быть перегружен в дочернем объекте)
* в случае успешного его завершения замещает исходные ресурсы модифицированными копиями (`commit`)
* при ошибках замещения возвращает изменённые ресурсы на место (`rollback`)

## Создание атомарной задачи

Необхдимо унаследоваться от [Atomic::Task](Atomic/Task.pm) и перегрузить метод `execute()`:

```perl
    package ATask;
    use Atomic::Task;
    use base qw/Atomic::Task/;

    sub execute
    {
        my ($self) = @_;
        #   Здесь доступны:
        #       my @resources = @{ $self->{resources} };
        #       my %params    = @{ $self->{params} };
        #       my $id        = $self->{id};
        #   На практике достаточно:
                my $id       = $self->id();
        #   Получить ресурс:
                my $resource = $self->rget('RESOURCE_ID');
        #   Получить рабочую копию данных ресурса:
                my $work     = $self->wget('RESOURCE_ID');
        #   или
                $work = $resource->{work};
        #   Здесь делаем с делаем с рабочими копиями ресурсов что хотим.
        #   В случае ошибок вернуть сообщение:
                return 'Усё пропало, шеф!';
        #   Или ничего (всё хорошо).
        #   Если были изменения - обязательно выставить флаг модификации
                $resource->modified(1);
                return;
    }

    use Mutex;
    my $task = ATask->new( [$xml_file], { mutex => Mutex->new, quiet => 1 } );
```

<a name="Resources"></a>

## Ресурсы

Наследуются от абстрактного класса [Atomic::Resource::Base](Atomic/Resource/Base.pm). 
Конструктор принимает ссылку на хэш с параметрами:

```perl
    sub new
    {
        my ($self, $params ) = @_;
        #   $params = {
        #       id     => SCALAR,     # ID, при отсутствии будет сгенерирован
        #       quiet  => bool,       # выводить предупреждения или нет
        #       SOURCE => VALUE,      # ОБЯЗАТЕЛЬНЫЙ аргумент, значение
        #                             # зависит от типа ресурса
        #       # ... дополнительные данные
        #   }
    }
```

В случае ошибок конструктор генерирует исключение. 

```perl
    use Atomic::Resource::XmlFile;
    use Try::Tiny;
    my $xml_file;
    try {
        $xml_file = Atomic::Resource::XmlFile->new( { source => '../data/test.xml' } );
    }
    catch {
        say sprintf 'Error: %s', $_;
    };
```

### [Atomic::Resource::Data](Atomic/Resource/Data.pm)

Любая структура данных (SCALAR, HASH, ARRAY, OBJECT). В случае blessed-объекта для 
корректного копирования в объекте должен быть (при необходимости) метод `clone()`.

```perl
    use Atomic::Resource::Data;
    my $data = { a => 1, b => 2 };
    my $r_data = Atomic::Resource::Data->new( { source => \$data } );
```

`Atomic::Task::wget()` возвращает копию исходной структуры данных.

<a name="Resource_JSON"></a>

### [Atomic::Resource::JSON](Atomic/Resource/JSON.pm)

Скаляр с JSON. Дополнительно могут быть указаны методы для управления парсером, см. 
[JSON::XS#OBJECT-ORIENTED-INTERFACE](https://metacpan.org/pod/JSON::XS#OBJECT-ORIENTED-INTERFACE).

```perl
    use Atomic::Resource::JSON;
    my $json = '{"a":1, "b":2}';
    my $r_json = Atomic::Resource::JSON->new( { source => \$json, json => { pretty => 1 } } );
```

`Atomic::Task::wget()` возвращает хэш с результатами разбора JSON.

<a name="Resource_BSON"></a>

### [Atomic::Resource::BSON](Atomic/Resource/BSON.pm)

Скаляр с BSON. Дополнительно могут быть указаны флаги для управления парсером, см. 
[BSON#ATTRIBUTES](https://metacpan.org/pod/BSON#ATTRIBUTES).

```perl
    use Atomic::Resource::BSON;
    my $bson = '';
    my $r_bson = Atomic::Resource::BSON->new( { source => \$bson, bson => { prefer_numeric => 1 } } );
```

`Atomic::Task::wget()` возвращает хэш с результатами разбора BSON.

<a name="Resource_XML"></a>

### [Atomic::Resource::XML](Atomic/Resource/XML.pm)

Скаляр с XMP. Дополнительно могут быть указаны методы для управления парсером, см. 
[XML::Hash::XS#OPTIONS](https://metacpan.org/pod/XML::Hash::XS#OPTIONS).

```perl
    use Atomic::Resource::XML;
    my $xml = '<root a="1" b="2">text</root>';
    my $r_xml = Atomic::Resource::XML->new( { source => \$xml, xml => { indent => 2 } } );
```

`Atomic::Task::wget()` возвращает хэш с результатами разбора XML.

<a name="Resource_File"></a>

### [Atomic::Resource::File](Atomic/Resource/File.pm)

Произвольный файл. В конструкторе только один обязательный параметр: имя файла.

```perl
    use Atomic::Resource::File;
    my $r_file = Atomic::Resource::File->new( { source => './data/hello.txt' } );
```

`Atomic::Task::wget()` возвращает объект [Path::Tiny](https://metacpan.org/pod/Path::Tiny).

<a name="Resource_MemFile"></a>

### [Atomic::Resource::MemFile](Atomic/Resource/MemFile.pm)

То же самое, но `Atomic::Task::wget()` возвращает буфер в памяти с содержимым исходного файла.

<a name="Resource_XmlFile"></a>

### [Atomic::Resource::XmlFile](Atomic/Resource/XmlFile.pm)

Аналогично `Atomic::Resource::XML`, но на входе имя файла:

```perl
    use Atomic::Resource::XmlFile;
    my $r_xmlfile = Atomic::Resource::XmlFile->new( { source => './data/hello.xml', xml => { keep_root => 1 } } );
```

<a name="Resource_Imager"></a>

### [Atomic::Resource::Imager](Atomic/Resource/Imager.pm)

Картинка. Поддерживаются форматы `raw, sgi, bmp, pnm, ico, jpeg, tga, png, gif, tiff`.

```perl
    use Atomic::Resource::Imager;
    my $r_img = Atomic::Resource::Imager->new( { source => './data/hello.jpg' } );
```

`Atomic::Task::wget()` возвращает объект [Imager](https://metacpan.org/pod/Imager).

<a name="Resource_Create"></a>

## Создание ресурса

Чтобы создать свой ресурс необходимо унаследоваться от одного из существующих типов и перегрузить необходимые методы. Методы должны возвращать undef в лучае успешного завершения или сообщение об ошибке.

### Перегружаемые методы

```perl
sub check_params
{
    my ($self) = @_;
#   Проверка входных параметров ($self->{params}, или вообще чего угодно).
#   МОЖЕТ быть перегружен в производных объектах.
#   NB! Проверка НАЛИЧИЯ {params}->{source} происходит в базовом конструкторе.
    return;
}
```

```perl
sub create_backup_copy
{
#   Создание копии ресурса для отката. ДОЛЖЕН быть перегружен.
    my ($self) = @_;
    return 'Stub only';
}
```

```perl
sub delete_backup_copy
{
#   Удаление копии ресурса для отката. ДОЛЖЕН быть перегружен.
    my ($self) = @_;
    return 'Stub only';
}
```

```perl
sub create_work_copy
{
#   Создание рабочей копии ресурса для модификации. ДОЛЖЕН быть перегружен.
    my ($self) = @_;
    return 'Stub only';
}
```

```perl
sub delete_work_copy
{
#   Удаление рабочей копии ресура. ДОЛЖЕН быть перегружен в.
    my ($self) = @_;
    return 'Stub only';
}
```

```perl
sub commit
{
#   Замена ресурса на рабочую копию. ДОЛЖЕН быть перегружен.
    my ($self) = @_;
    return 'Stub only';
}
```

```perl
sub rollback
{
#   Замена ресурса на резервную копию. ДОЛЖЕН быть перегружен.
    my ($self) = @_;
    return 'Stub only';
}
```

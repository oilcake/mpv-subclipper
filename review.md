# 🔍 Subcliper — Code Review

Review of all `.lua` files. Focus on correctness, Lua best practices, and code clarity. Issues sorted by severity.

> **Summary:** 2 critical, 3 high, 6 medium, 5 low / style. Most serious: incorrect OOP constructors → singleton/shared‑state behaviour, leaked global variable.

---

## `cut.lua`

- [x] **`🔴 CRITICAL` — `HandSaw:new()`: конструктор создавал синглтон вместо нового экземпляра (ИСПРАВЛЕНО)**
  
  ```lua
  -- БЫЛО (баг):
  function HandSaw:new(file, output_location)
      setmetatable({}, self)  -- результат выброшен!
      self.__index = self
      self.file = file
      ...
      return self  -- возвращается прототип HandSaw, а не новый объект
  end
  
  -- СТАЛО:
  function HandSaw:new(file, output_location)
      local o = {}
      setmetatable(o, self)
      self.__index = self
      o.file = file
      ...
      return o
  end
  ```
  
  `setmetatable({}, self)` создавал новую таблицу но результат терялся. Дальше функция модифицировала `self` (прототип `HandSaw`) и возвращала его же. **Все «экземпляры» были одной таблицей.** При обработке папки каждый следующий файл затирал данные предыдущего.

- ✅ **RESOLVED — `o.scaled_height = self.height`**
  
  Строка закомментирована (`-- o.scaled_height = o.height`). Проблема устранена.

- [ ] **`🟠 HIGH` — Дублирование логики в `format_args()` и `copy_clip()`**
  
  Оба метода независимо вычисляют `clip_name` и `clip_path`. При изменении формата имени придётся править в двух местах. Лучше вынести формирование имени в отдельный метод или вызывать `format_args` из `copy_clip`.

---

## `subcliper.lua`

- [ ] **`🔴 CRITICAL` — `Index`: утечка в глобальную область видимости**
  
  ```lua
  local Regions = {}
  
  Index = 1  -- нет local! Переменная стала глобальной
  ```
  
  Случайно пропущенный `local`. mpv выполняет все скрипты в одном Lua-состоянии — глобальная `Index` может конфликтовать с другими плагинами. Нужно: `local Index = 1`.

- [x] **`🟠 HIGH` — `Loop:new()`: сломанный конструктор (ИСПРАВЛЕНО)**
  
  ```lua
  -- БЫЛО:
  function Loop:new(a, b)
      self = {}              -- перезаписывает неявный параметр self
      setmetatable({}, self) -- результат выброшен
      self.a = a
      self.b = b
      return self            -- пустая таблица без метатаблицы
  end
  
  -- СТАЛО:
  function Loop:new(a, b)
      local l = {}
      setmetatable(l, self)
      self.__index = self
      l.a = a
      l.b = b
      return l
  end
  ```
  
  Работало только потому, что экземпляры Loop — простые контейнеры `{a, b}` без методов. Но код вводил в заблуждение.

- 🆕 **`🆕 NEW` — Лог-файл не закрывается на пути ошибок в `process_folder`**
  
  `Batch:new()` открывает `o.log` и делает `io.output(o.log)`. В `process_folder()` вызов `self.log:close()` происходит только на пути успеха (`"success!"`). При досрочном прерывании (`done == nil` / `done == false`) дескриптор остаётся открытым. Кроме того, `io.output(o.log)` меняет глобальный поток вывода для всего Lua-состояния — побочный эффект на другие модули.
  
  **Рекомендация:** использовать `o.log:write(...)` вместо `io.output()` + `io.write()`, закрывать лог во всех точках возврата.

- [ ] **`🔵 MEDIUM` — `scene_list_file_to_regions`: вызов `collectgarbage()`**
  
  Принудительный сборщик мусора посреди функции — костыль. Если проблема в нехватке памяти при большом количестве сцен, лучше потоковая обработка без накопления. Если нет — убрать.

- [ ] **`⚪ LOW` — `loop_drop`: неконсистентное состояние при удалении**
  
  `remove_region()` вызывает `unset_loop()`, который обращается к mpv API без проверки, остались ли регионы. После удаления последнего региона вызывается `looper.init()`, что восстанавливает состояние, но промежуточный `unset_loop()` избыточен и может вызвать предупреждения mpv при пустом списке.

---

## `batch.lua`

- [x] **`🟠 HIGH` — `Batch:new()`: модифицирует прототип, а не создаёт экземпляр (ИСПРАВЛЕНО)**
  
  ```lua
  -- БЫЛО:
  function Batch:new(output_folder)
      self.output_folder = output_folder
      ...
      return self  -- self === Batch (прототип)
  end
  
  -- СТАЛО:
  function Batch:new(output_folder)
      local o = {}
      setmetatable(o, self)
      self.__index = self
      o.output_folder = output_folder
      ...
      return o
  end
  ```
  
  При однократном использовании (как в `process.lua`) старый код работал, но повторный вызов `:new()` перезаписывал состояние.

- [x] **`🔵 MEDIUM` — Переменная `type` затеняет встроенную функцию**
  
  ```lua
  local _, _, type = path.strip_path(file)
  if type ~= "clp" and type ~= "scn" then ...
  ```
  
  `type` — имя встроенной функции Lua. Переопределение запутывает. Лучше: `ext`.

- [ ] **`🔵 MEDIUM` — Ненадёжная проверка exit code 255**
  
  ```lua
  if status.code == 255 then
      io.write("most probably incomplete and will be deleted:\n" ...)
      os.remove(clip.clip_path)
  end
  ```
  
  Код 255 не стандартный для «неполного файла». Лучше проверять реальный размер выходного файла или длительность через ffprobe.

- [ ] **`⚪ LOW` — `remove_original`: перемещение в `__READY`**
  
  Исходные файлы перемещаются в поддиректорию `__READY` по мере обработки каждого файла. Если операция упадёт на середине — часть уже перемещена, часть нет. Надёжнее перемещать только после полного успеха, либо вести лог отдельно.

---

## `path.lua`

- [ ] **`🔵 MEDIUM` — `strip_path`: файлы в корне возвращают nil**
  
  ```lua
  function M.strip_path(path_to_file)
      local path = path_to_file:match("^/?(.+)/")   -- требует хотя бы один /
      local name = path_to_file:match(".+/(.+)%..+$")
      local type = path_to_file:match(".+%.(.+)$")
  end
  ```
  
  Для `/video.mp4` или `video.mp4` ни один паттерн не сработает — все три переменные будут `nil`. Нужен fallback: если `path` не найден → `""`; если `name` не найден → поиск без директории.

- [ ] **`🔵 MEDIUM` — `M.exists`: хак с `os.rename(file, file)`**
  
  Трюк с переименованием файла в самого себя работает на большинстве Unix (rename(2) no-op), но может обновить mtime на некоторых ФС. Надёжнее:
  
  ```lua
  function M.exists(file)
      local f = io.open(file, "r")
      if f then f:close(); return true end
      return false
  end
  ```

- [ ] **`⚪ LOW` — `M.move`: баг с файлами без расширения**
  
  ```lua
  local _, name, ext = M.strip_path(file)
  local full_name = name .. "." .. ext   -- ext = nil → "name.nil"
  ```
  
  Нужно: `local full_name = ext and (name .. "." .. ext) or name`.

- [ ] **`⚪ LOW` — `M.listdir`: `find` без экранирования спецсимволов в пути**
  
  ```lua
  local p = io.popen('find "' .. dir .. '" -type f')
  ```
  
  Двойные кавычки не спасают от `$` и `` ` ``. Лучше через `M.escape_shell`.

---

## `serializer.lua`

- [ ] **`⚪ LOW` — Использование `%q` в Lua 5.1 / LuaJIT**
  
  `string.format("%q", s)` официально добавлен в Lua 5.2. mpv использует LuaJIT (поддерживает), но для переносимости на vanilla 5.1 стоило бы реализовать `exportstring` вручную.

- [ ] **`⚪ LOW` — Комментарии-разделители из дефисов**
  
  Многострочные разделители из 100+ дефисов создают визуальный шум. Достаточно `--` или короткого разделителя.

---

## `process.lua`

- [ ] **`🔵 MEDIUM` — Парсинг аргументов без проверки ошибок**
  
  ```lua
  for i, v in ipairs(args) do
      if v == "--input" then
          folder = args[i + 1]
      end
  end
  ```
  
  Если `--input` последний аргумент — `args[i+1]` будет `nil`. Если `--input --output` — `--output` станет путём к input. Нет валидации обязательных параметров. Стоит добавить `--help`.

- [ ] **`⚪ LOW` — Избыточная проверка `if b ~= nil then`**
  
  `batch:new()` всегда возвращает объект (или падает) — проверка на nil не имеет смысла.

---

## `main.lua`

- [ ] **`🎨 STYLE` — Закомментированный код**
  
  ```lua
  --[[
  mp.add_key_binding("§", "save", add your function here)
  --]]
  ```
  
  Мёртвый код лучше убрать. Если пример — вынести в README или однострочный комментарий.

---

## 🎯 Общие замечания

- [ ] **`🎨 STYLE` — Неединообразный стиль OOP**
  
  Три реализации конструкторов — все три разные. Выберите один паттерн:
  
  ```lua
  local MyClass = {}
  
  function MyClass:new(...)
      local o = {}
      setmetatable(o, self)
      self.__index = self
      -- инициализация полей o
      return o
  end
  ```

- [ ] **`🎨 STYLE` — Именование: смесь стилей**
  
  `CamelCase` (`HandSaw`, `Regions`), `snake_case` (`validate_region`, `set_loop`), `UPPER_CASE` (`FFMPEG`, `SPACE`, `KEEP`). Конвенции Lua: `snake_case` для функций/переменных, `PascalCase` для классов.

- [ ] **`🎨 STYLE` — Избыточные модульные константы в `cut.lua`**
  
  `SPACE`, `COMMA`, `INPUT` используются только внутри `HandSaw`. Можно сделать полями класса или инлайнить.

---

## 📋 Итого по приоритетам

| Приоритет     | Замечания                                                                                                          |
| ------------- | ------------------------------------------------------------------------------------------------------------------ |
| 🔴 Critical   | ~~HandSaw:new — синглтон~~ ✅, `Index` — глобальная переменная                                                      |
| 🟠 High       | ~~Loop:new — сломан~~ ✅, ~~Batch:new — синглтон~~ ✅, дублирование в `cut.lua`                                      |
| 🆕 New        | Лог не закрывается на ошибках в `batch.lua`                                                                        |
| 🔵 Medium     | `collectgarbage`, затенение `type`, exit code 255, `strip_path` + `move` баги, парсинг аргументов, `os.rename` хак |
| ⚪ Low / Style | `listdir` экранирование, `%q` в LuaJIT, мёртвый код, неединообразный стиль                                         |
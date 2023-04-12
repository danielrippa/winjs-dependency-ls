
  dependency = do ->

    new-exception = (name, message, exception-stack) -> { name, message, exception-stack }

    fn-exception = (fn-name) -> (arg-name, message, previous-exception) -> new-exception "dependency.ls #fn-name (#arg-name)", message, previous-exception

    string = do ->

      us = String.from-char-code 31

      trim-regex = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g

      replace-crlf = (.replace /\r\n/g, us)
      replace-lf = (.replace /\n/g, us)
      replace-cr = (.replace /\r/g, us)
      replace-ff = (.replace /\f/g, us)

      string-as-units = -> it |> replace-crlf |> replace-lf |> replace-cr |> replace-ff

      units-as-array = (.split us)

      lcase = (.to-lower-case!)

      string-as-array = -> it |> string-as-units |> units-as-array

      trim = (.replace trim-regex, '')

      {
        lcase, string-as-array, trim
      }

    file-system = do ->

      { text-file, file-path, get-current-folder, file-exists, folder-exists } = winjs.load-library 'WinjsFileSystem.dll'

      { read: read-text-file } = text-file

      { get-base-name } = file-path

      { read-text-file, get-current-folder, file-exists, folder-exists }

    read-configuration-file = (filename) ->

      configuration = {}

      if file-system.file-exists filename

        exception = fn-exception 'read-configuration-file'

        configuration-lines = filename |> file-system.read-text-file |> string.string-as-array

        for line, line-number in configuration-lines

          line = string.trim line

          if line is ''
            continue

          if (line.char-at 0) is '#'
            continue

          space-index = line.index-of ' '

          throw exception 'configuration-line', "Invalid syntax at line (#line-number) '#line' of configuration file '#filename'. A valid configuration line has a word and an arbitrary value separated by space, or can be an empty line, or can have a comment line that starts with '#' " \
            if space-index is -1

          key = line.slice 0, space-index

          value = line.slice space-index + 1

          configuration[ key ] = value

      configuration

    namespace-path-manager = do ->

      configuration-filename = 'namespaces.conf'

      configuration-namespaces = read-configuration-file configuration-filename

      namespaces = '.': file-system.get-current-folder!

      get-qualified-namespace-path: (qualified-namespace) ->

        exception = fn-exception 'namespace-path-manager.get-qualified-namespace-path'

        if qualified-namespace is ''
          qualified-namespace = '.'

        namespace-path = namespaces[ qualified-namespace ]

        if namespace-path isnt void

          return namespace-path

        namespace-path = configuration-namespaces[ qualified-namespace ]

        if namespace-path isnt void

          if file-system.folder-exists namespace-path

            namespaces[ qualified-namespace ] := namespace-path
            return namespace-path

          throw exception "configuration-namespaces[ #qualified-namespace ]", "Folder '#namespace-path' for namespace '#qualified-namespace' in configuration file '#configuration-filename' does not exist"

        namespace-path =

          [ file-system.get-current-folder! ]
          |> (++ qualified-namespace / '.')
          |> -> it * '\\'

        if file-system.folder-exists namespace-path

          namespaces[ qualified-namespace ] := namespace-path
          return namespace-path

        throw exception "namespace-path", "Folder '#namespace-path' for namespace '#qualified-namespace' does not exist"

    parse-qualified-dependency-name = (qualified-dependency-name) ->

      [ ...namespaces, dependency-name ] = qualified-dependency-name / '.'

      qualified-namespace = namespaces * '.' |> string.lcase

      { qualified-namespace, dependency-name }

    dependency-builder = do ->

      build-dependency: (qualified-dependency-name) ->

        exception = fn-exception 'dependency-builder.build-dependency'

        { qualified-namespace, dependency-name } = parse-qualified-dependency-name qualified-dependency-name

        namespace-path = namespace-path-manager.get-qualified-namespace-path qualified-namespace

        filename = [ dependency-name, 'js' ] * '.'

        dependency-full-path = [ namespace-path, filename ] * '\\'

        if not file-system.file-exists dependency-full-path

          throw exception 'qualified-dependency-name', "Dependency file '#dependency-full-path' not found"

        dependency-source = file-system.read-text-file dependency-full-path

        winjs.eval-script-source dependency-source, qualified-dependency-name

    dependency-manager = do ->

      dependencies = {}

      get-dependency: (qualified-dependency-name) ->

        exception = fn-exception 'dependency-manager.get-dependency'

        result = dependencies[ string.lcase qualified-dependency-name ]

        if result is void

          result = dependency-builder.build-dependency qualified-dependency-name

          dependencies[ string.lcase qualified-dependency-name ] := result

        result

    ##

    (qualified-dependency-name) -> dependency-manager.get-dependency qualified-dependency-name

  process.args => if ..length > 2 => dependency ..2
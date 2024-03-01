
  dependency = do ->

    fs = os.file-system

    ##

    lcase = (.to-lower-case!)

    unit = String.from-char-code 31

    replace-crlf = (.replace /\r\n/g, unit)
    replace-lf   = (.replace /\n/g, unit)

    string-as-units = -> it |> replace-crlf |> replace-lf

    units-as-array = (.split unit)

    string-as-array = -> it |> string-as-units |> units-as-array

    trim-regex = /^\s+|\s+$/g

    trim = (.replace trim-regex, '')

    #

    read-configuration-file = (filename) ->

      configuration = {}

      if fs.file-exists filename

        configuration-lines = filename |> fs.read-text-file |> string-as-array

        for line, line-number in configuration-lines

          line = trim line

          if line is ''
            continue

          if (line.char-at 0) is '#'
            continue

          space-index = line.index-of ' '

          throw new Error "Invalid configuration file syntax at line (#line-number) '#line' of configuration file '#filename'" \
            if space-index is -1

          key = line.slice 0, space-index

          value = line.slice space-index + 1

          configuration[ key ] = value

      configuration

    namespace-path-manager = do ->

      configuration-filename = 'namespaces.conf'

      configuration-namespaces = read-configuration-file configuration-filename

      current-folder = fs.get-current-folder!

      namespaces = '.' : current-folder

      get-qualified-namespace-path = (qualified-namespace) ->

        if qualified-namespace is ''
          qualified-namespace = '.'

        namespace-path = namespaces[ qualified-namespace ]

        if namespace-path isnt void

          return namespace-path

        namespace-path = configuration-namespaces[ qualified-namespace ]

        if namespace-path isnt void

          if fs.folder-exists namespace-path

            namespaces[ qualified-namespace ] := namespace-path
            return namespace-path

          throw new Error "Folder '#namespace-path' for namespace '#qualified-namespace' in configuration file '#configuration-filename' does not exist"

        build-path = (* '\\')

        namespace-path =

          [ current-folder ]
          |> (++ qualified-namespace / '.')
          |> build-path

        if fs.folder-exists namespace-path

          namespaces[ qualified-namespace ] := namespace-path
          return namespace-path

        if configuration-namespaces[ '.' ] isnt void

          namespace-path =

            [ configuration-namespaces[ '.' ] ]
            |> (++ qualified-namespace / '.')
            |> build-path

          if fs.folder-exists namespace-path

            namespaces[ qualified-namespace ] := namespace-path
            return namespace-path

        throw new Error "Folder '#namespace-path' for namespace '#qualified-namespace' does not exist"

      {
        get-qualified-namespace-path
      }

    ##

    parse-qualified-dependency-name = (qualified-dependency-name) ->

      [ ...namespaces, dependency-name ] = qualified-dependency-name / '.'

      qualified-namespace = namespaces * '.' |> lcase

      { qualified-namespace, dependency-name }

    dependency-builder = do ->

      build-dependency = (qualified-dependency-name) ->

        { qualified-namespace, dependency-name } = parse-qualified-dependency-name qualified-dependency-name

        filename = [ dependency-name, 'js' ] * '.'

        if fs.file-exists filename

          dependency-full-path = filename

        else

          namespace-path = namespace-path-manager.get-qualified-namespace-path qualified-namespace

          dependency-full-path = [ namespace-path, filename ] * '\\'

          if not fs.file-exists dependency-full-path

            throw new Error "Dependency file '#dependency-full-path' not found"

        winjs.load-script dependency-full-path, qualified-dependency-name

      {
        build-dependency
      }

    ##

    dependency-manager = do ->

      dependencies = {}

      get-dependency = (qualified-dependency-name) ->

        qname = lcase qualified-dependency-name

        result = dependencies[ qname ]

        if result is void

          result = dependency-builder.build-dependency qualified-dependency-name

          dependencies[ qname ] := result

        result

      {
        get-dependency
      }

    ##

    (qualified-dependency-name) -> dependency-manager.get-dependency qualified-dependency-name


  do ->

    args = winjs.process.args

    fs = os.file-system

    if args.length > 2

      script = args.2

      if fs.file-exists script

        winjs.load-script script

      else

        dependency script
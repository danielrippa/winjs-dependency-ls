
  dependency = do ->

    writeln = -> winjs.process.io.stdout '\n' + [ (arg) for arg in arguments ] * ' '

    { folder-exists, file-exists, read-text-file, get-current-folder } = os.file-system

    get-path = (string) -> string / '\\' |> (.slice 0, -1) |> (* '\\')

    build-path = (* '\\')

    lcase = (.to-lower-case!)

    string-as-array = do ->

      us = String.from-char-code 31

      replace-crlf = (.replace /\r\n/g, us)
      replace-lf   = (.replace /\n/g, us)

      string-as-units = -> it |> replace-crlf |> replace-lf

      units-as-array = (.split us)

      #

      -> it |> string-as-units |> units-as-array

    #

    trim = do ->

      trim-regex = /^\s+|\s+$/g

      (.replace trim-regex, '')

    ##

    read-configuration-file = (filepath) ->

      configuration = {}

      if file-exists filepath

        configuration-lines = filepath |> read-text-file |> string-as-array

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

    #

    namespace-path-manager = do ->

      { args } = winjs.process

      winjs-path = get-path args.0

      script-path = get-path args.2

      configuration-filename = 'namespaces.conf'

      configuration-filepath = build-path [ script-path, configuration-filename ]

      configuration-namespaces = read-configuration-file configuration-filepath

      current-folder = get-current-folder!

      # namespaces = '.' : current-folder

      namespaces = {}

      get-qualified-namespace-path = (qualified-namespace) ->

        # registered namespaces

        namespace-path = namespaces[ qualified-namespace ]

        if namespace-path isnt void

          return namespace-path

        # configuration-namespaces

        namespace-path = configuration-namespaces[ qualified-namespace ]

        if namespace-path isnt void

          if folder-exists namespace-path

            namespaces[ qualified-namespace ] := namespace-path
            return namespace-path

          throw new Error "Folder '#namespace-path' for namespace '#qualified-namespace' in configuration file '#configuration-filename' not found."

        # script-path

        namespace-path =

          [ script-path ]
            |> (++ qualified-namespace / '.')
            |> build-path

        if folder-exists namespace-path

          namespaces[ qualified-namespace ] := namespace-path
          return namespace-path

        # current-folder path

        namespace-path =

          [ current-folder ]
            |> (++ qualified-namespace / '.')
            |> build-path

        if folder-exists namespace-path

          namespaces[ qualified-namespace ] := namespace-path
          return namespace-path

        # winjs path

        namespace-path =

          [ winjs-path ]
            |> (++ qualified-namespace / '.')
            |> build-path

        if folder-exists namespace-path

          namespaces[ qualified-namespace ] := namespace-path
          return namespace-path

        throw new Error "Folder for namespace '#qualified-namespace' not found."

      {
        get-qualified-namespace-path
      }

    #

    parse-qualified-dependency-name = (qualified-dependency-name) ->

      [ ...namespaces, dependency-name ] = qualified-dependency-name / '.'

      qualified-namespace = namespaces * '.' |> lcase

      { qualified-namespace, dependency-name }

    #

    dependency-builder = do ->

      build-dependency = (qualified-dependency-name) ->

        { qualified-namespace, dependency-name } = parse-qualified-dependency-name qualified-dependency-name

        filename = [ dependency-name, 'js' ] * '.'

        namespace-path = namespace-path-manager.get-qualified-namespace-path qualified-namespace

        dependency-full-path = build-path [ namespace-path, filename ]

        if not file-exists dependency-full-path

          throw new Error "Dependency file '#dependency-full-path' not found."

        winjs.load-script dependency-full-path, "(#qualified-dependency-name) #dependency-full-path"

      {
        build-dependency
      }

    #

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

    #

    (qualified-dependency-name) -> dependency-manager.get-dependency qualified-dependency-name

    #

  #

  do ->

    { args } = winjs.process

    if args.length > 2

      script = args.2

      winjs.load-script script, '' #, "script #script"


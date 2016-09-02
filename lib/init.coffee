{BufferedProcess, CompositeDisposable} = require 'atom'

class Parser
  @match: (line) ->
    if m = /(.+):([0-9]+): +(MD[0-9]{3}) +(.+)/.exec line
      type: 'Error'
      message: "#{m[3]}: #{m[4]}"
      lint: m[3]
      lineStart: m[2]
      lineEnd: m[2]
      charStart: 1
      charEnd: 1
  @parse: (data, ignoreLints) =>
    errors = (@match(line) for line in data)
    ignoreLints = ',' + ignoreLints.replace(/[^A-Za-z0-9,]/g, '') + ','
    errors = (error for error in errors when error? and
              ignoreLints.indexOf(',' + error.lint + ',') == -1)
    if errors.length == 0
      passed: true
    else
      passed: false
      errors: errors

class Command
  @setExecutablePath: (path) =>
    @executablePath = path

  @getExecutablePath: =>
    @executablePath || 'mdl'

module.exports =
  config:
    executablePath:
      type: 'string'
      default: 'mdl'
      description: 'Path to mdl executable'
    ignoreLints:
      type: 'string'
      default: ''
      description: 'Comma-separated list of Lints. Example: MD001,MD013'
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-markdownlint.executablePath',
      (executablePath) ->
        Command.setExecutablePath(executablePath)
    @subscriptions.add atom.config.observe 'linter-markdownlint.ignoreLints',
      (ignoreLints) ->
        @ignoreLints = ignoreLints
  deactivate: ->
    @subscriptions.dispose()
  provideLinter: ->
    provider =
      name: 'markdownlint'
      grammarScopes: ['source.gfm', 'source.pfm']
      scope: 'file'
      lintOnFly: false
      lint: (TextEditor) =>
        return new Promise (resolve, reject) =>
          filePath = TextEditor.getPath()
          lines = []
          process = new BufferedProcess
            command: Command.getExecutablePath()
            args: [filePath]
            stdout: (data) ->
              lines.push(line) for line in data.split('\n')
            exit: (code) ->
              return resolve [] if code is 0
              info = Parser.parse(lines, @ignoreLints)
              return resolve [] unless info?
              return resolve [] if info.passed
              resolve info.errors.map (error) ->
                type: error.type,
                text: error.message,
                filePath: error.file or filePath,
                range: [
                  # Atom expects ranges to be 0-based
                  [error.lineStart - 1, error.charStart - 1],
                  [error.lineEnd - 1, error.charEnd]
                ]

          process.onWillThrowError ({error,handle}) ->
            atom.notifications.addError "Failed to run #{@executablePath}",
              detail: "#{error.message}"
              dismissable: true
            handle()
            resolve []

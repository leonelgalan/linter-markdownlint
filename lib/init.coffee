{BufferedProcess, CompositeDisposable} = require 'atom'

class Parser
  @match: (line) ->
    if m = /(.+):([0-9]+): +(MD[0-9]{3}) +(.+)/.exec line
      type: 'Error'
      message: "#{m[3]}: #{m[4]}"
      lineStart: m[2]
      lineEnd: m[2]
      charStart: 1
      charEnd: 1
  @parse: (data) =>
    errors = (@match(line) for line in data)
    errors = (error for error in errors when error?)
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
  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-example.executablePath',
      (executablePath) ->
        Command.setExecutablePath(executablePath)
  deactivate: ->
    @subscriptions.dispose()
  provideLinter: ->
    provider =
      grammarScopes: ['source.gfm', 'source.pfm']
      scope: 'file'
      lintOnFly: false
      lint: (TextEditor) =>
        return new Promise (resolve, reject) =>
          filePath = TextEditor.getPath()
          lines = []
          console.log Command.getExecutablePath()
          process = new BufferedProcess
            command: Command.getExecutablePath()
            args: [filePath]
            stdout: (data) ->
              lines.push(line) for line in data.split('\n')
            exit: (code) ->
              return resolve [] if code is 0
              info = Parser.parse lines
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

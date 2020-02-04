'use babel';

const { BufferedProcess, CompositeDisposable } = require('atom');

export const config = {
  executablePath: {
    type: 'string',
    default: 'mdl',
    description: 'Path to mdl executable',
  },
  severity: {
    type: 'string',
    default: 'error',
    enum: [
      { value: 'error', description: 'Error' },
      { value: 'warning', description: 'Warning' },
      { value: 'info', description: 'Info' },
    ],
    description: 'Sets the severity of mdl findings',
  },
};

class Command {
  static setExecutablePath(path) {
    this.executablePath = path;
  }

  static getExecutablePath() {
    return this.executablePath || config.executablePath.default;
  }

  static setSeverity(severity) {
    this.severity = severity;
  }

  static getSeverity() {
    return this.severity || config.severity.default;
  }
}

class Parser {
  static match(line) {
    // Example line: /absolute/path/file.md:3: MD013 Line length
    const match = /(.+):([0-9]+): +(MD[0-9]{3}) +(.+)/.exec(line);

    if (match) {
      const text = `${match[3]}: ${match[4]}`;
      return {
        severity: Command.getSeverity(),
        location: {
          file: match[1],
          position: [[Number(match[2]) - 1, 0], [Number(match[2]) - 1, 0]],
        },
        excerpt: text,
        description: text,
      };
    }

    return undefined;
  }

  static parse(data) {
    const errors = data.map(line => Parser.match(line)).filter(Boolean);
    if (errors.length === 0) {
      return { passed: true };
    } return { passed: false, errors };
  }
}

let reportedBroken = false;

export function activate() {
  this.subscriptions = new CompositeDisposable();
  this.subscriptions.add(
    atom.config.observe(
      'linter-markdownlint.executablePath',
      executablePath => Command.setExecutablePath(executablePath),
    ),
  );

  this.subscriptions.add(
    atom.config.observe(
      'linter-markdownlint.severity',
      severity => Command.setSeverity(severity),
    ),
  );
}

export function deactivate() {
  this.subscriptions.dispose();
}

export function provideLinter() {
  return {
    name: 'markdownlint',
    scope: 'file',
    lintsOnChange: false,
    grammarScopes: ['source.gfm', 'source.pfm', 'text.md'],
    lint(textEditor) {
      const editorPath = textEditor.getPath();
      const cwd = atom.project.relativizePath(editorPath)[0];

      return new Promise(((resolve) => {
        const lines = [];
        const process = new BufferedProcess({
          options: { cwd },
          command: Command.getExecutablePath(),
          args: [editorPath],
          stdout(data) {
            data.split('\n').forEach(line => lines.push(line));
          },
          exit(code) {
            reportedBroken = false;
            if (code === 0) {
              return resolve([]);
            }
            const info = Parser.parse(lines);
            if (info == null || info.passed) {
              return resolve([]);
            }
            return resolve(info.errors);
          },
        });

        process.onWillThrowError((arg) => {
          const { error, handle } = arg;
          if (error.code === 'ENOENT') {
            if (reportedBroken) {
              handle();
              resolve([]);
              return;
            }
            reportedBroken = true;
          }
          atom.notifications.addError(
            `Failed to run ${Command.getExecutablePath()}`,
            {
              detail: 'Cannot find markdown lint on specified path.',
              dismissable: true,
            },
          );
          handle();
          resolve([]);
        });
      }));
    },
  };
}

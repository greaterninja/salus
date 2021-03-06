require 'open3'

module Salus::Scanners
  # Super class for all scanner objects.
  class Base
    class UnhandledExitStatusError < StandardError; end
    class InvalidScannerInvocationError < StandardError; end

    def initialize(repository:, report:, config:)
      @repository = repository
      @report = report
      @config = config
    end

    def name
      self.class.name.sub('Salus::Scanners::', '')
    end

    # The scanning logic or something that calls a scanner.
    def run
      raise NoMethodError
    end

    # Returns TRUE if this scanner is appropriate for this repo, ELSE false.
    def should_run?
      raise NoMethodError
    end

    # Runs a command on the terminal.
    def run_shell(command, env: {}, stdin_data: '')
      # If we're passed a string, convert it to an array beofre passing to capture3
      command = command.split unless command.is_a?(Array)

      stdout, stderr, exit_status = Open3.capture3(env, *command, stdin_data: stdin_data)
      { stdout: stdout, stderr: stderr, exit_status: exit_status }
    end

    # Add a log to the report that this scanner had no findings.
    def report_success
      @report.scan_passed(name, true)
    end

    # Add a log to the report that this scanner had findings.
    def report_failure
      @report.scan_passed(name, false)
    end

    # Report information about this scan.
    def report_info(type, message)
      @report.scan_info(name, type, message)
    end

    # Report the STDOUT from the scanner.
    def report_stdout(stdout)
      @report.scan_stdout(name, stdout)
    end

    # Report the STDERR from the scanner.
    def report_stderr(stderr)
      @report.scan_stderr(name, stderr)
    end

    # Report an error in a scanner.
    def report_error(error_data)
      unless error_data.is_a?(Hash)
        raise "`report_error` must take in a hash, not a #{error_data.class}"
      end

      @report.salus_error(name, error_data)
    end

    def report_recorded_failure?
      @report.has_failure?(name)
    end

    def record_dependency_info(info, dependency_file)
      report_info('dependency', { dependency_file: dependency_file }.merge(info))
    end
  end
end

# frozen_string_literal: true

require 'etc'
require 'fileutils'
require 'net/http'
require 'rubygems/package'
require 'stringio'
require 'uri'
require 'zlib'
require_relative 'sqldef/version'

module Sqldef
  GOARCH = {
    'x86_64'  => 'amd64',
    'aarch64' => 'arm64',
    # TODO: add arm and 386
  }
  private_constant :GOARCH

  COMMANDS = %w[
    mysqldef
    psqldef
    sqlite3def
  ]
  private_constant :COMMANDS

  @bin = Dir.pwd

  class << self
    attr_accessor :bin

    # @param [String,Symbol] command - mysqldef, psqldef, sqllite3def
    # @param [String] path - Schema export path
    def export(command:, path:, host:, port: nil, user:, password: nil, database:)
      sqldef = download(command)
      schema = IO.popen(
        [
          sqldef,
          "--user=#{user}", *(["--password=#{password}"] if password),
          "--host=#{host}", *(["--port=#{port}"] if port),
          '--export', database,
        ],
        &:read
      )
      raise "Failed to execute '#{sqldef}'" unless $?.success?
      File.write(path, schema)
    end

    # @param [String,Symbol] command - mysqldef, psqldef, sqllite3def
    # @param [String] path - Schema file path
    def dry_run(command:, path:, host:, port: nil, user:, password: nil, database:)
      sqldef = download(command)
      execute(
        sqldef,
        "--user=#{user}", *(["--password=#{password}"] if password),
        "--host=#{host}", *(["--port=#{port}"] if port),
        '--dry-run', database,
        in: path,
      )
    end

    # @param [String,Symbol] command - mysqldef, psqldef, sqllite3def
    # @param [String] path - Schema file path
    def apply(command:, path:, host:, port: nil, user:, password: nil, database:)
      sqldef = download(command)
      execute(
        sqldef,
        "--user=#{user}", *(["--password=#{password}"] if password),
        "--host=#{host}", *(["--port=#{port}"] if port),
        database,
        in: path,
      )
    end

    # @param [String,Symbol] command - mysqldef, psqldef, sqllite3def
    # @return String - command path
    def download(command)
      path = File.join(bin, command = command.to_s)
      return path if File.executable?(path)

      print("Downloading '#{command}' under '#{bin}'... ")
      resp = get(build_url(command), code: 302) # Latest
      resp = get(resp['location'],   code: 302) # vX.Y.Z
      resp = get(resp['location'],   code: 200) # Binary

      gzip = Zlib::GzipReader.new(StringIO.new(resp.body))
      Gem::Package::TarReader.new(gzip) do |tar|
        unless file = tar.find { |f| f.full_name == command }
          raise "'#{command}' was not found in the archive"
        end
        File.binwrite(path, file.read)
      end

      FileUtils.chmod('+x', path)
      puts 'done.'
      path
    end

    private

    def execute(*cmd, **opts)
      unless system(*cmd, **opts)
        raise "Failed to execute '#{cmd.first.is_a?(Hash) ? cmd[1] : cmd.first}'"
      end
    end

    def build_url(command)
      unless COMMANDS.include?(command)
        raise "Unexpected sqldef command: #{command}" 
      end
      os = Etc.uname.fetch(:sysname).downcase
      arch = GOARCH.fetch(Etc.uname.fetch(:machine))
      "https://github.com/k0kubun/sqldef/releases/latest/download/#{command}_#{os}_#{arch}.tar.gz"
    end

    # TODO: Retry transient errors
    def get(url, code: nil)
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.get("#{uri.path}?#{uri.query}")
      end.tap do |resp|
        if code && resp.code != code.to_s
          raise "Expected '#{url}' to return #{code}, but got #{resp.code}: #{resp.body}"
        end
      end
    end
  end
end
